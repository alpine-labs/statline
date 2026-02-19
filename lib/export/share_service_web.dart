import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Share a CSV string by triggering a browser download.
Future<void> shareCsvContent(String csvContent, String fileName) async {
  final bytes = utf8.encode(csvContent);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

/// Share plain text by copying to clipboard on web.
Future<void> shareTextContent(String text, {String? subject}) async {
  await html.window.navigator.clipboard?.writeText(text);
}
