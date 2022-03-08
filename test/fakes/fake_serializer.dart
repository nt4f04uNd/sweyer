import 'package:sweyer/logic/logic.dart';

/// All methods, do nothing except [read], which just returns the [value].
class FakeJsonSerializer<R, S> extends JsonSerializer<R, S> {
  FakeJsonSerializer(this.value);
  final R value;

  @override
  String get fileName => '';

  @override
  S get initialValue => throw UnimplementedError();

  @override
  Future<void> init() async {}

  @override
  Future<R> read() async {
    return value;
  }

  @override
  Future<void> save(S data) async {}
}