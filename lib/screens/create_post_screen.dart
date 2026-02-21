import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Comprime Uint8List usando dart:ui para garantir que caiba no Firestore.
// ─────────────────────────────────────────────────────────────────────────────
Future<Uint8List> _compressImage(
  Uint8List input, {
  int maxDim = 800,
  int maxBytes = 700 * 1024,
}) async {
  final codec = await ui.instantiateImageCodec(input);
  final frame = await codec.getNextFrame();
  final srcImage = frame.image;

  final w = srcImage.width;
  final h = srcImage.height;
  int targetW = w;
  int targetH = h;
  if (w > maxDim || h > maxDim) {
    if (w >= h) {
      targetW = maxDim;
      targetH = (h * maxDim / w).round();
    } else {
      targetH = maxDim;
      targetW = (w * maxDim / h).round();
    }
  }

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..filterQuality = FilterQuality.medium;
  canvas.drawImageRect(
    srcImage,
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Rect.fromLTWH(0, 0, targetW.toDouble(), targetH.toDouble()),
    paint,
  );
  final picture = recorder.endRecording();
  final resized = await picture.toImage(targetW, targetH);

  final byteData = await resized.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return input;

  final result = byteData.buffer.asUint8List();

  if (result.length > maxBytes && maxDim > 400) {
    return _compressImage(input, maxDim: (maxDim * 0.7).round(), maxBytes: maxBytes);
  }

  return result;
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageBase64;
  bool _loading = false;
  bool _compressing = false;
  String? _sizeInfo;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file == null) return;

      // Abre o cropper para ajuste de foto (crop/rotação)
      CroppedFile? cropped;
      if (!kIsWeb) {
        cropped = await ImageCropper().cropImage(
          sourcePath: file.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Ajustar foto',
              toolbarColor: AppTheme.bgPrimary,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: AppTheme.purple,
              backgroundColor: AppTheme.bgPrimary,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.original,
              ],
            ),
          ],
        );
      }

      setState(() => _compressing = true);

      final rawBytes = cropped != null
          ? await cropped.readAsBytes()
          : await file.readAsBytes();

      final compressed = await _compressImage(rawBytes);

      final kb = (compressed.length / 1024).round();
      final base64Str = base64Encode(compressed);

      setState(() {
        _imageBytes  = compressed;
        _imageBase64 = 'data:image/png;base64,$base64Str';
        _sizeInfo    = '${kb} KB';
        _compressing = false;
      });
    } catch (e) {
      setState(() => _compressing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar imagem: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _publish() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma imagem primeiro.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final db = context.read<DatabaseService>();
      await db.createPost(
        imageBytes: _imageBytes!,
        caption: _captionCtrl.text.trim(),
      );
      if (mounted) {
        setState(() => _loading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post publicado com sucesso!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao publicar: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Criar Post'),
        actions: [
          TextButton(
            onPressed: (_loading || _compressing) ? null : _publish,
            child: const Text(
              'Publicar',
              style: TextStyle(
                color: AppTheme.purpleLight,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Preview da imagem (ocupa toda a largura, proporção 4:5 igual ao feed) ──
            GestureDetector(
              onTap: _compressing ? null : _showImagePicker,
              child: _compressing
                  ? Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width * (5 / 4),
                      color: AppTheme.bgCard,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppTheme.purple),
                          SizedBox(height: 16),
                          Text(
                            'Otimizando imagem…',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : _imageBase64 != null
                      ? Stack(
                          children: [
                            // Foto edge-to-edge sem bordas laterais
                            AspectRatio(
                              aspectRatio: 4 / 5,
                              child: AppImage(
                                imageData: _imageBase64!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                            // Badge de tamanho
                            if (_sizeInfo != null)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _sizeInfo!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            // Botão de editar (canto superior direito)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _showImagePicker,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_rounded,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        )
                      : AspectRatio(
                          aspectRatio: 4 / 5,
                          child: Container(
                            color: AppTheme.bgCard,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    gradient: AppTheme.gradientPurplePink,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Toque para adicionar foto',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  kIsWeb
                                      ? 'Selecionar arquivo'
                                      : 'Galeria ou câmera',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (!kIsWeb)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppTheme.purple
                                              .withValues(alpha: 0.4)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.crop_rounded,
                                            color: AppTheme.purpleLight,
                                            size: 14),
                                        SizedBox(width: 6),
                                        Text(
                                          'Recortar após selecionar',
                                          style: TextStyle(
                                              color: AppTheme.purpleLight,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Legenda ────────────────────────────────────────────────
                  TextField(
                    controller: _captionCtrl,
                    maxLines: 3,
                    maxLength: 300,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Legenda (opcional)',
                      hintText: 'Descreva sua foto...',
                      prefixIcon: Icon(Icons.short_text_rounded,
                          color: AppTheme.textMuted),
                      counterStyle: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppTheme.purpleLight, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Após publicar, outros usuários poderão criar pins avaliando sua foto.',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Botão publicar ─────────────────────────────────────────
                  GradientButton(
                    label: _loading
                        ? 'Publicando...'
                        : _compressing
                            ? 'Otimizando...'
                            : 'Publicar foto',
                    icon: Icons.cloud_upload_rounded,
                    loading: _loading || _compressing,
                    onPressed:
                        _imageBase64 != null && !_compressing ? _publish : null,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker() {
    if (kIsWeb) {
      _pickImage(ImageSource.gallery);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selecionar imagem',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Você poderá recortar/ajustar a foto depois de selecionar',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradientPurplePink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Colors.white),
                ),
                title: const Text('Galeria de fotos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradientPurplePink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white),
                ),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
