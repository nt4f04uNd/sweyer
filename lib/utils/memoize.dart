class _Memo3Cache<R, A1, A2, A3> {
  final R r;
  final A1 a1;
  final A2 a2;
  final A3 a3;

  _Memo3Cache(
    this.r,
    this.a1,
    this.a2,
    this.a3,
  );
}

_Memo3Cache? _memo3Cache;

R memo3<R, A1, A2, A3>(R Function() valueBuilder, A1 a1, A2 a2, A3 a3) {
  final memo3Cache = _memo3Cache;
  if (memo3Cache != null &&
      identical(a1, memo3Cache.a1) &&
      identical(a2, memo3Cache.a2) &&
      identical(a3, memo3Cache.a3)) {
    return memo3Cache.r;
  } else {
    final r = valueBuilder();
    _memo3Cache = _Memo3Cache<R, A1, A2, A3>(
      r,
      a1,
      a2,
      a3,
    );
    return r;
  }
}

class _Memo4Cache<R, A1, A2, A3, A4> {
  final R r;
  final A1 a1;
  final A2 a2;
  final A3 a3;
  final A4 a4;

  _Memo4Cache(
    this.r,
    this.a1,
    this.a2,
    this.a3,
    this.a4,
  );
}

_Memo4Cache? _memo4Cache;

R memo4<R, A1, A2, A3, A4>(R Function() valueBuilder, A1 a1, A2 a2, A3 a3, A4 a4) {
  final memo3Cache = _memo4Cache;
  if (memo3Cache != null &&
      identical(a1, memo3Cache.a1) &&
      identical(a2, memo3Cache.a2) &&
      identical(a3, memo3Cache.a3) &&
      identical(a4, memo3Cache.a4)) {
    return memo3Cache.r;
  } else {
    final r = valueBuilder();
    _memo4Cache = _Memo4Cache<R, A1, A2, A3, A4>(
      r,
      a1,
      a2,
      a3,
      a4,
    );
    return r;
  }
}
