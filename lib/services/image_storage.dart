// lib/services/image_storage.dart
//
// Serviço de armazenamento de imagens:
//  - Web  → IndexedDB (sem limite prático, suporta centenas de MB)
//  - Mobile → arquivos locais no diretório de documentos
//
// API pública (static):
//   await ImageStorage.save(key, base64String)
//   String? b64 = await ImageStorage.load(key)
//   await ImageStorage.delete(key)

import 'dart:convert';
import 'package:flutter/foundation.dart';

// Importações condicionais – só compilam na plataforma certa
import 'image_storage_web.dart'    if (dart.library.io) 'image_storage_io.dart'
    as _impl;

class ImageStorage {
  ImageStorage._();

  /// Salva uma imagem (bytes) usando [key] como identificador.
  static Future<void> saveBytes(String key, Uint8List bytes) async {
    final b64 = base64Encode(bytes);
    await _impl.saveImage(key, b64);
  }

  /// Carrega os bytes de uma imagem pelo [key]. Retorna null se não existir.
  static Future<Uint8List?> loadBytes(String key) async {
    final b64 = await _impl.loadImage(key);
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  /// Carrega a string base64 diretamente (evita encode/decode duplo).
  static Future<String?> loadBase64(String key) => _impl.loadImage(key);

  /// Salva a string base64 diretamente.
  static Future<void> saveBase64(String key, String base64) =>
      _impl.saveImage(key, base64);

  /// Remove a imagem associada a [key].
  static Future<void> delete(String key) => _impl.deleteImage(key);
}
