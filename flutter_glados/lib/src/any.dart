import 'dart:math';

import 'anys.dart';
import 'errors.dart';
import 'generator.dart';

/// The [any] singleton, providing a namespace for [Generator]s.
///
/// New [Generator]s should be added as extension methods, so you can use them
/// with a syntax like this: `any.int`
final any = Any();

/// A namespace for all [Generator]s.
///
/// You can register an [Generator] as the default [Generator] for a given
/// type. Then, you don't need to pass the concrete [Generator] to [Glados]
/// anymore – [Glados] can infer the right [Generator] only given the generic
/// types.
class Any {
  /// A map from [Type]s to their default [Generator].
  static final _defaults = <_TypeWrapper<dynamic>, Generator<dynamic>>{
    ..._defaultGenerators
  };

  static void setDefault<T>(Generator<T> generator) {
    _defaults[_TypeWrapper<T>()] = generator;
  }

  static Generator<T> defaultFor<T>() {
    return (_defaults[_TypeWrapper<T>()] as Generator<T>?) ??
        (throw InternalNoGeneratorFound());
  }

  static Generator<T> defaultForWithBeautifulError<T>(
    int numGladosArgs,
    int typeIndex,
  ) {
    try {
      return defaultFor<T>();
    } on InternalNoGeneratorFound {
      throw NoGeneratorFound(numGladosArgs, typeIndex, T);
    }
  }
}

class _TypeWrapper<T> {
  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;
  @override
  int get hashCode => runtimeType.hashCode;
}

/// Useful utilities for creating [Geneator]s that behave just like you want to.
extension AnyUtils on Any {
  /// Creates a new, simple [Generator] that produces values and knows how to
  /// simplify them.
  Generator<T> simple<T>({
    required T Function(Random random, int size) generate,
    required Iterable<T> Function(T input) shrink,
  }) {
    // Map both given functions to the semantics of generators: Instead of
    // having two top-level functions, we have one function that generates
    // `ShrinkableValue`s that each know how the shrink themselves.

    late Shrinkable<T> Function(T) generateShrinkable;
    generateShrinkable = (T value) {
      return Shrinkable(value, () sync* {
        for (final value in shrink(value)) {
          yield generateShrinkable(value);
        }
      });
    };
    return (random, size) {
      return generateShrinkable(generate(random, size));
    };
  }

  /// Returns always the same value.
  Generator<T> always<T>(T value) =>
      simple(generate: (_, __) => value, shrink: (_) => []);

  /// Chooses between the given values. Values further at the front of the
  /// list are considered less complex.
  Generator<T> choose<T>(List<T> values) {
    assert(values.toSet().length == values.length,
        'The list of values given to any.choice contains duplicate items.');
    return simple(
      generate: (random, size) => values[random.nextInt(
        size.clamp(0, values.length),
      )],
      shrink: (option) sync* {
        final index = values.indexOf(option);
        if (index > 0) yield values[index - 1];
      },
    );
  }

  /// Uses either one of the provided generators to generate a value.
  ///
  /// See [oneOf] for a version of this method to be used if the number of
  /// generators is not known at compile-time.
  Generator<T> either<T>(
    Generator<T> first,
    Generator<T> second, [
    Generator<T>? third,
    Generator<T>? fourth,
    Generator<T>? fifth,
    Generator<T>? sixth,
    Generator<T>? seventh,
    Generator<T>? nineth,
    Generator<T>? tenth,
  ]) {
    return oneOf([
      first,
      second,
      if (third != null) third,
      if (fourth != null) fourth,
      if (fifth != null) fifth,
      if (sixth != null) sixth,
      if (seventh != null) seventh,
      if (nineth != null) nineth,
      if (tenth != null) tenth,
    ]);
  }

  /// Uses one of the supplied generators to generate a value.
  ///
  /// See [either] for a version of this method if the number of generators is
  /// known at compile-time.
  Generator<T> oneOf<T>(List<Generator<T>> generators) {
    return choose(generators).bind((generator) => generator);
  }
}

