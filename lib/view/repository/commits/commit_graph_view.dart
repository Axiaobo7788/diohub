import 'package:auto_route/auto_route.dart';
import 'package:diohub/app/global.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.data.gql.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/repository/commit_graph_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:provider/provider.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class CommitGraphView extends StatefulWidget {
  const CommitGraphView({super.key});

  @override
  State<CommitGraphView> createState() => _CommitGraphViewState();
}

class _CommitGraphViewState extends State<CommitGraphView> {
  Graph graph = Graph();
  late BuchheimWalkerConfiguration builder;
  late BuchheimWalkerAlgorithm algorithm;

  @override
  void initState() {
    super.initState();
    builder = BuchheimWalkerConfiguration(
      orientation: BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM,
      siblingSeparation: 60,
      levelSeparation: 120,
      subtreeSeparation: 60,
    );
    algorithm = BuchheimWalkerAlgorithm(
      builder,
      TreeEdgeRenderer(builder),
    );
  }

  double _calculateGraphHeight(int commitCount) {
    // Estimate height based on commit count
    // Each commit node is approximately 120px tall (including spacing)
    // Add some padding for the graph layout
    return (commitCount * 120.0).clamp(400.0, double.infinity);
  }

  void _buildGraph(CommitGraphData data) {
    if (kDebugMode) {
      log.d(
          '[CommitGraphView] Building graph with ${data.commits.length} commits');
    }

    // Create new graph for each build
    graph = Graph();

    final Map<String, Node> nodes = {};

    // Create nodes for each commit
    for (final commit in data.commits) {
      final oid = commit.oid;
      final node = Node.Id(oid);
      nodes[oid] = node;
      graph.addNode(node);
    }

    if (kDebugMode) {
      log.d('[CommitGraphView] Created ${nodes.length} nodes');
    }

    // Create edges (parent → child relationships)
    int edgeCount = 0;
    for (final commit in data.commits) {
      final oid = commit.oid;
      final childNode = nodes[oid];
      if (childNode == null) {
        if (kDebugMode) {
          log.w('[CommitGraphView] Child node not found for commit $oid');
        }
        continue;
      }

      // Get parent OIDs from commit
      final parentOids = commit.parents.edges
              ?.map((e) => e?.node?.oid)
              .whereType<String>()
              .toList() ??
          [];

      for (final parentOid in parentOids) {
        final parentNode = nodes[parentOid];
        if (parentNode != null) {
          graph.addEdge(parentNode, childNode);
          edgeCount++;
        } else {
          if (kDebugMode) {
            log.w(
                '[CommitGraphView] Parent commit $parentOid not found in nodes for commit ${commit.oid}');
          }
        }
      }
    }

    if (kDebugMode) {
      log.d('[CommitGraphView] Created $edgeCount edges');
      log.d(
          '[CommitGraphView] Graph nodes: ${graph.nodes.length}, edges: ${graph.edges.length}');

      // Log branch labels
      final commitsWithLabels = data.commits
          .where((c) => data.branchTips[c.oid]?.isNotEmpty ?? false)
          .toList();
      log.d(
          '[CommitGraphView] ${commitsWithLabels.length} commits have branch labels');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommitGraphProvider>(
      builder: (context, provider, _) {
        if (kDebugMode) {
          log.d(
              '[CommitGraphView] Building widget, status: ${provider.status}');
        }

        // Handle initialized and loading states - don't access data until loaded
        if (provider.status == Status.loading ||
            provider.status == Status.initialized) {
          if (kDebugMode) {
            log.d('[CommitGraphView] Showing loading indicator');
          }
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.status == Status.error) {
          if (kDebugMode) {
            log.e('[CommitGraphView] Error state: ${provider.errorInfo}');
          }
          return const Center(
            child: Text('Error loading commits'),
          );
        }

        // Only access data when status is loaded
        final data = provider.data;
        if (data.commits.isEmpty) {
          if (kDebugMode) {
            log.w('[CommitGraphView] No commits found');
          }
          return const Center(child: Text('No commits found'));
        }

        if (kDebugMode) {
          log.d(
              '[CommitGraphView] Rendering graph with ${data.commits.length} commits, branch: ${data.selectedBranch}');
        }

        _buildGraph(data);

        return SizedBox(
          width: double.infinity,
          height: _calculateGraphHeight(data.commits.length),
          child: InteractiveViewer(
            constrained: false,
            minScale: 0.1,
            maxScale: 2.0,
            child: GraphView(
              graph: graph,
              algorithm: algorithm,
              builder: (Node node) {
                final commitOid = node.key?.value as String?;
                if (commitOid == null) {
                  if (kDebugMode) {
                    log.w('[CommitGraphView] Node has null key value');
                  }
                  return const SizedBox.shrink();
                }

                final commit = data.commits.firstWhere(
                  (c) => c.oid == commitOid,
                  orElse: () {
                    if (kDebugMode) {
                      log.w(
                          '[CommitGraphView] Commit $commitOid not found in data');
                    }
                    throw StateError('Commit $commitOid not found');
                  },
                );
                final branchLabels = data.branchTips[commit.oid] ?? [];

                if (kDebugMode && branchLabels.isNotEmpty) {
                  log.d(
                      '[CommitGraphView] Commit ${commit.abbreviatedOid} has branch labels: $branchLabels');
                }

                return CommitNodeWidget(
                  commit: commit,
                  branchLabels: branchLabels,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class CommitNodeWidget extends StatelessWidget {
  const CommitNodeWidget({
    required this.commit,
    required this.branchLabels,
    super.key,
  });

  final GcommitListItem commit;
  final List<String> branchLabels;

  Color _getBranchColor(String branch) {
    final hash = branch.hashCode;
    return Color.fromRGBO(
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      hash & 0x0000FF,
      0.3,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AutoRouter.of(context).push(
          CommitInfoRoute(commitURL: commit.commitUrl.toString()),
        );
      },
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 200,
          maxWidth: 200,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: branchLabels.isNotEmpty
                ? _getBranchColor(branchLabels.first)
                : context.colorScheme.outline.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Branch labels
            if (branchLabels.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: branchLabels.map((branch) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getBranchColor(branch),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      branch,
                      style: context.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 8),

            // Commit hash
            Text(
              commit.abbreviatedOid,
              style: context.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: context.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 4),

            // Commit message
            Flexible(
              child: Text(
                commit.messageHeadline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall,
              ),
            ),

            const SizedBox(height: 8),

            // Author
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: commit.author?.user?.avatarUrl != null
                      ? NetworkImage(
                          commit.author?.user?.avatarUrl.toString() ?? '',
                        )
                      : null,
                  child: commit.author?.user?.avatarUrl == null
                      ? Icon(
                          MdiIcons.account,
                          size: 16,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    commit.author?.user?.login ??
                        commit.author?.name ??
                        'Unknown',
                    style: context.textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
