import 'package:diohub/providers/account/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ErrorPopup extends ConsumerWidget {
  const ErrorPopup(this.error, {super.key});
  final String error;
  @override
  Widget build(final BuildContext context, final WidgetRef ref) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Divider(
            height: 32,
          ),
          Text(
            'Error'.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(
            height: 32,
          ),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Divider(
            height: 32,
          ),
          Center(
            child: MaterialButton(
              onPressed: () {
                ref.read(authProvider.notifier).reset();
              },
              child: const Text('Retry'),
            ),
          ),
        ],
      );
}
