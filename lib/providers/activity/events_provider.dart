import 'package:diohub/common/events/events.dart' show Events;
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub_models/models/events/events_model.dart';
import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/services/activity/events_service.dart';
import 'package:diohub/utils/pagination/infinite_pagination_data_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'events_provider.freezed.dart';

/// Key for the events list: [specificUser] (when set), [orgLogin] (when set),
/// or [privateEvents] for received vs public.
@freezed
abstract class EventsQueryKey with _$EventsQueryKey {
  const EventsQueryKey._();

  const factory EventsQueryKey({
    String? specificUser,
    String? orgLogin,
    @Default(true) bool privateEvents,
  }) = _EventsQueryKey;
}

/// Fetches one page of events. Use from [Events] widget.
/// Requires [ref] for [currentUserProvider] when [key.privateEvents] is true.
Future<List<EventsModel>> fetchEventsPage(
  final WidgetRef ref,
  final EventsQueryKey key,
  final PageRequest<EventsModel> request,
) {
  final EventsService eventsService = EventsService(ref.read(apiClientProvider));
  if (key.orgLogin != null) {
    return eventsService.getOrgEvents(
      key.orgLogin!,
      page: request.page ?? 1,
      perPage: request.pageSize ?? 10,
      refresh: request.refresh ?? false,
    );
  }
  if (key.specificUser != null) {
    return eventsService.getUserEvents(
      key.specificUser,
      page: request.page ?? 1,
      perPage: request.pageSize ?? 10,
      refresh: request.refresh ?? false,
    );
  }
  if (key.privateEvents) {
    final AsyncValue<ViewerInfo?> userAsync = ref.read(currentUserProvider);
    if (!userAsync.hasValue || userAsync.value == null) {
      return Future<List<EventsModel>>.value(<EventsModel>[]);
    }
    return eventsService.getReceivedEvents(
      userAsync.value!.login,
      page: request.page ?? 1,
      perPage: request.pageSize ?? 10,
      refresh: request.refresh ?? false,
    );
  }
  return eventsService.getPublicEvents(
    page: request.page ?? 1,
    perPage: request.pageSize ?? 10,
    refresh: request.refresh ?? false,
  );
}
