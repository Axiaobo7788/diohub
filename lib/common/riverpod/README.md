# State management (Riverpod)

This directory holds shared Riverpod utilities and the conventions for mutations, cache invalidation, and UI binding.

## Entity data and refs

- **Entity data** (repo, issue, PR, user, etc.) is keyed by a **ref** (e.g. `RepoRef`, `IssueRef`, `PullRequestRef`) and held in **family providers** (e.g. `repositoryProvider(repoRef)`, `issueDetailProvider(issueRef)`).
- Refs must implement value equality (`==` / `hashCode`) so that the same logical entity always resolves to the same provider instance (e.g. `RepoRef.fromFullName("a/b")` and `RepoRef.fromRepoCardFields(data)` for the same repo).

## Mutation patterns

**One idea for all mutations:** use the **mutation response** to update state when the API returns data. Only invalidate (or refetch) when you don’t have the data to patch. The two patterns below differ only in whether we have an existing entity to optimistically transform first.

### Entity mutations (toggle / update in place)

Use the **optimistic notifier** ([optimistic_notifier.dart](optimistic_notifier.dart)):

- **When**: You are updating a single cached entity (e.g. star repo, close issue, add comment) and the API returns the updated subject or a patch.
- **Pattern**: Call `optimistic(transform: ..., mutation: () => apiCall(), applyResponse: ..., onError: ...)` directly from your notifier. No extra wrappers; use the same API everywhere (repo, issue, PR).
- **Error handling**: Use [showMutationError](mutation_error.dart) in `onError` and in catch blocks so all mutation failures behave the same (haptic + toast).
- **Files**: Mix in `OptimisticFamilyAsyncNotifier` (or `OptimisticAsyncNotifier`) and call `optimistic()` from your notifier methods.

### Fire-and-forget (create / no cached entity)

Use **MutationState** ([mutation_state.dart](mutation_state.dart)):

- **When**: The mutation creates something or doesn’t map to a single cached entity (e.g. fork repo, create issue). You need loading / success / error UI; there’s nothing to optimistically transform.
- **Pattern**: Set `MutationLoading`, run the API call, then set `MutationSuccess` or `MutationError`. After success, **same idea**: patch state from the mutation response when the API returns data (e.g. fork returns the new repo → set `repositoryProvider(forkedRepoRef)` or patch a list). Only invalidate when you don’t have data to patch.

## UI binding

- **Entity screens and cards that can mutate**: Prefer reading from the entity’s provider (e.g. `ref.watch(repositoryProvider(repoRef))`) or use a “by ref” widget that does this and passes the data down. That way optimistic updates and post-mutation state are visible immediately.
- **Lists of entities**: Use a list provider where possible and invalidate it when a mutation changes the list (e.g. starred repos list when the user stars/unstars). List items should use the “by ref” pattern so each item watches the entity provider and shows optimistic state.
- **Snapshot-only data**: Use `RepositoryCard(repoData)` (or equivalent) only when you have no ref or no mutation (e.g. static or external source).

## Entity provider lifecycle

- **Screen-level entity providers** (repo, issue, PR, user, commit): use `keepAliveFor(ref, duration: kEntityCacheDuration)` in `build()`. See [keep_alive_helper.dart](keep_alive_helper.dart). The default duration is already 5 minutes; use the constant so a single change updates all call sites. Document any notifier that uses a different duration or no duration (e.g. short-lived or non-entity).

## Invalidation

- **When**: After a mutation that changes data another screen or list might show, invalidate the relevant provider(s) unless the notifier already patches state from the mutation result (then invalidation is optional).
- **List invalidation**: After star/unstar, fork, follow/unfollow, etc., invalidate the list provider that backs “starred repos”, “my repos”, “followers”, etc.

## Async UI with Riverpod

- Use **Riverpod providers** for any data that has a natural ref or stable key (entity by ref, search by query, file by path). That gives a single cache, optimistic updates, and consistent invalidation.
- Use **AsyncValueBuilder** (or **SliverAsyncValueBuilder**) with `ref.watch(provider)` for all async loading → data → error UI. Do not use raw `AsyncValue.when` for that.

## Checklist for new entity notifiers

- Watch account (if auth affects data): `ref.watch(accountProvider.select(...))`.
- Call `keepAliveFor(ref, duration: kEntityCacheDuration)` in `build()`.
- For in-place mutations: use `optimistic()` with `showMutationError(ref, message)` in `onError`.
- Prefer patching state from the mutation response; invalidate only when you don't have data to patch.
