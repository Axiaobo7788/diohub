import 'dart:async';

import 'package:diohub/l10n/l10n.dart';
import 'package:flutter/material.dart';

Future<void> runSettingsUpdate(
  final BuildContext context,
  final Future<void> update,
) async {
  try {
    await update;
  } on Object {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.settingsSaveError)));
  }
}

class SettingsPageHeading extends StatelessWidget {
  const SettingsPageHeading({
    required this.title,
    required this.description,
    this.trailing,
    super.key,
  });

  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailing case final Widget action) ...<Widget>[
              const SizedBox(width: 16),
              action,
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class Md3SettingsSection extends StatelessWidget {
  const Md3SettingsSection({
    required this.title,
    required this.children,
    this.description,
    super.key,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (description case final String value) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Card.outlined(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List<Widget>.generate(
              children.length * 2 - 1,
              (final int index) =>
                  index.isOdd ? const Divider(height: 1) : children[index ~/ 2],
            ),
          ),
        ),
      ],
    ),
  );
}

class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(final BuildContext context) => SwitchListTile(
    value: value,
    onChanged: enabled ? onChanged : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    title: Text(title),
    subtitle: Text(subtitle),
  );
}

class SettingsChoiceRow<T> extends StatelessWidget {
  const SettingsChoiceRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onSelected,
    super.key,
  });

  final String title;
  final String subtitle;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
    builder: (final BuildContext context, final BoxConstraints constraints) {
      final bool stacked = constraints.maxWidth < 560;
      final Widget copy = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
      final Widget menu = DropdownMenu<T>(
        key: ValueKey<Object>(('settings-choice', title, value)),
        initialSelection: value,
        width: stacked ? constraints.maxWidth - 40 : 240,
        dropdownMenuEntries: values
            .map(
              (final T option) => DropdownMenuEntry<T>(
                value: option,
                label: labelBuilder(option),
              ),
            )
            .toList(growable: false),
        onSelected: (final T? option) {
          if (option != null && option != value) {
            onSelected(option);
          }
        },
      );
      return Padding(
        padding: const EdgeInsets.all(20),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[copy, const SizedBox(height: 16), menu],
              )
            : Row(
                children: <Widget>[
                  Expanded(child: copy),
                  const SizedBox(width: 24),
                  menu,
                ],
              ),
      );
    },
  );
}

class SettingsSliderRow extends StatefulWidget {
  const SettingsSliderRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabelBuilder,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double value) valueLabelBuilder;
  final ValueChanged<double> onChanged;

  @override
  State<SettingsSliderRow> createState() => _SettingsSliderRowState();
}

class _SettingsSliderRowState extends State<SettingsSliderRow> {
  late double _draftValue;

  @override
  void initState() {
    super.initState();
    _draftValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant final SettingsSliderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _draftValue = widget.value;
    }
  }

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Text(
              widget.valueLabelBuilder(_draftValue),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          widget.subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Slider(
          value: _draftValue.clamp(widget.min, widget.max),
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          label: widget.valueLabelBuilder(_draftValue),
          onChanged: (final double value) =>
              setState(() => _draftValue = value),
          onChangeEnd: widget.onChanged,
        ),
      ],
    ),
  );
}

class SettingsActionRow extends StatelessWidget {
  const SettingsActionRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onPressed;
  final Widget? trailing;

  @override
  Widget build(final BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: trailing ?? const Icon(Icons.chevron_right),
    onTap: onPressed,
  );
}
