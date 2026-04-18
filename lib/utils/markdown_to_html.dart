import 'package:diohub_models/models/server_config.dart';
import 'package:markdown/markdown.dart';

String mdToHtml(
  final String data, {
  final String? repo,
  final ServerConfig? serverConfig,
}) {
  final String webBase =
      serverConfig?.webBaseUrl ?? ServerConfig.gitHubDotCom.webBaseUrl;
  return markdownToHtml(
    data,
    extensionSet: ExtensionSet.gitHubWeb,
    inlineSyntaxes: <InlineSyntax>[
      TeamMentionSyntax(webBase),
      MentionSyntax(webBase),
      if (repo != null) IssuesPullsNumberSyntax(repo, webBase),
      if (repo != null) IssuesPullsRefSyntaxCurrentRepo(repo, webBase),
      IssuesPullsRefSyntax(webBase: webBase, currentRepo: repo),
    ],
  );
}

class MentionSyntax extends InlineSyntax {
  MentionSyntax(this._webBase) : super(r'\B@\w+');
  final String _webBase;

  @override
  bool onMatch(final InlineParser parser, final Match match) {
    parser.addNode(
      Text(
        '<a href="$_webBase/${match[0]!.substring(1)}" style="color: #ffffff; font-weight:bold">${match[0]}</a>',
      ),
    );
    return true;
  }
}

class TeamMentionSyntax extends InlineSyntax {
  TeamMentionSyntax(this._webBase) : super('\\B@(\\w+)[/]{1}(\\w+)');
  final String _webBase;

  @override
  bool onMatch(final InlineParser parser, final Match match) {
    parser.addNode(
      Text(
        '<a href="$_webBase/orgs/${match[0]!.split('/').first.substring(1)}/teams/${match[0]!.split('/').last}" style="color: #ffffff; font-weight:bold">${match[0]}</a>',
      ),
    );
    return true;
  }
}

class IssuesPullsNumberSyntax extends CustomInlineSyntax {
  IssuesPullsNumberSyntax(this._webBase, final String currentRepo)
      : super('(?:\\#(\\d+))(?!\\w)', currentRepo: currentRepo);
  final String _webBase;

  @override
  bool onMatch(final InlineParser parser, final Match match) {
    parser.addNode(
      Text(
        '<a href="$_webBase/${currentRepo!}/issues/${match[0]!.substring(1)}" style="font-weight:bold">${match[0]}</a>',
      ),
    );
    return true;
  }
}

class IssuesPullsRefSyntaxCurrentRepo extends CustomInlineSyntax {
  IssuesPullsRefSyntaxCurrentRepo(final String currentRepo, this._webBase)
      : super(
          '(/)(?:(issues))(/)(?:(\\d+))(?!\\w)',
          currentRepo: currentRepo,
        );
  final String _webBase;

  @override
  bool onMatch(final InlineParser parser, final Match match) {
    parser.addNode(
      Text(
        '<a href="$_webBase/$currentRepo${match[0]!}" style="font-weight:bold">${match[0]!.replaceAll(currentRepo!, '')}</a>',
      ),
    );
    return true;
  }
}

class IssuesPullsRefSyntax extends CustomInlineSyntax {
  IssuesPullsRefSyntax(
      {final String? currentRepo, required final String webBase})
      : _webBase = webBase,
        super(
          '(?:\\w+)(/)(?:\\w+)(/)(?:(issues))(/)(?:(\\d+))(?!\\w)',
          currentRepo: currentRepo,
        );
  final String _webBase;

  @override
  bool onMatch(final InlineParser parser, final Match match) {
    final matchText = match[0]!;
    if (currentRepo != null && matchText.startsWith(currentRepo!)) {
      final replacedText = matchText.replaceFirst(currentRepo!, '');
      parser.addNode(
        Text(
          '<a href="$_webBase/$matchText" style="font-weight:bold">$replacedText</a>',
        ),
      );
    } else {
      parser.addNode(
        Text(
          '<a href="$_webBase/$matchText" style="font-weight:bold">$matchText</a>',
        ),
      );
    }
    return true;
  }
}

abstract class CustomInlineSyntax extends InlineSyntax {
  CustomInlineSyntax(super.pattern, {this.currentRepo});
  final String? currentRepo;
}