extension CombinableAny on Any {
  /// Combines n values. Is not typesafe, so it's private.
  Generator<T> _combineN<T>(
    List<Generator<dynamic>> generators,
    T Function(List<dynamic> values) combiner,
  ) {
    return (random, size) {
      return ShrinkableCombination(<Shrinkable<dynamic>>[
        for (final generator in generators) generator(random, size),
      ], combiner);
    };
  }

  /// Combines 2 values.
  Generator<T> combine2<A, B, T>(
    Generator<A> aGenerator,
    Generator<B> bGenerator,
    T Function(A a, B b) combiner,
  ) {
    return _combineN(
      [aGenerator, bGenerator],
      (values) => combiner(values[0] as A, values[1] as B),
    );
  }

  /// Combines 3 values.
  Generator<T> combine3<A, B, C, T>(
    Generator<A> aGenerator,
    Generator<B> bGenerator,
    Generator<C> cGenerator,
    T Function(A a, B b, C c) combiner,
  ) {
    return _combineN(
      [aGenerator, bGenerator, cGenerator],
      (values) => combiner(values[0] as A, values[1] as B, values[2] as C),
    );
  }

  /// Combines 4 values.
  Generator<T> combine4<A, B, C, D, T>(
    Generator<A> aGenerator,
    Generator<B> bGenerator,
    Generator<C> cGenerator,
    Generator<D> dGenerator,
    T Function(A a, B b, C c, D d) combiner,
  ) {
    return _combineN(
      [aGenerator, bGenerator, cGenerator, dGenerator],
      (values) => combiner(
        values[0] as A,
        values[1] as B,
        values[2] as C,
        values[3] as D,
      ),
    );
  }

