import 'package:diohub/common/search/client_text_matcher.dart';
import 'package:diohub/common/search/match_strategy.dart';
import 'package:diohub/common/search/type_filter.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:test/test.dart';

void main() {
  group('SubstringMatch', () {
    const strategy = SubstringMatch();

    test('matches exact substring', () {
      expect(strategy.matches('flutter', 'flut'), isTrue);
      expect(strategy.matches('flutter', 'flutter'), isTrue);
    });

    test('does not match non-substring', () {
      expect(strategy.matches('flutter', 'fltr'), isFalse);
      expect(strategy.matches('react', 'fltr'), isFalse);
    });

    test('is case-insensitive when inputs are lowercased', () {
      expect(strategy.matches('flutter', 'flut'), isTrue);
      expect(strategy.matches('FLUTTER'.toLowerCase(), 'flut'), isTrue);
    });

    test('empty query matches everything', () {
      expect(strategy.matches('anything', ''), isTrue);
    });
  });

  group('FuzzyMatch', () {
    test('matches exact substring (short-circuit)', () {
      const strategy = FuzzyMatch(threshold: 70);
      expect(strategy.matches('flutter', 'flut'), isTrue);
    });

    test('matches typo within threshold', () {
      const strategy = FuzzyMatch(threshold: 70);
      expect(strategy.matches('flutter', 'fltr'), isTrue);
    });

    test('rejects typo below threshold', () {
      const strategy = FuzzyMatch(threshold: 90);
      expect(strategy.matches('react', 'fltr'), isFalse);
    });

    test('keeps exact substring matching for single-char query', () {
      const strategy = FuzzyMatch(threshold: 70);
      expect(strategy.matches('flutter', 'f'), isTrue);
      expect(strategy.matches('flutter', 'z'), isFalse);
    });
  });

  group('ClientTextMatcher', () {
    test('matches against any field', () {
      final matcher = ClientTextMatcher<_User>(
        fields: [(u) => u.login, (u) => u.name],
      );
      final user = _User('alice', 'Alice Smith');
      expect(matcher.matches(user, 'ali'), isTrue);
      expect(matcher.matches(user, 'smith'), isTrue);
      expect(matcher.matches(user, 'xyz'), isFalse);
    });

    test('skips null fields', () {
      final matcher = ClientTextMatcher<_User>(
        fields: [(u) => u.login, (u) => u.name],
      );
      final user = _User('bob', null);
      expect(matcher.matches(user, 'bob'), isTrue);
      expect(matcher.matches(user, 'alice'), isFalse);
    });

    test('empty query returns all', () {
      final matcher = ClientTextMatcher<_User>(fields: [(u) => u.login]);
      final users = [_User('a', null), _User('b', null)];
      expect(matcher.filter(users, ''), equals(users));
      expect(matcher.filter(users, '   '), equals(users));
    });

    test('filter returns matching subset', () {
      final matcher = ClientTextMatcher<_User>(
        fields: [(u) => u.login, (u) => u.name],
      );
      final users = [
        _User('alice', 'Alice'),
        _User('bob', 'Bob'),
        _User('carol', 'Carol'),
      ];
      expect(matcher.filter(users, 'al'), [users[0]]);
      expect(matcher.filter(users, 'bob'), [users[1]]);
    });

    test('toClientFilter produces compatible callback', () {
      final matcher = ClientTextMatcher<_User>(fields: [(u) => u.login]);
      final fn = matcher.toClientFilter();
      expect(fn(_User('alice', null), 'ali'), isTrue);
      expect(fn(_User('bob', null), 'ali'), isFalse);
    });
  });

  group('typeFilter', () {
    test('retains only matching type', () {
      final FilterFn fn = typeFilter<int>();
      final items = <Object>[1, 'two', 3, 4.0, 5];
      final result = fn(items);
      expect(result, [1, 3, 5]);
    });

    test('empty list returns empty', () {
      final FilterFn fn = typeFilter<String>();
      expect(fn(<Object>[]), isEmpty);
    });
  });
}

class _User {
  _User(this.login, this.name);
  final String login;
  final String? name;
}
