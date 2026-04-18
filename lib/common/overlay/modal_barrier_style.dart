import 'package:diohub/style/opacities.dart';
import 'package:flutter/material.dart';

/// Shared modal barrier color for overlays (dialogs, popups, peek).
///
/// Use this so all overlay barriers are consistent and semi-transparent,
/// giving a "dialog over content" feel rather than fully opaque.
Color modalBarrierColor(final BuildContext context) =>
    Theme.of(context).colorScheme.scrim.withValues(alpha: Opacities.scrim);
