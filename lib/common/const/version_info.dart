import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionInfoWidget extends StatelessWidget {
  const VersionInfoWidget({super.key});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: context.spacing.chipPadding,
        child: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (
            final BuildContext context,
            final AsyncSnapshot<PackageInfo> snapshot,
          ) {
            if (snapshot.hasData) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: ScalableImageWidget.fromSISource(
                      si: ScalableImageSource.fromSvg(
                        rootBundle,
                        'assets/icon/svg/inner_ios.svg',
                      ),
                    ),
                  ),
                  context.spacing.tightGap,
                  Text(
                    snapshot.data!.version,
                    style: context.textTheme.labelSmall?.asMuted(),
                  ),
                ],
              );
            }
            return const LoadingIndicator(
              size: 15,
            );
          },
        ),
      );
}
