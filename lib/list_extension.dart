extension ListExtension<T> on List<T> {
  /// Splits a list into a tuple of two lists based on a predicate.
  ///
  /// This function is based on Haskell's `Data.List.span`. It returns a tuple
  /// where the first list is the longest prefix of elements that satisfy the
  /// [test] predicate, and the second list is the remainder of the list.
  ///
  /// Example:
  /// ```dart
  /// final numbers = [1, 2, 3, 4, 1, 2];
  /// final (lessThanFour, remainder) = numbers.span((n) => n < 4);
  /// // lessThanFour is [1, 2, 3]
  /// // remainder is [4, 1, 2]
  /// ```
  (List<T>, List<T>) span(bool Function(T) test) {
    switch (this) {
      case []:
        return ([], []);
      case [final t, ...(final ts)] when test(t):
        final (yts, zts) = ts.span(test);
        return ([t, ...yts], zts);
      default:
        return ([], this);
    }
  }

  /// Groups adjacent elements of a list based on a predicate.
  ///
  /// This function is based on Haskell's `Data.List.groupBy`. It takes a
  /// predicate that compares two adjacent elements and returns a list of lists,
  /// where each inner list contains adjacent elements for which the predicate
  /// was satisfied.
  ///
  /// Example:
  /// ```dart
  /// final numbers = [1, 1, 1, 2, 2, 3, 1, 1];
  /// final grouped = numbers.groupBy((a, b) => a == b);
  /// // grouped is [[1, 1, 1], [2, 2], [3], [1, 1]]
  /// ```
  List<List<T>> groupBy(bool Function(T, T) test) => switch (this) {
    [] => [],
    [final x, ...final xs] => [
      [x, ...xs.span((y) => test(x, y)).$1],
      ...xs.span((y) => test(x, y)).$2.groupBy(test),
    ],
  };
}
