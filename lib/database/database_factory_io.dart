// Native platform database factory (iOS, Android, Desktop)
import 'package:sqflite/sqflite.dart';

/// Native database factory - no special initialization needed
DatabaseFactory? get webDatabaseFactory => null;
