import 'package:flutter_glados/flutter_glados.dart';

void main() {
  Glados<double>().test('division', (a) => expect(a / a, equals(1)));
}
