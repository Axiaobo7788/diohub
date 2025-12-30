import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/markdown_view/widgets/readme_image_view.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;

/// Builds an image widget from an HTML img element
Widget buildImageTag(
  final dom.Element element, {
  required final Iterable<MarkdownImgSrcModifiers>? imgSrcModifiers,
}) {
  String src = element.attributes['src']!;
  for (final MarkdownImgSrcModifiers modifier
      in imgSrcModifiers ?? <MarkdownImgSrcModifiers>[]) {
    src = modifier.call(
      MarkdownImgSrcData(src),
    );
  }
  return Padding(
    padding: const EdgeInsets.all(4),
    child: ReadmeImageView(
      url: src,
      height: double.tryParse(
        element.attributes['height'] ?? '',
      ),
      width: double.tryParse(
        element.attributes['width'] ?? '',
      ),
    ),
  );
}
