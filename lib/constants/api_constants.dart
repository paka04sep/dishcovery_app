import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get googlePlacesApiKey => dotenv.env['MAPS_API_KEY'] ?? '';
}
