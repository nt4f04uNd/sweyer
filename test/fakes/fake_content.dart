import '../test.dart';

class FakeContentControl extends ContentControl {
  FakeContentControl() {
    instance = this;
    ContentControl.instance = this;
  }
  static late FakeContentControl instance;

  @override
  ContentState? stateNullable;

  @override
  bool initializing = false;

  @override
  ValueNotifier<bool> disposed = ValueNotifier(true);
}
