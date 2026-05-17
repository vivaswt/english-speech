extension IterableExtension<T> on Iterable<T> {
  Future<List<S>> asyncMapSequential<S>(Future<S> Function(T) f) =>
      Stream.fromIterable(this).asyncMap(f).toList();

  Iterable<U> zipWith<S, U>(U Function(T, S) f, Iterable<S> ss) sync* {
    final itrT = iterator;
    final itrS = ss.iterator;
    while (itrT.moveNext() && itrS.moveNext()) {
      yield f(itrT.current, itrS.current);
    }
  }
}
