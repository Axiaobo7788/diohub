import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final uniLinkStreamProvider = StreamProvider.autoDispose<Uri?>(
  (ref) => AppLinks()
      .stringLinkStream
      .map((final String? s) => s != null ? Uri.tryParse(s) : null),
);
