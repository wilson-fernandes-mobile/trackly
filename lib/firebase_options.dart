// ============================================================
//  firebase_options.dart
//  ATENÇÃO: Substitua estes valores pelos gerados com o comando:
//    flutterfire configure
//
//  Pré-requisitos:
//    1. Instale o Firebase CLI:  npm install -g firebase-tools
//    2. Instale o FlutterFire CLI: dart pub global activate flutterfire_cli
//    3. Execute na raiz do projeto: flutterfire configure
//
//  O comando acima:
//    - Cria google-services.json em android/app/
//    - Cria GoogleService-Info.plist em ios/Runner/
//    - Regenera este arquivo com os valores reais do seu projeto.
// ============================================================

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
        throw UnsupportedError(
          'DefaultFirebaseOptions não configurado para a plataforma: '
          '$defaultTargetPlatform. Execute "flutterfire configure".',
        );
    }
  }

  // ── Substitua pelos valores do seu projeto Firebase ───────────────────────

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBbuNKPS3BiNNp9puF5_sNa7rYDLnLrkZA',
    appId: '1:529288831226:android:49a3fc8145990f30756943',
    messagingSenderId: '529288831226',
    projectId: 'trackly-6b3da',
    storageBucket: 'trackly-6b3da.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB22Q7qp7cLtSbSV36xYWChU-J1UJg3L94',
    appId: '1:529288831226:ios:0ab9dfb574f962a1756943',
    messagingSenderId: '529288831226',
    projectId: 'trackly-6b3da',
    storageBucket: 'trackly-6b3da.firebasestorage.app',
    iosBundleId: 'com.tabajara.trackly.trackly',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'SUA_WEB_API_KEY',
    appId: 'SEU_WEB_APP_ID',
    messagingSenderId: 'SEU_MESSAGING_SENDER_ID',
    projectId: 'SEU_PROJECT_ID',
    storageBucket: 'SEU_PROJECT_ID.appspot.com',
    authDomain: 'SEU_PROJECT_ID.firebaseapp.com',
  );
}
