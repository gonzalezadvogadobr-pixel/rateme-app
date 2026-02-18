// lib/services/image_storage_io.dart
// Implementação Mobile/Desktop: salva imagens como arquivos no sistema de arquivos

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<String> _imgDir() async {
  final dir = await getApplicationDocumentsDirectory();
  final imgDir = Directory('${dir.path}/rateme_images');
  if (!imgDir.existsSync()) imgDir.createSync(recursive: true);
  return imgDir.path;
}

String _sanitize(String key) => key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

Future<void> saveImage(String key, String base64) async {
  try {
    final dir  = await _imgDir();
    final file = File('$dir/${_sanitize(key)}.b64');
    await file.writeAsString(base64);
  } catch (e) {
    if (kDebugMode) debugPrint('[ImageStorage] saveImage erro: $e');
  }
}

Future<String?> loadImage(String key) async {
  try {
    final dir  = await _imgDir();
    final file = File('$dir/${_sanitize(key)}.b64');
    if (!file.existsSync()) return null;
    return await file.readAsString();
  } catch (e) {
    if (kDebugMode) debugPrint('[ImageStorage] loadImage erro: $e');
    return null;
  }
}

Future<void> deleteImage(String key) async {
  try {
    final dir  = await _imgDir();
    final file = File('$dir/${_sanitize(key)}.b64');
    if (file.existsSync()) await file.delete();
  } catch (e) {
    if (kDebugMode) debugPrint('[ImageStorage] deleteImage erro: $e');
  }
}
