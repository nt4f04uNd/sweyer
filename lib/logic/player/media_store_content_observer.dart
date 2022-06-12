import 'package:android_content_provider/android_content_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sweyer/sweyer.dart';

/// An event in [MediaStoreContentObserver.onChangeStream] stream.
class MediaStoreContentChangeEvent {
  final int id;
  final int flags;
  final Type contentType;

  const MediaStoreContentChangeEvent({
    required this.id,
    required this.flags,
    required this.contentType,
  });
}

/// An Android MediaStore content observer.
class MediaStoreContentObserver<T extends Content> extends ContentObserver {
  MediaStoreContentObserver([this.contentType])
      : assert(
          Content.enumerate().contains(T),
          "Specified type must be a subtype of Content",
        );

  final Type? contentType;

  Stream<MediaStoreContentChangeEvent> get onChangeStream => _changeSubject;
  final _changeSubject = PublishSubject<MediaStoreContentChangeEvent>();

  void register() {
    AndroidContentResolver.instance.registerContentObserver(
      uri: _uri,
      observer: this,
      // Can be uncommented for debug purposes - will notify about the changes the app itself
      // made to the MediaStore.
      //
      // notifyForDescendants: true,
    );
  }

  String get _uri => contentPick<T, String>(
        contentType: contentType,
        // MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        song: 'content://media/external/audio/media',
        // MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI
        album: 'content://media/external/audio/albums',
        // MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI
        playlist: 'content://media/external/audio/playlists',
        // MediaStore.Audio.Artists.EXTERNAL_CONTENT_URI
        artist: 'content://media/external/audio/artists',
      );

  @override
  void dispose() {
    AndroidContentResolver.instance.unregisterContentObserver(this);
    _changeSubject.close();
    super.dispose();
  }

  @override
  void onChange(bool selfChange, String? uri, int flags) {
    if (uri != null && uri.startsWith(_uri)) {
      final regexp = RegExp('$_uri/([0-9]+)');
      final match = regexp.firstMatch(uri);
      if (match != null) {
        final capturedNumber = match.group(1);
        if (capturedNumber != null) {
          final id = int.tryParse(capturedNumber);
          if (id != null) {
            _changeSubject.add(MediaStoreContentChangeEvent(
              id: id,
              flags: flags,
              contentType: contentType ?? T,
            ));
          }
        }
      }
    }
  }
}
