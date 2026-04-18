import 'package:flutter/material.dart';

/// Provides inner box scroll state from DynamicScroll to descendants.
class InnerBoxScrolledProvider extends InheritedWidget {
  const InnerBoxScrolledProvider({
    required this.isInnerBoxScrolled,
    required super.child,
    super.key,
  });

  final bool isInnerBoxScrolled;

  static bool of(final BuildContext context) {
    final InnerBoxScrolledProvider? provider =
        context.dependOnInheritedWidgetOfExactType<InnerBoxScrolledProvider>();
    return provider?.isInnerBoxScrolled ?? false;
  }

  @override
  bool updateShouldNotify(final InnerBoxScrolledProvider oldWidget) =>
      isInnerBoxScrolled != oldWidget.isInnerBoxScrolled;
}
