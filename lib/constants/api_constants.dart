import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get googlePlacesApiKey =>
      dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
}
