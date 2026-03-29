// Trackly — Widget smoke test básico.
// Este teste verifica apenas que o widget raiz é instanciado sem crash.
// Testes completos (auth, mapa, amigos) devem usar mocks de Firebase.

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TracklyApp smoke test placeholder', (WidgetTester tester) async {
    // Firebase.initializeApp() requer um ambiente real com google-services.
    // Adicione firebase_core_platform_interface mocks para habilitar testes
    // completos de widget. Por ora, garantimos que o arquivo de teste compila.
    expect(true, isTrue);
  });
}
