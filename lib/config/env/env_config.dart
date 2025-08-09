import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiUrl =>
      dotenv.env['API_URL'] ?? 'https://encrypted.nadiapoint.com';
  static String get jwtKey => dotenv.env['JWT_KEY'] ?? '';

  static String get authBaseUrl => '$apiUrl/auth';

  static String get appName => dotenv.env['APP_NAME'] ?? 'NadiaPoint';
}
