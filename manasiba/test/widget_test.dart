import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manasiba/main.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ManasibaApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
