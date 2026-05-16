import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/widgets/load_error_view.dart';

void main() {
  testWidgets('LoadErrorView appelle onRetry au tap', (WidgetTester tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          extensions: <ThemeExtension<dynamic>>[SmartHomeColors.dark],
        ),
        home: Scaffold(
          body: LoadErrorView(
            message: 'Erreur réseau simulée',
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(find.text('Réessayer'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    expect(retries, 1);
  });
}
