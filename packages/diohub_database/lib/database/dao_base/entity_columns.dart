part of '../database.dart';

/// Column references for the shared entity columns across account-scoped tables.
/// Allows generic predicates (accountScope, forEntity, withEntityFilters)
/// without knowing which table the columns belong to.
/// Nullable columns are still GeneratedColumn<String> in Drift (nullable in SQL).
typedef EntityColumns = ({
  GeneratedColumn<String> accountKey,
  GeneratedColumn<String> nodeId,
  GeneratedColumn<String> entityPath,
  GeneratedColumn<String> entityType,
  GeneratedColumn<String> parentPath,
  GeneratedColumn<String> parentNodeId,
});
