/// Strip HTML tags to plain text (e.g. for prefill from titleHTML/bodyHTML).
String htmlToPlain(final String? html) {
  if (html == null || html.isEmpty) return '';
  return html
      .replaceAll(_reHtmlTag, '')
      .replaceAll(_reNbsp, ' ')
      .replaceAll(_reHtmlEntity, ' ')
      .trim();
}

final RegExp _reHtmlTag = RegExp(r'<[^>]*>');
final RegExp _reNbsp = RegExp(r'&nbsp;');
final RegExp _reHtmlEntity = RegExp(r'&[^;]+;');
