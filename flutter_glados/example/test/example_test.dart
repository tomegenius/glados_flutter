import 'package:flutter/material.dart';
import 'package:flutter_glados/flutter_glados.dart';
import 'package:flutter_test/flutter_test.dart' hide expect, group;

class MyWidget extends StatelessWidget {
  const MyWidget({required this.title, required this.message, Key? key})
      : super(key: key);

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        body: Center(
            child: Column(
          children: [
            Text(title),
            Text(message),
          ],
        )),
      ),
    );
  }
}

void main() {
  group('maximum', () {
    Glados2<String, String>(any.letterOrDigits, any.letterOrDigits).testWidgets(
        'is in the list', (tester, randomString, randomString2) async {
      await tester
          .pumpWidget(MyWidget(title: randomString, message: randomString2));
      final titleFinder = find.text(randomString);
      final messageFinder = find.text(randomString2);

      expect(titleFinder, findsOneWidget);
      expect(messageFinder, findsOneWidget);
    });
  });
}
