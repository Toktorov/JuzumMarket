import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:juzum/main.dart';
import 'package:juzum/data/app_state.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const JuzumApp(),
      ),
    );

    // Splash должен отрендериться (MaterialApp присутствует).
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
