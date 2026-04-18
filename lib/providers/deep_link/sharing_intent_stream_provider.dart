import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

Uri? _firstUrlFromSharedMedia(final List<SharedMediaFile> list) {
  for (final SharedMediaFile media in list) {
    if (media.type == SharedMediaType.url ||
        media.type == SharedMediaType.text) {
      if (media.path.isNotEmpty) {
        return Uri.tryParse(media.path);
      }
    }
  }
  return null;
}

final sharingIntentStreamProvider = StreamProvider.autoDispose<Uri?>(
  (ref) => ReceiveSharingIntent.instance
      .getMediaStream()
      .map(_firstUrlFromSharedMedia),
);
