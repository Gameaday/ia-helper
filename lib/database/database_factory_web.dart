// Web platform database factory
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

/// Web database factory using IndexedDB
DatabaseFactory? get webDatabaseFactory => databaseFactoryFfiWeb;
