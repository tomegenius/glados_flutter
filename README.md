Fork of https://github.com/MarcelGarus/glados with added support for testing Flutter widgets.

This package specifically adds the ability to call Glados<T>().testWidgets().

For example:
```
 Glados3<String, int, String>(
    any.letter,
    any.int,
    any.any.letterOrDigits,
  ).testWidgets('test explanation',
      (tester, s, n, s2) async {
    
    // Build some widgets with random values

    await tester.pumpAndSettle();

    expect(); // Check something

  });
```

# Self-documenting example
1. $ cd flutter glados
1. $ flutter pub get (needs flutter_test from sdk)
2. cd flutter_glados/example
2. run $ flutter test