  /// Combines 5 values.
  Generator<T> combine5<T0, T1, T2, T3, T4, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    T Function(T0 arg0, T1 arg1, T2 arg2, T3 arg3, T4 arg4) combiner,
  ) {
    return _combineN(
      [generator0, generator1, generator2, generator3, generator4],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
      ),
    );
  }

  /// Combines 6 values.
  Generator<T> combine6<T0, T1, T2, T3, T4, T5, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    T Function(T0 arg0, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5) combiner,
  ) {
    return _combineN(
      [generator0, generator1, generator2, generator3, generator4, generator5],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
      ),
    );
  }

  // Combines 7 values.
  Generator<T> combine7<T0, T1, T2, T3, T4, T5, T6, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    Generator<T6> generator6,
    T Function(T0 arg0, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6)
        combiner,
  ) {
    return _combineN(
      [
        generator0, generator1, generator2, generator3, generator4, generator5,
        generator6 //
      ],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
        values[6] as T6,
      ),
    );
  }

  // Combines 8 values.
  Generator<T> combine8<T0, T1, T2, T3, T4, T5, T6, T7, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    Generator<T6> generator6,
    Generator<T7> generator7,
    T Function(T0 arg0, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6,
            T7 arg7)
        combiner,
  ) {
    return _combineN(
      [
        generator0, generator1, generator2, generator3, generator4, generator5,
        generator6, generator7 //
      ],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
        values[6] as T6,
        values[7] as T7,
      ),
    );
  }

  // Combines 9 values.
  Generator<T> combine9<T0, T1, T2, T3, T4, T5, T6, T7, T8, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    Generator<T6> generator6,
    Generator<T7> generator7,
    Generator<T8> generator8,
    T Function(T0 arg0, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6,
            T7 arg7, T8 arg8)
        combiner,
  ) {
    return _combineN(
      [
        generator0, generator1, generator2, generator3, generator4, generator5,
        generator6, generator7, generator8 //
      ],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
        values[6] as T6,
        values[7] as T7,
        values[8] as T8,
      ),
    );
  }

  // Combines 10 values.
  Generator<T> combine10<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    Generator<T6> generator6,
    Generator<T7> generator7,
    Generator<T8> generator8,
    Generator<T9> generator9,
    T Function(T0 arg0, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6,
            T7 arg7, T8 arg8, T9 arg9)
        combiner,
  ) {
    return _combineN(
      [
        generator0, generator1, generator2, generator3, generator4, generator5,
        generator6, generator7, generator8, generator9 //
      ],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
        values[6] as T6,
        values[7] as T7,
        values[8] as T8,
        values[9] as T9,
      ),
    );
  }

  // Combines 11 values.
  Generator<T> combine11<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    Generator<T6> generator6,
    Generator<T7> generator7,
    Generator<T8> generator8,
    Generator<T9> generator9,
    Generator<T10> generator10,
    T Function(T0 arg0, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6,
            T7 arg7, T8 arg8, T9 arg9, T10 arg10)
        combiner,
  ) {
    return _combineN(
      [
        generator0, generator1, generator2, generator3, generator4, generator5,
        generator6, generator7, generator8, generator9, generator10 //
      ],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
        values[6] as T6,
        values[7] as T7,
        values[8] as T8,
        values[9] as T9,
        values[10] as T10,
      ),
    );
  }

  // Combines 12 values.
  Generator<T> combine12<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    Generator<T6> generator6,
    Generator<T7> generator7,
    Generator<T8> generator8,
    Generator<T9> generator9,
    Generator<T10> generator10,
    Generator<T11> generator11,
    T Function(T0 arg0, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6,
            T7 arg7, T8 arg8, T9 arg9, T10 arg10, T11 arg11)
        combiner,
  ) {
    return _combineN(
      [
        generator0, generator1, generator2, generator3, generator4, generator5,
        generator6, generator7, generator8, generator9, generator10,
        generator11 //
      ],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
        values[6] as T6,
        values[7] as T7,
        values[8] as T8,
        values[9] as T9,
        values[10] as T10,
        values[11] as T11,
      ),
    );
  }

  // Combines 13 values.
  Generator<T>
      combine13<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    Generator<T6> generator6,
    Generator<T7> generator7,
    Generator<T8> generator8,
    Generator<T9> generator9,
    Generator<T10> generator10,
    Generator<T11> generator11,
    Generator<T12> generator12,
    T Function(T0 arg0, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6,
            T7 arg7, T8 arg8, T9 arg9, T10 arg10, T11 arg11, T12 arg12)
        combiner,
  ) {
    return _combineN(
      [
        generator0, generator1, generator2, generator3, generator4, generator5,
        generator6, generator7, generator8, generator9, generator10,
        generator11, generator12 //
      ],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
        values[6] as T6,
        values[7] as T7,
        values[8] as T8,
        values[9] as T9,
        values[10] as T10,
        values[11] as T11,
        values[12] as T12,
      ),
    );
  }

  // Combines 14 values.
  Generator<T>
      combine14<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    Generator<T6> generator6,
    Generator<T7> generator7,
    Generator<T8> generator8,
    Generator<T9> generator9,
    Generator<T10> generator10,
    Generator<T11> generator11,
    Generator<T12> generator12,
    Generator<T13> generator13,
    T Function(
            T0 arg0,
            T1 arg1,
            T2 arg2,
            T3 arg3,
            T4 arg4,
            T5 arg5,
            T6 arg6,
            T7 arg7,
            T8 arg8,
            T9 arg9,
            T10 arg10,
            T11 arg11,
            T12 arg12,
            T13 arg13)
        combiner,
  ) {
    return _combineN(
      [
        generator0, generator1, generator2, generator3, generator4, generator5,
        generator6, generator7, generator8, generator9, generator10,
        generator11, generator12, generator13 //
      ],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
        values[6] as T6,
        values[7] as T7,
        values[8] as T8,
        values[9] as T9,
        values[10] as T10,
        values[11] as T11,
        values[12] as T12,
        values[13] as T13,
      ),
    );
  }

  // Combines 15 values.
  Generator<T> combine15<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
      T13, T14, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    Generator<T6> generator6,
    Generator<T7> generator7,
    Generator<T8> generator8,
    Generator<T9> generator9,
    Generator<T10> generator10,
    Generator<T11> generator11,
    Generator<T12> generator12,
    Generator<T13> generator13,
    Generator<T14> generator14,
    T Function(
            T0 arg0,
            T1 arg1,
            T2 arg2,
            T3 arg3,
            T4 arg4,
            T5 arg5,
            T6 arg6,
            T7 arg7,
            T8 arg8,
            T9 arg9,
            T10 arg10,
            T11 arg11,
            T12 arg12,
            T13 arg13,
            T14 arg14)
        combiner,
  ) {
    return _combineN(
      [
        generator0, generator1, generator2, generator3, generator4, generator5,
        generator6, generator7, generator8, generator9, generator10,
        generator11, generator12, generator13, generator14 //
      ],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
        values[6] as T6,
        values[7] as T7,
        values[8] as T8,
        values[9] as T9,
        values[10] as T10,
        values[11] as T11,
        values[12] as T12,
        values[13] as T13,
        values[14] as T14,
      ),
    );
  }

  // Combines 16 values.
  Generator<T> combine16<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
      T13, T14, T15, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    Generator<T6> generator6,
    Generator<T7> generator7,
    Generator<T8> generator8,
    Generator<T9> generator9,
    Generator<T10> generator10,
    Generator<T11> generator11,
    Generator<T12> generator12,
    Generator<T13> generator13,
    Generator<T14> generator14,
    Generator<T15> generator15,
    T Function(
            T0 arg0,
            T1 arg1,
            T2 arg2,
            T3 arg3,
            T4 arg4,
            T5 arg5,
            T6 arg6,
            T7 arg7,
            T8 arg8,
            T9 arg9,
            T10 arg10,
            T11 arg11,
            T12 arg12,
            T13 arg13,
            T14 arg14,
            T15 arg15)
        combiner,
  ) {
    return _combineN(
      [
        generator0, generator1, generator2, generator3, generator4, generator5,
        generator6, generator7, generator8, generator9, generator10,
        generator11, generator12, generator13, generator14, generator15 //
      ],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
        values[6] as T6,
        values[7] as T7,
        values[8] as T8,
        values[9] as T9,
        values[10] as T10,
        values[11] as T11,
        values[12] as T12,
        values[13] as T13,
        values[14] as T14,
        values[15] as T15,
      ),
    );
  }

  // Combines 17 values.
  Generator<T> combine17<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
      T13, T14, T15, T16, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    Generator<T6> generator6,
    Generator<T7> generator7,
    Generator<T8> generator8,
    Generator<T9> generator9,
    Generator<T10> generator10,
    Generator<T11> generator11,
    Generator<T12> generator12,
    Generator<T13> generator13,
    Generator<T14> generator14,
    Generator<T15> generator15,
    Generator<T16> generator16,
    T Function(
            T0 arg0,
            T1 arg1,
            T2 arg2,
            T3 arg3,
            T4 arg4,
            T5 arg5,
            T6 arg6,
            T7 arg7,
            T8 arg8,
            T9 arg9,
            T10 arg10,
            T11 arg11,
            T12 arg12,
            T13 arg13,
            T14 arg14,
            T15 arg15,
            T16 arg16)
        combiner,
  ) {
    return _combineN(
      [
        generator0,
        generator1,
        generator2,
        generator3,
        generator4,
        generator5,
        generator6,
        generator7,
        generator8,
        generator9,
        generator10,
        generator11,
        generator12,
        generator13,
        generator14,
        generator15,
        generator16 //
      ],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
        values[6] as T6,
        values[7] as T7,
        values[8] as T8,
        values[9] as T9,
        values[10] as T10,
        values[11] as T11,
        values[12] as T12,
        values[13] as T13,
        values[14] as T14,
        values[15] as T15,
        values[16] as T16,
      ),
    );
  }

  // Combines 18 values.
  Generator<T> combine18<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
      T13, T14, T15, T16, T17, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    Generator<T6> generator6,
    Generator<T7> generator7,
    Generator<T8> generator8,
    Generator<T9> generator9,
    Generator<T10> generator10,
    Generator<T11> generator11,
    Generator<T12> generator12,
    Generator<T13> generator13,
    Generator<T14> generator14,
    Generator<T15> generator15,
    Generator<T16> generator16,
    Generator<T17> generator17,
    T Function(
            T0 arg0,
            T1 arg1,
            T2 arg2,
            T3 arg3,
            T4 arg4,
            T5 arg5,
            T6 arg6,
            T7 arg7,
            T8 arg8,
            T9 arg9,
            T10 arg10,
            T11 arg11,
            T12 arg12,
            T13 arg13,
            T14 arg14,
            T15 arg15,
            T16 arg16,
            T17 arg17)
        combiner,
  ) {
    return _combineN(
      [
        generator0,
        generator1,
        generator2,
        generator3,
        generator4,
        generator5,
        generator6,
        generator7,
        generator8,
        generator9,
        generator10,
        generator11,
        generator12,
        generator13,
        generator14,
        generator15,
        generator16,
        generator17 //
      ],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
        values[6] as T6,
        values[7] as T7,
        values[8] as T8,
        values[9] as T9,
        values[10] as T10,
        values[11] as T11,
        values[12] as T12,
        values[13] as T13,
        values[14] as T14,
        values[15] as T15,
        values[16] as T16,
        values[17] as T17,
      ),
    );
  }

  // Combines 19 values.
  Generator<T> combine19<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
      T13, T14, T15, T16, T17, T18, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    Generator<T6> generator6,
    Generator<T7> generator7,
    Generator<T8> generator8,
    Generator<T9> generator9,
    Generator<T10> generator10,
    Generator<T11> generator11,
    Generator<T12> generator12,
    Generator<T13> generator13,
    Generator<T14> generator14,
    Generator<T15> generator15,
    Generator<T16> generator16,
    Generator<T17> generator17,
    Generator<T18> generator18,
    T Function(
            T0 arg0,
            T1 arg1,
            T2 arg2,
            T3 arg3,
            T4 arg4,
            T5 arg5,
            T6 arg6,
            T7 arg7,
            T8 arg8,
            T9 arg9,
            T10 arg10,
            T11 arg11,
            T12 arg12,
            T13 arg13,
            T14 arg14,
            T15 arg15,
            T16 arg16,
            T17 arg17,
            T18 arg18)
        combiner,
  ) {
    return _combineN(
      [
        generator0,
        generator1,
        generator2,
        generator3,
        generator4,
        generator5,
        generator6,
        generator7,
        generator8,
        generator9,
        generator10,
        generator11,
        generator12,
        generator13,
        generator14,
        generator15,
        generator16,
        generator17,
        generator18 //
      ],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
        values[6] as T6,
        values[7] as T7,
        values[8] as T8,
        values[9] as T9,
        values[10] as T10,
        values[11] as T11,
        values[12] as T12,
        values[13] as T13,
        values[14] as T14,
        values[15] as T15,
        values[16] as T16,
        values[17] as T17,
        values[18] as T18,
      ),
    );
  }

  // Combines 20 values.
  Generator<T> combine20<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
      T13, T14, T15, T16, T17, T18, T19, T>(
    Generator<T0> generator0,
    Generator<T1> generator1,
    Generator<T2> generator2,
    Generator<T3> generator3,
    Generator<T4> generator4,
    Generator<T5> generator5,
    Generator<T6> generator6,
    Generator<T7> generator7,
    Generator<T8> generator8,
    Generator<T9> generator9,
    Generator<T10> generator10,
    Generator<T11> generator11,
    Generator<T12> generator12,
    Generator<T13> generator13,
    Generator<T14> generator14,
    Generator<T15> generator15,
    Generator<T16> generator16,
    Generator<T17> generator17,
    Generator<T18> generator18,
    Generator<T19> generator19,
    T Function(
            T0 arg0,
            T1 arg1,
            T2 arg2,
            T3 arg3,
            T4 arg4,
            T5 arg5,
            T6 arg6,
            T7 arg7,
            T8 arg8,
            T9 arg9,
            T10 arg10,
            T11 arg11,
            T12 arg12,
            T13 arg13,
            T14 arg14,
            T15 arg15,
            T16 arg16,
            T17 arg17,
            T18 arg18,
            T19 arg19)
        combiner,
  ) {
    return _combineN(
      [
        generator0,
        generator1,
        generator2,
        generator3,
        generator4,
        generator5,
        generator6,
        generator7,
        generator8,
        generator9,
        generator10,
        generator11,
        generator12,
        generator13,
        generator14,
        generator15,
        generator16,
        generator17,
        generator18,
        generator19
      ],
      (values) => combiner(
        values[0] as T0,
        values[1] as T1,
        values[2] as T2,
        values[3] as T3,
        values[4] as T4,
        values[5] as T5,
        values[6] as T6,
        values[7] as T7,
        values[8] as T8,
        values[9] as T9,
        values[10] as T10,
        values[11] as T11,
        values[12] as T12,
        values[13] as T13,
        values[14] as T14,
        values[15] as T15,
        values[16] as T16,
        values[17] as T17,
        values[18] as T18,
        values[19] as T19,
      ),
    );
  }
}

