import '../test.dart';

class FakeContentControl extends ContentControl {
  FakeContentControl() {
    instance = this;
    ContentControl.instance = this;
  }
  static late FakeContentControl instance;

  /// The content held by this ContentControl.
  ContentTuple _content = const ContentTuple();

  @override
  ContentState? stateNullable;

  @override
  bool initializing = false;

  @override
  ValueNotifier<bool> disposed = ValueNotifier(true);

  @override
  List<T> getContent<T extends Content>(
    ContentType<T> contentType, {
    bool filterFavorite = false,
  }) {
    final content = _content.get(contentType);
    if (filterFavorite) {
      return ContentUtils.filterFavorite(content).toList();
    }
    return content;
  }

  /// Set the [content] of this control.
  void setContent(ContentTuple content) {
    _content = content;
  }
}
