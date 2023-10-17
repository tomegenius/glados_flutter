Fork of https://github.com/MarcelGarus/glados with added Flutter Widget testing support.

1. Add dependencies with $ flutter pub get (needs flutter_test from sdk)
2. Go in the example directory and run $ flutter test

This package specifically adds the ability to call Glados<T>().testWidgets().

For example:
`
 Glados3<String, int, String>(
    any.letter,
    any.int,
    any.any.letterOrDigits,
  ).testWidgets('initial messages always sorted by timestamp',
      (tester, s, n, s2) async {
    
    // Build some widgets with random values

    await tester.pumpAndSettle();

    expect(); // Check something

  });
  `
