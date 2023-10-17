Fork of https://github.com/MarcelGarus/glados with added support for testing Flutter widgets.

This package specifically adds the ability to call `Glados<T>().testWidgets()`.

For instance:
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


# Example

## See it
[example_test.dart](flutter_glados/example/test/example_test.dart)

## Try it
1. $ cd flutter_glados
2. $ flutter pub get (needs flutter_test from sdk)
3. $ cd flutter_glados/example
4. $ flutter test