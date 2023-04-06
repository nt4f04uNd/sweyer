import 'package:sweyer/logic/logic.dart';

abstract class _FakeJsonSerializer<R, S> extends JsonSerializer<R, S> {
  @override
  String get fileName => '';

  @override
  S get initialValue => throw UnimplementedError();

  @override
  Future<void> init() async {}

  @override
  Future<void> save(S data) async {}
}

/// All methods do nothing, except [read], which just returns the [value].
class FakeJsonSerializer<R, S> extends _FakeJsonSerializer<R, S> {
  FakeJsonSerializer(this.value);
  final R value;

  @override
  Future<R> read() async {
    return value;
  }
}

/// Like [FakeJsonSerializer] but the [value] can be updated.
class UpdatableFakeSerializer<R> extends _FakeJsonSerializer<R, R> {
  UpdatableFakeSerializer(this.value);
  R value;

  @override
  Future<R> read() async {
    return value;
  }

  @override
  Future<void> save(R data) async {
    value = data;
  }
}
