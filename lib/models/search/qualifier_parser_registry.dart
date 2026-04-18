import 'package:diohub/common/search_overlay/filters.dart' show SearchType;
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub_models/models/search/search_ranges.dart';
import 'package:diohub/models/search/search_scope.dart';

/// Type of picker to show for a qualifier in suggestion overlay / filter sheet.
enum PickerType {
  options,
  userSearch,
  text,
  numericRange,
  dateRange,
  bool_,
  label,
  milestone,
  branch,
}

/// Parser for one qualifier key. Each key has its own parser (no giant regex).
abstract class QualifierValueParser {
  const QualifierValueParser();

  /// Try to parse raw value string into a typed [Qualifier]. Returns null if invalid.
  Qualifier? tryParse(String key, String rawValue);

  /// Valid options for suggestion overlay (null = dynamic/free-form).
  List<String>? get staticOptions => null;

  PickerType get pickerType;
}

/// Parses option qualifiers like is:open, review:approved, type:pr.
class OptionValueParser extends QualifierValueParser {
  const OptionValueParser(this.validOptions, this.factory);
  final Map<String, String> validOptions;
  final Qualifier Function(String value) factory;

  @override
  PickerType get pickerType => PickerType.options;
  @override
  List<String>? get staticOptions => validOptions.keys.toList();

  @override
  Qualifier? tryParse(String key, String rawValue) {
    if (!validOptions.containsKey(rawValue.toLowerCase())) return null;
    return factory(rawValue.toLowerCase());
  }
}

/// Parses user qualifiers like author:naman, assignee:me.
class UserValueParser extends QualifierValueParser {
  const UserValueParser(this.factory);
  final Qualifier Function(UserRef) factory;

  @override
  PickerType get pickerType => PickerType.userSearch;

  @override
  Qualifier? tryParse(String key, String rawValue) {
    if (rawValue.isEmpty) return null;
    return factory(UserRef(login: rawValue.trim()));
  }
}

/// Parses text qualifiers like label:bug, language:dart.
class TextValueParser extends QualifierValueParser {
  const TextValueParser(this.factory, {this.pickerOverride});
  final Qualifier Function(String) factory;
  final PickerType? pickerOverride;

  @override
  PickerType get pickerType => pickerOverride ?? PickerType.text;

  @override
  Qualifier? tryParse(String key, String rawValue) {
    if (rawValue.isEmpty) return null;
    final unquoted = rawValue.startsWith('"') && rawValue.endsWith('"')
        ? rawValue.substring(1, rawValue.length - 1)
        : rawValue;
    return factory(unquoted.trim());
  }
}

/// Parses numeric range qualifiers like stars:>100, comments:10..50.
class NumericRangeParser extends QualifierValueParser {
  const NumericRangeParser(this.factory);
  final Qualifier Function(NumericRange) factory;

  @override
  PickerType get pickerType => PickerType.numericRange;

  @override
  Qualifier? tryParse(String key, String rawValue) {
    final range = tryParseNumericRange(rawValue);
    return range != null ? factory(range) : null;
  }
}

/// Parses date range qualifiers like created:>2024-01-01.
class DateRangeParser extends QualifierValueParser {
  const DateRangeParser(this.factory);
  final Qualifier Function(DateRange) factory;

  @override
  PickerType get pickerType => PickerType.dateRange;

  @override
  Qualifier? tryParse(String key, String rawValue) {
    final range = tryParseDateRange(rawValue);
    return range != null ? factory(range) : null;
  }
}

/// Parses bool qualifiers like draft:true, archived:false.
class BoolValueParser extends QualifierValueParser {
  const BoolValueParser(this.factory);
  final Qualifier Function(bool value) factory;

  @override
  PickerType get pickerType => PickerType.bool_;

  @override
  Qualifier? tryParse(String key, String rawValue) {
    final lower = rawValue.toLowerCase();
    if (lower == 'true') return factory(true);
    if (lower == 'false') return factory(false);
    return null;
  }
}

/// Parses repo:owner/name.
class RepoValueParser extends QualifierValueParser {
  const RepoValueParser();

  @override
  PickerType get pickerType => PickerType.text;

