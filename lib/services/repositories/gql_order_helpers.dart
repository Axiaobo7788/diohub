import 'package:diohub_graphql/schema.graphql.dart';

/// Utility functions to reduce boilerplate when constructing GQL order types
/// from decomposed enum fields.

Input$RefOrder buildRefOrder({
  Enum$RefOrderField? field,
  Enum$OrderDirection? direction,
  Enum$RefOrderField defaultField = Enum$RefOrderField.ALPHABETICAL,
  Enum$OrderDirection defaultDirection = Enum$OrderDirection.ASC,
}) =>
    Input$RefOrder(
      field: field ?? defaultField,
      direction: direction ?? defaultDirection,
    );

Input$ReleaseOrder buildReleaseOrder({
  Enum$ReleaseOrderField? field,
  Enum$OrderDirection? direction,
}) =>
    Input$ReleaseOrder(
      field: field ?? Enum$ReleaseOrderField.CREATED_AT,
      direction: direction ?? Enum$OrderDirection.DESC,
    );

Input$RepositoryOrder buildRepositoryOrder({
  Enum$RepositoryOrderField? field,
  Enum$OrderDirection? direction,
}) =>
    Input$RepositoryOrder(
      field: field ?? Enum$RepositoryOrderField.PUSHED_AT,
      direction: direction ?? Enum$OrderDirection.DESC,
    );
