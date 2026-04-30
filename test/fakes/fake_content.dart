import 'dart:async';

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

  final _contentChanges = StreamController<void>.broadcast();

  @override
  Stream<void> get onContentChange => _contentChanges.stream;

  @override
  void emitContentChange() {
    if (!disposed.value && !_contentChanges.isClosed) {
      _contentChanges.add(null);
    }
  }

  @override
  // ignore: must_call_super
  Future<void> init() async {
    initializing = false;
    stateNullable ??= ContentState();
    disposed.value = false;
    emitContentChange();
  }

  @override
  // ignore: must_call_super
  void dispose() {
    if (!disposed.value) {
      disposed.value = true;
      _contentChanges.close();
    }
  }
}
