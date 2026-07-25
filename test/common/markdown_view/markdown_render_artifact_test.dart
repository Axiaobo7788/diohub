import 'package:diohub/common/markdown_view/markdown_render_artifact.dart';
import 'package:test/test.dart';

void main() {
  const MarkdownArtifactParser parser = MarkdownArtifactParser();

  test('extracts stable headings and lazy sections from GitHub wrappers', () {
    const String html = '''
      <div id="readme">
        <article class="markdown-body">
          <p>Introduction</p>
          <div class="markdown-heading"><h1>Hello, World!</h1></div>
          <p>First section</p>
          <h2>Usage &amp; setup</h2>
          <p>Second section</p>
        </article>
      </div>
    ''';

    final MarkdownRenderArtifact artifact = parser.parse(html);

    expect(artifact.headings, hasLength(2));
    expect(artifact.headings.first.text, 'Hello, World!');
    expect(artifact.headings.first.id, 'hello-world');
    expect(artifact.headings.first.level, 1);
    expect(
      artifact.headings.last.id,
      'usage--setup',
      reason: 'The artifact preserves the existing heading ID contract.',
    );
    expect(artifact.sections, hasLength(3));
    expect(artifact.sections.first, contains('Introduction'));
    expect(artifact.sections[1], contains('id="hello-world"'));
    expect(artifact.sections[2], contains('id="usage--setup"'));
    expect(artifact.estimatedWeight, greaterThan(0));
  });

  test('produces deterministic immutable rendering input', () {
    const String html = '<h1>Title</h1><p>Body</p>';

    final MarkdownRenderArtifact first = parser.parse(html);
    final MarkdownRenderArtifact second = parser.parse(html);

    expect(second.sections, first.sections);
    expect(second.headings.single.id, first.headings.single.id);
    expect(second.estimatedWeight, first.estimatedWeight);
  });
}
