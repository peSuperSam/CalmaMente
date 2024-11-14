import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calmamente/main.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    // Inicialize o aplicativo
    await tester.pumpWidget(const MyApp());

    // Verifique que um widget esperado está na tela inicial
    expect(find.text('Bem-Vindo de Volta'), findsOneWidget); // Altere para um texto relevante na tela inicial do seu app
  });
}
