// providers/database_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_app/services/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});