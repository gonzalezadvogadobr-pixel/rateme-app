// lib/services/image_storage_web.dart
// Implementação Web usando IndexedDB via JS Interop moderno (dart:js_interop)
// Compatível com Flutter 3.35 / Dart 3.9

import 'dart:async';
import 'package:flutter/foundation.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

/// Salva base64 no IndexedDB via função JS global idbSaveImage(key, base64)
Future<void> saveImage(String key, String base64) async {
  try {
    // js_util.globalThis é o objeto global (window no browser)
    final jsObj = js_util.globalThis;
    final jsPromise = js_util.callMethod<Object>(jsObj, 'idbSaveImage', [key, base64]);
    await js_util.promiseToFuture<dynamic>(jsPromise);
  } catch (e) {
    if (kDebugMode) debugPrint('[ImageStorage/Web] saveImage($key) erro: $e');
  }
}

/// Carrega base64 do IndexedDB. Retorna null se não existir.
Future<String?> loadImage(String key) async {
  try {
    final jsObj = js_util.globalThis;
    final jsPromise = js_util.callMethod<Object>(jsObj, 'idbLoadImage', [key]);
    final result = await js_util.promiseToFuture<dynamic>(jsPromise);
    if (result == null) return null;
    final str = result.toString();
    return str.isEmpty ? null : str;
  } catch (e) {
    if (kDebugMode) debugPrint('[ImageStorage/Web] loadImage($key) erro: $e');
    return null;
  }
}

/// Remove imagem do IndexedDB.
Future<void> deleteImage(String key) async {
  try {
    final jsObj = js_util.globalThis;
    final jsPromise = js_util.callMethod<Object>(jsObj, 'idbDeleteImage', [key]);
    await js_util.promiseToFuture<dynamic>(jsPromise);
  } catch (e) {
    if (kDebugMode) debugPrint('[ImageStorage/Web] deleteImage($key) erro: $e');
  }
}