  @override
  Qualifier? tryParse(String key, String rawValue) {
    final t = rawValue.trim();
    if (t.isEmpty || !t.contains('/')) return null;
    final parts = t.split('/');
    if (parts.length != 2) return null;
    return RepoQualifier(
        RepoRef(owner: parts[0].trim(), name: parts[1].trim()));
  }
}

/// Parses org:login.
class OrgValueParser extends QualifierValueParser {
  const OrgValueParser();

  @override
  PickerType get pickerType => PickerType.text;

  @override
  Qualifier? tryParse(String key, String rawValue) {
    final t = rawValue.trim();
    if (t.isEmpty) return null;
    return OrgQualifier(t);
  }
}

/// Tokenizer that respects quoted values: label:"good first issue".
List<String> tokenizeQualifierText(String text) {
  final tokens = <String>[];
  final buf = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '"') {
      inQuotes = !inQuotes;
      buf.write(c);
    } else if (c == ' ' && !inQuotes) {
      if (buf.isNotEmpty) {
        tokens.add(buf.toString());
        buf.clear();
      }
    } else {
      buf.write(c);
    }
  }
  if (buf.isNotEmpty) tokens.add(buf.toString());
  return tokens;
}

/// Registry of qualifier key → parser. Replaces giant regex for parsing.
class QualifierParserRegistry {
  const QualifierParserRegistry(this.entries);
  final Map<String, QualifierValueParser> entries;

  /// Parse a single token like "is:open" or "-label:bug".
  QualifierExpression? parseToken(String token) {
    final negated = token.startsWith('-');
    final clean = negated ? token.substring(1) : token;
    final colonIdx = clean.indexOf(':');
    if (colonIdx < 0) return null;

    final key = clean.substring(0, colonIdx).toLowerCase();
    final value = clean.substring(colonIdx + 1);
    if (value.isEmpty) return null;

    final parser = entries[key];
    if (parser == null) return null;
    final qualifier = parser.tryParse(key, value);
    if (qualifier == null) return null;
    return QualifierExpression(qualifier, negated: negated);
  }

  /// Extract all complete qualifiers from text; return remaining free text.
  ({List<QualifierExpression> qualifiers, String freeText}) extractFromText(
      String text) {
    final tokens = tokenizeQualifierText(text);
    final qualifiers = <QualifierExpression>[];
    final freeTokens = <String>[];
    for (final token in tokens) {
      final q = parseToken(token);
      if (q != null) {
        qualifiers.add(q);
      } else {
        freeTokens.add(token);
      }
    }
    return (qualifiers: qualifiers, freeText: freeTokens.join(' '));
  }

  /// Parser for a partial token (e.g. "is:" for suggestions).
  QualifierValueParser? parserForPartial(String partialToken) {
    if (!partialToken.contains(':')) return null;
    final key =
        partialToken.substring(0, partialToken.indexOf(':')).toLowerCase();
    return entries[key];
  }

  static QualifierParserRegistry forScope(SearchScope scope) =>
      QualifierParserRegistry(
          _buildEntries(scope.searchType, scope.blacklistedQualifiers));
}

IsOption _parseIsOption(String v) {
  return switch (v) {
    'open' => IsOption.open,
    'closed' => IsOption.closed,
    'merged' => IsOption.merged,
    'unmerged' => IsOption.unmerged,
    'public' => IsOption.public_,
    'private' => IsOption.private_,
    'internal' => IsOption.internal_,
    'locked' => IsOption.locked,
    'unlocked' => IsOption.unlocked,
    'answered' => IsOption.answered,
    'unanswered' => IsOption.unanswered,
    'curated' => IsOption.curated,
    'featured' => IsOption.featured,
    'sponsorable' => IsOption.sponsorable,
    'queued' => IsOption.queued,
    _ => IsOption.open,
  };
}

