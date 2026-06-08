import '../data/local/app_database.dart';
import '../data/local/database_connection.dart';

class AppInitializer {
  static Future<AppDatabase> initialize() async {
    final executor = await DatabaseConnection.createConnection();
    return AppDatabase(executor);
  }
}
