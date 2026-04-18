/// A builder widget that exposes Riverpod mutation state to its child.
///
/// This is a **pure state-to-UI builder** -- it does not own any tap
/// handling. The parent widget (e.g. `BorderedContainer(onTap:)`,
/// `TapFeedback`, `ActionCard`) owns the gesture.
///
/// Example:
/// ```dart
/// BorderedContainer(
///   onTap: mutation.isIdle
///       ? () => ref.read(starNotifier(repo).notifier).toggleStar()
///       : null,
///   child: MutationBuilder(
///     mutation: ref.watch(starMutationProvider(repo)),
///     builder: (context, state) {
///       return state.when(
///         idle: () => const Icon(Icons.star_border),
///         loading: () => const ButtonSpinner(size: 16),
///         success: (_) => const Icon(Icons.check, color: Colors.green),
///         error: (e) => const Icon(Icons.error_outline, color: Colors.red),
///       );
///     },
///   ),
/// )
/// ```
library;

import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:flutter/material.dart';

class MutationBuilder<T> extends StatelessWidget {
  const MutationBuilder({
    required this.mutation,
    required this.builder,
    super.key,
  });

  /// The current mutation state to observe.
  final MutationState<T> mutation;

  /// Builder that renders the UI based on the mutation state.
  final Widget Function(
    BuildContext context,
    MutationState<T> state,
  ) builder;

  @override
  Widget build(final BuildContext context) => builder(context, mutation);
}
