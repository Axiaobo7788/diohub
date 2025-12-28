import 'package:diohub/providers/repository/commit_graph_provider.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:diohub/view/repository/commits/commit_graph_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommitsTab extends StatelessWidget {
  const CommitsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repositoryProvider = context.repoProvider(listen: false);

    return ChangeNotifierProvider<CommitGraphProvider>(
      create: (_) => CommitGraphProvider(
        repositoryProvider: repositoryProvider,
      ),
      child:  CommitGraphView(),
    );
  }
}






