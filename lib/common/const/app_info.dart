import 'package:diohub/common/const/app_tokens.dart';
import 'package:diohub/common/const/version_info.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

class AppNameWidget extends StatelessWidget {
  const AppNameWidget({required this.size, super.key});
  final double size;

  @override
  Widget build(final BuildContext context) => Text.rich(
        AppTokens.appNameSpan(
          style:
              Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: size),
        ),
      );
}

class AppLogoWidget extends StatelessWidget {
  const AppLogoWidget({required this.size, super.key});
  final double size;

  @override
  Widget build(final BuildContext context) => Image.asset(
        'assets/icon/splash_logo.png',
        width: size,
        height: size,
      );
}

class AppInfoWidget extends StatelessWidget {
  const AppInfoWidget({
    super.key,
    this.axis = Axis.vertical,
    this.logoSize,
    this.nameSize = 24,
  });
  final Axis axis;
  final double? logoSize;
  final double nameSize;

  @override
  Widget build(final BuildContext context) {
    final List<Widget> children = <Widget>[
      AppLogoWidget(size: logoSize ?? MediaQuery.of(context).size.width * 0.3),
      AppNameWidget(
        size: nameSize,
      ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (axis == Axis.vertical)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
      ],
    );
  }
}

class AppNameWithVersion extends StatelessWidget {
  const AppNameWithVersion({super.key});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: context.spacing.chipPadding,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            AppNameWidget(
              size: 20,
            ),
            VersionInfoWidget(),
          ],
        ),
      );
}
