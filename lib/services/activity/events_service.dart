import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub_models/models/events/events_model.dart';

class EventsService {
  EventsService(ApiClient client) : _restHandler = client.rest;

  final RESTHandler _restHandler;

  // Ref: https://docs.github.com/en/rest/reference/activity#list-events-for-the-authenticated-user
  Future<List<EventsModel>> getUserEvents(
    final String? user, {
    required final bool refresh,
    final int? page,
    final int? perPage,
  }) async {
    final Response<List<dynamic>> response = await _restHandler
        .get<List<dynamic>>(
          '/users/$user/events',
          queryParameters: <String, dynamic>{'per_page': perPage, 'page': page},
          refreshCache: refresh,
        );
    final List<Map<String, dynamic>> unParsedEvents = response.data!
        .cast<Map<String, dynamic>>();
    final List<EventsModel> parsedEvents = <EventsModel>[];
    for (final Map<String, dynamic> event in unParsedEvents) {
      parsedEvents.add(Event.fromJson(event));
    }
    return parsedEvents;
  }

  // Ref: https://docs.github.com/en/rest/reference/activity#list-events-received-by-the-authenticated-user
  Future<List<EventsModel>> getReceivedEvents(
    final String? user, {
    final bool refresh = false,
    final int? perPage,
    final int? page,
  }) async {
    final Map<String, dynamic> parameters = <String, dynamic>{
      'per_page': perPage,
      'page': page,
    };
    final Response<List<dynamic>> response = await _restHandler
        .get<List<dynamic>>(
          '/users/$user/received_events',
          queryParameters: parameters,
          refreshCache: refresh,
        );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map((final Map<String, dynamic> e) => Event.fromJson(e))
        .toList();
  }

  // Ref: https://docs.github.com/en/rest/reference/activity#list-public-events
  Future<List<EventsModel>> getPublicEvents({
    final bool refresh = false,
    final int? perPage,
    final int? page,
  }) async {
    final Map<String, dynamic> parameters = <String, dynamic>{
      'per_page': perPage,
      'page': page,
    };
    final Response<List<dynamic>> response = await _restHandler
        .get<List<dynamic>>(
          '/events',
          queryParameters: parameters,
          refreshCache: refresh,
        );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map((final Map<String, dynamic> e) => Event.fromJson(e))
        .toList();
  }

  // Ref: https://docs.github.com/en/rest/reference/activity#list-organization-events
  Future<List<EventsModel>> getOrgEvents(
    final String org, {
    required final bool refresh,
    final int? page,
    final int? perPage,
  }) async {
    final Response<List<dynamic>> response = await _restHandler
        .get<List<dynamic>>(
          '/orgs/$org/events',
          queryParameters: <String, dynamic>{'per_page': perPage, 'page': page},
          refreshCache: refresh,
        );
    final List<Map<String, dynamic>> unParsedEvents = response.data!
        .cast<Map<String, dynamic>>();
    final List<EventsModel> parsedEvents = <EventsModel>[];
    for (final Map<String, dynamic> event in unParsedEvents) {
      parsedEvents.add(Event.fromJson(event));
    }
    return parsedEvents;
  }
}
