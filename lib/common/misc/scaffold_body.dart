import 'package:diohub/adapters/internet_connectivity.dart';
import 'package:diohub/common/animations/animations.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScaffoldBody extends ConsumerWidget {
  const ScaffoldBody({
    super.key,
    this.child,
    this.header,
  });
  final Widget? child;
  final Widget? header;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final networkStream = ref.read(internetConnectivityProvider).networkStream;
    return Column(
      children: <Widget>[
        header ??
            StreamBuilder<NetworkStatus>(
              stream: networkStream,
              builder: (
                final BuildContext context,
                final AsyncSnapshot<NetworkStatus> snapshot,
              ) =>
                  Stack(
                children: <Widget>[
                  AnimatedVisibility(
                    visible: snapshot.data == NetworkStatus.offline,
                    transition: AnimationTransition.size,
                    child: Container(
                      width: double.infinity,
                      color: context.colorScheme.error,
                      child: Padding(
                        padding: EdgeInsets.all(context.spacing.itemSpacing),
                        child: Center(
                          child: Text(
                            'Network Lost. Showing cached data.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedVisibility(
                    visible: snapshot.data == NetworkStatus.restored,
                    transition: AnimationTransition.size,
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.all(context.spacing.itemSpacing),
                        child: Center(
                          child: Text(
                            'Online',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        Expanded(child: child ?? Container()),
      ],
    );
  }
}