class ShrinkableCombination<T> implements Shrinkable<T> {
  ShrinkableCombination(this.fields, this.combiner);

  final List<Shrinkable<dynamic>> fields;
  final T Function(List<dynamic> values) combiner;

  @override
  T get value {
    return combiner(fields.map((shrinkable) => shrinkable.value).toList());
  }

  @override
  Iterable<Shrinkable<T>> shrink() sync* {
    for (var i = 0; i < fields.length; i++) {
      for (final shrunk in fields[i].shrink()) {
        yield ShrinkableCombination(List.of(fields)..[i] = shrunk, combiner);
      }
    }
  }
}

final _defaultGenerators = {
  // ignore: prefer_void_to_null
  _TypeWrapper<Null>(): any.null_,
  _TypeWrapper<bool>(): any.bool,
  _TypeWrapper<int>(): any.int,
  _TypeWrapper<double>(): any.double,
  _TypeWrapper<num>(): any.num,
  _TypeWrapper<BigInt>(): any.bigInt,
  _TypeWrapper<DateTime>(): any.dateTime,
  _TypeWrapper<Duration>(): any.duration,
  _TypeWrapper<List<bool>>(): any.list(any.bool),
  _TypeWrapper<List<int>>(): any.list(any.int),
  _TypeWrapper<List<double>>(): any.list(any.double),
  _TypeWrapper<List<num>>(): any.list(any.num),
  _TypeWrapper<List<BigInt>>(): any.list(any.bigInt),
  _TypeWrapper<List<DateTime>>(): any.list(any.dateTime),
  _TypeWrapper<List<Duration>>(): any.list(any.duration),
  _TypeWrapper<Set<int>>(): any.set(any.int),
  _TypeWrapper<Set<BigInt>>(): any.set(any.bigInt),
  _TypeWrapper<Map<int, bool>>(): any.map(any.int, any.bool),
  _TypeWrapper<Map<int, int>>(): any.map(any.int, any.int),
  _TypeWrapper<Map<int, double>>(): any.map(any.int, any.double),
  _TypeWrapper<Map<int, num>>(): any.map(any.int, any.num),
  _TypeWrapper<Map<int, BigInt>>(): any.map(any.int, any.bigInt),
  _TypeWrapper<Map<int, DateTime>>(): any.map(any.int, any.dateTime),
  _TypeWrapper<Map<int, Duration>>(): any.map(any.int, any.duration),
  _TypeWrapper<Map<int, bool>>(): any.map(any.int, any.bool),
  _TypeWrapper<Map<BigInt, int>>(): any.map(any.bigInt, any.int),
  _TypeWrapper<Map<BigInt, double>>(): any.map(any.bigInt, any.double),
  _TypeWrapper<Map<BigInt, num>>(): any.map(any.bigInt, any.num),
  _TypeWrapper<Map<BigInt, BigInt>>(): any.map(any.bigInt, any.bigInt),
  _TypeWrapper<Map<BigInt, DateTime>>(): any.map(any.bigInt, any.dateTime),
  _TypeWrapper<Map<BigInt, Duration>>(): any.map(any.bigInt, any.duration),
};
