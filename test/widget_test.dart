import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_nutritions/shared/widgets/pop_card.dart';

void main() {
  testWidgets('PopCard renders child content', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PopCard(child: Text('Food Nutritions'))),
      ),
    );

    expect(find.text('Food Nutritions'), findsOneWidget);
  });
}
