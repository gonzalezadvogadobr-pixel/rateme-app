import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

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
  final _picker = ImagePicker();

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Comprime automaticamente para caber no localStorage (~1MB base64)
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 75,
      );
      if (file == null) return;
      Uint8List bytes = await file.readAsBytes();

      // Se ainda estiver grande, recomprime com qualidade menor
      if (bytes.lengthInBytes > 700 * 1024) {
        final smaller = await _picker.pickImage(
          source: source,
          maxWidth: 720,
          maxHeight: 720,
          imageQuality: 55,
        );
        if (smaller != null) bytes = await smaller.readAsBytes();
      }

      setState(() {
        _imageBytes = bytes;
        _imageBase64 = base64Encode(bytes);
      });
    } catch (e) {
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
            onPressed: _loading ? null : _publish,
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
            // Preview da imagem
            GestureDetector(
              onTap: () => _showImagePicker(),
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
                child: _imageBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AppImage(
                          imageData: _imageBase64!,
                          fit: BoxFit.cover,
                        ),
                      )
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
                            kIsWeb ? 'Selecionar arquivo' : 'Galeria ou câmera',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            // Botão trocar imagem
            if (_imageBase64 != null) ...[
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
            // Legenda
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
            GradientButton(
              label: _loading ? 'Publicando...' : 'Publicar foto',
              icon: Icons.cloud_upload_rounded,
              loading: _loading,
              onPressed: _imageBase64 != null ? _publish : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker() {
    // No web, vai direto para galeria (câmera não funciona no browser)
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
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
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
