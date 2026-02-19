import 'package:drift/drift.dart';
// ignore: deprecated_member_use
import 'package:drift/web.dart';

QueryExecutor openConnection() {
  return WebDatabase('statline_db');
}
