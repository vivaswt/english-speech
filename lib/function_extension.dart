extension PipableFunction<S, T> on T Function(S s) {
  U Function(S) pipe<U>(U Function(T) f) =>
      (S s) => f(this(s));
  T Function(S) tap(void Function(T) f) => (S s) {
    final result = this(s);
    f(result);
    return result;
  };
}

extension PipableVoidFuncton<T> on T Function() {
  U Function() pipe<U>(U Function(T) f) =>
      () => f(this());
  T Function() tap(void Function(T) f) => () {
    final result = this();
    f(result);
    return result;
  };
}