Map<String, QualifierValueParser> _buildEntries(
    SearchType type, List<String> blacklist) {
  final entries = <String, QualifierValueParser>{};

  if (type == SearchType.issuesPulls) {
    entries['is'] = OptionValueParser(
      const {
        'open': 'Open',
        'closed': 'Closed',
        'merged': 'Merged',
        'unmerged': 'Unmerged',
        'public': 'Public',
        'private': 'Private',
        'internal': 'Internal',
        'locked': 'Locked',
        'unlocked': 'Unlocked',
        'answered': 'Answered',
        'unanswered': 'Unanswered',
        'curated': 'Curated',
        'featured': 'Featured',
        'sponsorable': 'Sponsorable',
        'queued': 'Queued',
      },
      (v) => IsQualifier(_parseIsOption(v)),
    );
    entries['state'] = OptionValueParser(
      const {'open': 'Open', 'closed': 'Closed'},
      (v) => v == 'open' ? Qualifier.stateOpen() : Qualifier.stateClosed(),
    );
    entries['type'] = OptionValueParser(
      const {'issue': 'Issue', 'pr': 'Pull Request'},
      (v) => v == 'issue' ? Qualifier.typeIssue() : Qualifier.typePr(),
    );
    entries['label'] = TextValueParser(
      Qualifier.label,
      pickerOverride: PickerType.label,
    );
    entries['assignee'] = UserValueParser(Qualifier.assignee);
    entries['author'] = UserValueParser(Qualifier.author);
    entries['mentions'] = UserValueParser(Qualifier.mentions);
    entries['commenter'] = UserValueParser(Qualifier.commenter);
    entries['involves'] = UserValueParser(Qualifier.involves);
    entries['review-requested'] = UserValueParser(Qualifier.reviewRequested);
    entries['reviewed-by'] = UserValueParser(Qualifier.reviewedBy);
    entries['milestone'] = TextValueParser(
      Qualifier.milestone,
      pickerOverride: PickerType.milestone,
    );
    entries['repo'] = const RepoValueParser();
    entries['org'] = const OrgValueParser();
    entries['created'] = DateRangeParser(Qualifier.created);
    entries['updated'] = DateRangeParser(Qualifier.updated);
    entries['closed'] = DateRangeParser(Qualifier.closed);
    entries['merged'] = DateRangeParser(Qualifier.merged);
    entries['comments'] = NumericRangeParser(Qualifier.comments);
    entries['reactions'] = NumericRangeParser(Qualifier.reactions);
    entries['interactions'] = NumericRangeParser(Qualifier.interactions);
    entries['draft'] = BoolValueParser(Qualifier.draft);
    entries['archived'] = BoolValueParser(Qualifier.archived);
    entries['base'] = TextValueParser(Qualifier.base);
    entries['head'] = TextValueParser(Qualifier.head);
  }

  if (type == SearchType.repositories) {
    entries['user'] = UserValueParser(Qualifier.user);
    entries['org'] = const OrgValueParser();
    entries['repo'] = const RepoValueParser();
    entries['language'] = TextValueParser(Qualifier.language);
    entries['topic'] = TextValueParser(Qualifier.topic);
    entries['stars'] = NumericRangeParser(Qualifier.stars);
    entries['forks'] = NumericRangeParser(Qualifier.forks);
    entries['created'] = DateRangeParser(Qualifier.created);
    entries['pushed'] = DateRangeParser(Qualifier.pushed);
    entries['archived'] = BoolValueParser(Qualifier.archived);
    entries['mirror'] = BoolValueParser(Qualifier.mirror);
    entries['template'] = BoolValueParser(Qualifier.template);
  }

  if (type == SearchType.discussions) {
    entries['is'] = OptionValueParser(
      const {
        'open': 'Open',
        'closed': 'Closed',
        'answered': 'Answered',
        'unanswered': 'Unanswered',
      },
      (v) => switch (v) {
        'closed' => Qualifier.isClosed,
        'answered' => Qualifier.isAnswered,
        'unanswered' => Qualifier.isUnanswered,
        _ => Qualifier.isOpen,
      },
    );
    entries['author'] = UserValueParser(Qualifier.author);
    entries['answered-by'] = UserValueParser(Qualifier.answeredBy);
    entries['repo'] = const RepoValueParser();
    entries['created'] = DateRangeParser(Qualifier.created);
    entries['comments'] = NumericRangeParser(Qualifier.comments);
  }

  for (final key in blacklist) {
    entries.remove(key);
  }
  return entries;
}
