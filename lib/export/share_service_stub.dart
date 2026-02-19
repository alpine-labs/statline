import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Share a CSV string as a file via the platform share sheet.
Future<void> shareCsvContent(String csvContent, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(csvContent);
  await Share.shareXFiles([XFile(file.path)]);
}

/// Share plain text via the platform share sheet.
Future<void> shareTextContent(String text, {String? subject}) async {
  await Share.share(text, subject: subject);
}
