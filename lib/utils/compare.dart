extension NullableCompare<T extends Comparable<Comparable<T>>> on Comparable<T>? {
  int compareToNullable(T? other, {nullCompareResult = -1}) {
    final self = this;
    if (self != null) {
      return self.compareToNullable(other, nullCompareResult: nullCompareResult);
    }
    if (other != null) {
      return -other.compareToNullable(self, nullCompareResult: nullCompareResult);
    }
    return 0;
  }
}

extension CompareNullable<T> on Comparable<T> {
  int compareToNullable(T? other, {nullCompareResult = -1}) {
    if (other != null) {
      return compareTo(other);
    }
    return nullCompareResult;
  }
}
