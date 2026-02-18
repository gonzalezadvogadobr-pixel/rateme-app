// firebase_options.dart — gerado para projeto rateme-a1de6
// Suporta Web e Android (package: com.pinscore.rating)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBy_5Kkopj7XHdhEeF6xJdU7SFkR-nwFBs',
    appId: '1:641618795234:web:79bc6e9ed4ac8e6d12dcbb',
    messagingSenderId: '641618795234',
    projectId: 'rateme-a1de6',
    authDomain: 'rateme-a1de6.firebaseapp.com',
    storageBucket: 'rateme-a1de6.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBy_5Kkopj7XHdhEeF6xJdU7SFkR-nwFBs',
    appId: '1:641618795234:android:b3182f5a24028df412dcbb',
    messagingSenderId: '641618795234',
    projectId: 'rateme-a1de6',
    storageBucket: 'rateme-a1de6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBy_5Kkopj7XHdhEeF6xJdU7SFkR-nwFBs',
    appId: '1:641618795234:android:b3182f5a24028df412dcbb',
    messagingSenderId: '641618795234',
    projectId: 'rateme-a1de6',
    storageBucket: 'rateme-a1de6.firebasestorage.app',
    iosBundleId: 'com.pinscore.rating',
  );
}
