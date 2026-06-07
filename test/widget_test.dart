import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utsob/main.dart';

void main() {
  testWidgets('Utsob app launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UtsobApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
