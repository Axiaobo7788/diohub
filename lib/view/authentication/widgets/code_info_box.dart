import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/providers/account/auth_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub_models/models/authentication/device_code_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/countdown_timer_controller.dart';
import 'package:flutter_countdown_timer/current_remaining_time.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class CodeInfoBox extends ConsumerStatefulWidget {
  const CodeInfoBox(this.deviceCodeResponse, {super.key});
  final DeviceCodeResponse deviceCodeResponse;
  @override
  ConsumerState<CodeInfoBox> createState() => CodeInfoBoxState();
}

class CodeInfoBoxState extends ConsumerState<CodeInfoBox> {
  CountdownTimerController? timerController;
  bool copied = false;
  bool browserLaunchFailed = false;

  @override
  void initState() {
    super.initState();
    timerController = CountdownTimerController(
      endTime:
          DateTime.now().millisecondsSinceEpoch +
          widget.deviceCodeResponse.expiresIn * 1000,
      onEnd: () {
        ref.read(authProvider.notifier).reset();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      unawaited(_prepareAuthorization());
    });
  }

  @override
  void dispose() {
    timerController?.dispose();
    super.dispose();
  }

  Future<void> _prepareAuthorization() async {
    try {
      await copyCode();
      if (mounted) {
        setState(() {
          copied = true;
        });
        unawaited(_clearCopiedIndicator());
      }
    } on Object catch (e, st) {
      AppLogger.warning(
        'Copying the GitHub device code failed',
        error: e,
        stackTrace: st,
        tag: 'Auth',
      );
    }
    await _openVerificationPage();
  }

  Future<void> _clearCopiedIndicator() async {
    await Future<void>.delayed(const Duration(seconds: 4));
    if (mounted) {
      setState(() {
        copied = false;
      });
    }
  }

  Future<void> _openVerificationPage() async {
    try {
      final bool launched = await launchUrl(
        Uri.parse(widget.deviceCodeResponse.verificationUri),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('No system browser is available.');
      }
      if (mounted && browserLaunchFailed) {
        setState(() {
          browserLaunchFailed = false;
        });
      }
    } on Object catch (e, st) {
      AppLogger.warning(
        'Opening the GitHub device verification page failed',
        error: e,
        stackTrace: st,
        tag: 'Auth',
      );
      if (mounted) {
        setState(() {
          browserLaunchFailed = true;
        });
      }
    }
  }

  Future<void> copyCode({final bool pop = false}) async {
    await ref
        .read(clipboardServiceProvider)
        .copy(widget.deviceCodeResponse.userCode);
    if (pop) {
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CountdownTimer(
          controller: timerController,
          endWidget: Text(
            'Time Expired.',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
          ),
          widgetBuilder: (final _, final CurrentRemainingTime? time) => Column(
            children: <Widget>[
              Text(
                'Verification Code',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              context.spacing.sectionGap,
              Center(
                child: Text(
                  'Expires in ${time!.min ?? '00'}:${time.sec! < 10 ? '0' : ''}${time.sec}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.secondary,
                  ),
                ),
              ),
              context.spacing.contentGap,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: LinearProgressIndicator(
                  value:
                      ((time.min ?? 0) * 60 + time.sec!) /
                      widget.deviceCodeResponse.expiresIn,
                ),
              ),
            ],
          ),
        ),
        context.spacing.spaciousGap,
        Material(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: context.radius(RadiusSize.medium),
          child: InkWell(
            onTap: copied
                ? null
                : () async {
                    await copyCode();
                    setState(() {
                      copied = true;
                    });
                    await Future<void>.delayed(const Duration(seconds: 4));
                    if (mounted) {
                      setState(() {
                        copied = false;
                      });
                    }
                  },
            borderRadius: context.radius(RadiusSize.medium),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              child: Column(
                children: <Widget>[
                  Text(
                    widget.deviceCodeResponse.userCode,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  context.spacing.contentGap,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        copied ? Icons.check_circle : Icons.copy,
                        size: 16,
                        color: copied
                            ? colorScheme.primary
                            : colorScheme.onSurface.muted,
                      ),
                      context.spacing.itemGap,
                      Text(
                        copied ? 'Copied' : 'Tap to copy',
                        style: textTheme.bodySmall?.copyWith(
                          color: copied
                              ? colorScheme.primary
                              : colorScheme.onSurface.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        context.spacing.spaciousGap,
        Text(
          'Enter this code on:',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.secondary,
          ),
          textAlign: TextAlign.center,
        ),
        context.spacing.contentGap,
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openVerificationPage,
            borderRadius: context.radius(RadiusSize.small),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: context.spacing.sectionSpacing,
              ),
              child: Text(
                widget.deviceCodeResponse.verificationUri,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        if (browserLaunchFailed) ...<Widget>[
          context.spacing.itemGap,
          Text(
            'The browser did not open automatically. Tap the link above to retry.',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
        context.spacing.spaciousGap,
        TextButton(
          onPressed: () {
            ref.read(authProvider.notifier).reset();
          },
          child: Text(
            'Cancel',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.muted,
            ),
          ),
        ),
      ],
    );
  }
}
