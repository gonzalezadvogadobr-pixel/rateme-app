import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Comprime Uint8List usando dart:ui para garantir que caiba no Firestore.
// Redimensiona para maxDim e aplica qualidade/tamanho até caber em maxBytes.
// ─────────────────────────────────────────────────────────────────────────────
Future<Uint8List> _compressImage(
  Uint8List input, {
  int maxDim = 800,
  int maxBytes = 700 * 1024, // 700 KB → base64 ≈ 933 KB, abaixo do 1 MB do Firestore
}) async {
  // Decodifica a imagem (sem targetMax* que não existem nesta versão do Flutter)
  final codec = await ui.instantiateImageCodec(input);
  final frame = await codec.getNextFrame();
  final srcImage = frame.image;

  // Calcula dimensões respeitando o limite maxDim
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

  // Redimensiona via Canvas
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

  // Exporta como PNG (dart:ui não suporta JPEG nativo na web)
  final byteData = await resized.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return input;

  final result = byteData.buffer.asUint8List();

  // Se ainda for grande demais, tenta redimensionar mais agressivamente
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
      // Passo 1: ImagePicker faz uma compressão inicial (1200px, qualidade 80)
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (file == null) return;

      setState(() => _compressing = true);

      final rawBytes = await file.readAsBytes();

      // Passo 2: compressão dart:ui — garante tamanho < 700KB (cabe no Firestore)
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Preview da imagem ──────────────────────────────────────────
            GestureDetector(
              onTap: _compressing ? null : _showImagePicker,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: _imageBase64 == null
                      ? Border.all(
                          color: AppTheme.purple.withValues(alpha: 0.4),
                          width: 2,
                        )
                      : null,
                ),
                child: _compressing
                    // Comprimindo
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppTheme.purple),
                          SizedBox(height: 16),
                          Text(
                            'Otimizando imagem…',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      )
                    : _imageBase64 != null
                        // Preview com badge de tamanho
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: AppImage(
                                  imageData: _imageBase64!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 300,
                                ),
                              ),
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
                            ],
                          )
                        // Placeholder vazio
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
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
                            ],
                          ),
              ),
            ),

            // ── Botão trocar imagem ────────────────────────────────────────
            if (_imageBase64 != null && !_compressing) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _showImagePicker,
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppTheme.purpleLight, size: 18),
                    label: const Text('Trocar imagem',
                        style: TextStyle(color: AppTheme.purpleLight)),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // ── Legenda ────────────────────────────────────────────────────
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

            // ── Botão publicar ─────────────────────────────────────────────
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
