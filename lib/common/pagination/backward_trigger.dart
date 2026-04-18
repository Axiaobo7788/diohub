/// How to trigger loading earlier (backward) items.
sealed class BackwardTrigger {
  const BackwardTrigger();
}

final class ButtonBackwardTrigger extends BackwardTrigger {
  const ButtonBackwardTrigger({this.label = 'Load earlier activity'});
  final String label;
}
