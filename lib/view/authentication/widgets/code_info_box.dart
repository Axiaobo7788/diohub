import 'dart:async';

import 'package:diohub/app/api_handler/response_handler.dart';
import 'package:diohub/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:diohub/common/animations/fade_animation_widget.dart';
import 'package:diohub/common/bottom_sheet/url_actions.dart';
import 'package:diohub/models/authentication/device_code_model.dart';
import 'package:diohub/models/popup/popup_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_countdown_timer/countdown_timer_controller.dart';
import 'package:flutter_countdown_timer/current_remaining_time.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';

class CodeInfoBox extends StatefulWidget {
  const CodeInfoBox(this.deviceCodeModel, {super.key});
  final DeviceCodeModel deviceCodeModel;
  @override
  CodeInfoBoxState createState() => CodeInfoBoxState();
}

class CodeInfoBoxState extends State<CodeInfoBox> {
  CountdownTimerController? timerController;
  bool copied = false;

  @override
  void initState() {
    timerController = CountdownTimerController(
      endTime: widget.deviceCodeModel.expiresIn!,
      onEnd: () {
        BlocProvider.of<AuthenticationBloc>(context).add(ResetStates());
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    timerController!.dispose();
    super.dispose();
  }

  Future<void> copyCode({final bool pop = false}) async {
    await Clipboard.setData(
      ClipboardData(text: widget.deviceCodeModel.userCode!),
    );
    if (pop) {
      if (context.mounted) {
        Navigator.pop(context);
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    ResponseHandler.setSuccessMessage(
      AppPopupData(title: 'Copied Code ${widget.deviceCodeModel.userCode}'),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return FadeAnimationSection(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CountdownTimer(
            controller: timerController,
            endWidget: Text(
              'Time Expired.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
            ),
            widgetBuilder: (final _, final CurrentRemainingTime? time) =>
                Column(
              children: <Widget>[
                Text(
                  'Verification Code',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Expires in ${time!.min ?? '00'}:${time.sec! < 10 ? '0' : ''}${time.sec}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: LinearProgressIndicator(
                    value: ((time.min ?? 0) * 60 + time.sec!) /
                        ((widget.deviceCodeModel.expiresIn! -
                                widget.deviceCodeModel.parsedOn!) /
                            1000),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Material(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                child: Column(
                  children: <Widget>[
                    Text(
                      widget.deviceCodeModel.userCode!,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          copied ? Icons.check_circle : Icons.copy,
                          size: 16,
                          color: copied
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          copied ? 'Copied' : 'Tap to copy',
                          style: textTheme.bodySmall?.copyWith(
                            color: copied
                                ? colorScheme.primary
                                : colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Enter this code on:',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (final BuildContext context) {
              final URLActions urlActions = URLActions(
                uri: Uri.parse(widget.deviceCodeModel.verificationUri!),
                shareDescription:
                    'Enter the code ${widget.deviceCodeModel.userCode} on:',
              );
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: urlActions.launchURL,
                  onLongPress: () async {
                    await urlActions.showMenu(context);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Text(
                      widget.deviceCodeModel.verificationUri!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              BlocProvider.of<AuthenticationBloc>(context).add(ResetStates());
            },
            child: Text(
              'Cancel',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
