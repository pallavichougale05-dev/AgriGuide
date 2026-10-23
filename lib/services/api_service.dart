import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;


// ============================================================
// AGRIGUIDE API SERVICE

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static const FlutterSecureStorage _secureStorage =
      FlutterSecureStorage();

  static const String _tokenKey = 'agriguide_access_token';

  static const String _userIdKey = 'agriguide_user_id';
  static const String _userNameKey = 'agriguide_user_name';
  static const String _userEmailKey = 'agriguide_user_email';

  // ==========================================================
  // AUTHENTICATION

  static Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final Uri url = Uri.parse(
      '$baseUrl/auth/register',
    );

    final http.Response response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    ).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final AuthResponseModel authResponse =
          AuthResponseModel.fromJson(data);

      await _saveSession(authResponse);

      return authResponse;
    }

    throw Exception(
      _getApiErrorMessage(
        response,
        fallback: 'Registration failed.',
      ),
    );
  }

  static Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final Uri url = Uri.parse(
      '$baseUrl/auth/login',
    );

    final http.Response response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    ).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final AuthResponseModel authResponse =
          AuthResponseModel.fromJson(data);

      await _saveSession(authResponse);

      return authResponse;
    }

    throw Exception(
      _getApiErrorMessage(
        response,
        fallback: 'Login failed.',
      ),
    );
  }

  static Future<UserModel?> getCurrentUser() async {
    final String? token = await getAccessToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    final Uri url = Uri.parse(
      '$baseUrl/auth/me',
    );

    final http.Response response = await http.get(
      url,
      headers: _authorizedHeaders(),
    ).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final UserModel user =
          UserModel.fromJson(data);

      await _saveUser(user);

      return user;
    }

    if (response.statusCode == 401) {
      await logout();
      return null;
    }

    throw Exception(
      _getApiErrorMessage(
        response,
        fallback: 'Unable to load your account.',
      ),
    );
  }

  static Future<String?> getAccessToken() async {
    return _secureStorage.read(
      key: _tokenKey,
    );
  }

  static Future<UserModel?> getSavedUser() async {
    final String? idText =
        await _secureStorage.read(
      key: _userIdKey,
    );

    final String? name =
        await _secureStorage.read(
      key: _userNameKey,
    );

    final String? email =
        await _secureStorage.read(
      key: _userEmailKey,
    );

    if (idText == null ||
        name == null ||
        email == null) {
      return null;
    }

    final int? id = int.tryParse(idText);

    if (id == null) {
      return null;
    }

    return UserModel(
      id: id,
      fullName: name,
      email: email,
    );
  }

  static Future<bool> hasValidSession() async {
    final String? token = await getAccessToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final UserModel? user =
          await getCurrentUser();

      return user != null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> logout() async {
    await _secureStorage.delete(
      key: _tokenKey,
    );

    await _secureStorage.delete(
      key: _userIdKey,
    );

    await _secureStorage.delete(
      key: _userNameKey,
    );

    await _secureStorage.delete(
      key: _userEmailKey,
    );
  }

  static Future<void> _saveSession(
    AuthResponseModel authResponse,
  ) async {
    await _secureStorage.write(
      key: _tokenKey,
      value: authResponse.accessToken,
    );

    await _saveUser(
      authResponse.user,
    );
  }

  static Future<void> _saveUser(
    UserModel user,
  ) async {
    await _secureStorage.write(
      key: _userIdKey,
      value: user.id.toString(),
    );

    await _secureStorage.write(
      key: _userNameKey,
      value: user.fullName,
    );

    await _secureStorage.write(
      key: _userEmailKey,
      value: user.email,
    );
  }

  static Map<String, String> _authorizedHeaders() {
    return {
      'Accept': 'application/json',
    };
  }

  static Future<Map<String, String>>
      _getAuthorizedHeaders() async {
    final String? token =
        await getAccessToken();

    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ==========================================================
  // TEST API
  // ==========================================================

  Future<String> testApi() async {
    final http.Response response =
        await http.get(
      Uri.parse('$baseUrl/test'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      return data['message'] as String;
    }

    throw Exception(
      'Test API failed. HTTP ${response.statusCode}',
    );
  }

  // ==========================================================
  // CROP RECOMMENDATION
  // ==========================================================

  static Future<List<CropRecommendation>>
      recommendCrops({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperature,
    required double humidity,
    required double ph,
    required double rainfall,
  }) async {
    final Uri url = Uri.parse(
      '$baseUrl/crop/recommend',
    );

    final http.Response response =
        await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'temperature': temperature,
        'humidity': humidity,
        'ph': ph,
        'rainfall': rainfall,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final List<dynamic> rawRecommendations =
          data['recommendations']
              as List<dynamic>;

      return rawRecommendations
          .map(
            (item) =>
                CropRecommendation.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      'Crop API failed. '
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  // ==========================================================
  // DISEASE DETECTION
  // ==========================================================

  static Future<DiseaseDetectionResponse>
      detectDisease(
    File imageFile,
  ) async {
    final Uri url = Uri.parse(
      '$baseUrl/disease/detect',
    );

    final http.MultipartRequest request =
        http.MultipartRequest(
      'POST',
      url,
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ),
    );

    try {
      final http.StreamedResponse
          streamedResponse =
          await request.send().timeout(
        const Duration(seconds: 30),
      );

      final http.Response response =
          await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body)
                as Map<String, dynamic>;

        return DiseaseDetectionResponse
            .fromJson(data);
      }

      throw Exception(
        'Disease API failed. '
        'HTTP ${response.statusCode}: ${response.body}',
      );
    } on Exception {
      rethrow;
    } catch (error) {
      if (kDebugMode) {
        print(
          'Disease API error: $error',
        );
      }

      throw Exception(
        'Unable to connect to the disease detection API.',
      );
    }
  }

  // ==========================================================
  // WEATHER
  // ==========================================================

  static Future<WeatherData> getWeather({
    double latitude = 16.70,
    double longitude = 74.24,
  }) async {
    final Uri url = Uri.parse(
      '$baseUrl/weather/current',
    ).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );

    final http.Response response =
        await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      return WeatherData.fromJson(data);
    }

    throw Exception(
      'Weather API failed. '
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  // ==========================================================
  // LOCATION SEARCH
  // ==========================================================

  static Future<List<LocationSearchResult>>
      searchLocations(
    String query,
  ) async {
    final Uri url = Uri.parse(
      '$baseUrl/weather/search',
    ).replace(
      queryParameters: {
        'query': query,
      },
    );

    final http.Response response =
        await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final List<dynamic> results =
          data['results'] as List<dynamic>;

      return results
          .map(
            (item) =>
                LocationSearchResult.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      'Location search failed. '
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  // ==========================================================
  // CHATBOT
  // ==========================================================

  static Future<String> sendChatMessage(
    String message,
  ) async {
    final String cleanMessage =
        message.trim();

    if (cleanMessage.isEmpty) {
      throw Exception(
        'Message cannot be empty.',
      );
    }

    final Uri url = Uri.parse(
      '$baseUrl/chat/message',
    );

    try {
      final http.Response response =
          await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'message': cleanMessage,
        }),
      ).timeout(
        const Duration(seconds: 65),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body)
                as Map<String, dynamic>;

        final String? answer =
            data['response'] as String?;

        if (answer == null ||
            answer.trim().isEmpty) {
          throw Exception(
            'Assistant returned an empty response.',
          );
        }

        return answer.trim();
      }

      String errorMessage =
          'Chatbot API failed. '
          'HTTP ${response.statusCode}';

      try {
        final Map<String, dynamic>
            errorData =
            jsonDecode(response.body)
                as Map<String, dynamic>;

        if (errorData['detail'] != null) {
          errorMessage =
              errorData['detail'].toString();
        }
      } catch (_) {}

      throw Exception(errorMessage);
    } on Exception {
      rethrow;
    } catch (error) {
      if (kDebugMode) {
        print(
          'Chatbot API error: $error',
        );
      }

      throw Exception(
        'Unable to connect to the chatbot.',
      );
    }
  }

  // ==========================================================
  // KNOWLEDGE HUB
  // ==========================================================

  static Future<List<KnowledgeArticle>>
      getKnowledgeArticles() async {
    final Uri url = Uri.parse(
      '$baseUrl/knowledge/articles',
    );

    try {
      final http.Response response =
          await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body)
                as Map<String, dynamic>;

        final List<dynamic> rawArticles =
            data['articles']
                as List<dynamic>;

        return rawArticles
            .map(
              (item) =>
                  KnowledgeArticle.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }

      throw Exception(
        'Knowledge Hub API failed. '
        'HTTP ${response.statusCode}: ${response.body}',
      );
    } on Exception {
      rethrow;
    } catch (error) {
      if (kDebugMode) {
        print(
          'Knowledge Hub API error: $error',
        );
      }

      throw Exception(
        'Unable to connect to the Knowledge Hub.',
      );
    }
  }

  // ==========================================================
  // FARM DIARY
  // ==========================================================

  static Future<List<DiaryEntryModel>>
      getDiaryEntries() async {
    final Uri url = Uri.parse(
      '$baseUrl/diary',
    );

    final http.Response response =
        await http.get(
      url,
      headers: await _getAuthorizedHeaders(),
    ).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data =
          jsonDecode(response.body)
              as List<dynamic>;

      return data
          .map(
            (item) =>
                DiaryEntryModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      'Farm Diary API failed. '
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }

    // ==========================================================
  // CREATE DIARY ENTRY
  // ==========================================================
  //
  // Creates a diary record for the currently logged-in user.
  //
  // IMPORTANT:
  // user_id is NOT sent from Flutter.
  //
  // The JWT is sent in the Authorization header.
  // FastAPI reads the JWT and determines the current user.
  //
  // Flow:
  //
  // Flutter
  //    ↓
  // JWT in Authorization header
  //    ↓
  // FastAPI /diary
  //    ↓
  // get_current_user()
  //    ↓
  // user_id = current_user.id
  //    ↓
  // PostgreSQL
  //
  // ==========================================================

  static Future<DiaryEntryModel> createDiaryEntry({
    required DateTime date,
    required String cropField,
    required String activity,
    required String notes,
  }) async {
    // --------------------------------------------------------
    // GET SAVED JWT
    // --------------------------------------------------------

    final String? token =
        await getAccessToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Authentication required. Please log in again.',
      );
    }

    // --------------------------------------------------------
    // DIARY API URL
    // --------------------------------------------------------

    final Uri url =
        Uri.parse('$baseUrl/diary');

    // --------------------------------------------------------
    // SEND AUTHENTICATED REQUEST
    // --------------------------------------------------------

    final http.Response response =
        await http.post(
      url,

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',

        // This is the important part.
        'Authorization': 'Bearer $token',
      },

      body: jsonEncode({
        'date': date.toIso8601String(),
        'crop_field': cropField,
        'activity': activity,
        'notes': notes,
      }),
    ).timeout(
      const Duration(seconds: 15),
    );

    // --------------------------------------------------------
    // SUCCESS
    // --------------------------------------------------------

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      return DiaryEntryModel.fromJson(
        data,
      );
    }

    // --------------------------------------------------------
    // AUTHENTICATION ERROR
    // --------------------------------------------------------

    if (response.statusCode == 401) {
      throw Exception(
        'Your session has expired. Please log in again.',
      );
    }

    // --------------------------------------------------------
    // OTHER ERROR
    // --------------------------------------------------------

    String errorMessage =
        'Farm Diary create failed. '
        'HTTP ${response.statusCode}';

    try {
      final Map<String, dynamic> errorData =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      if (errorData['detail'] != null) {
        errorMessage =
            errorData['detail'].toString();
      }
    } catch (_) {
      // Keep the default error message.
    }

    throw Exception(errorMessage);
  }

  // ==========================================================
// DELETE DIARY ENTRY
// ==========================================================
//
// Deletes one diary record belonging to the authenticated user.
//
// The entry ID comes from the PostgreSQL record.
// The JWT identifies the current user.
//
// Backend:
// DELETE /diary/{entry_id}
// ==========================================================

static Future<void> deleteDiaryEntry(
  int entryId,
) async {
  final String? token = await getAccessToken();

  if (token == null || token.trim().isEmpty) {
    throw Exception(
      'Authentication required. Please log in again.',
    );
  }

  final Uri url = Uri.parse(
    '$baseUrl/diary/$entryId',
  );

  final http.Response response = await http.delete(
    url,
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  ).timeout(
    const Duration(seconds: 15),
  );

  // FastAPI diary DELETE currently returns 200.
  if (response.statusCode == 200 ||
      response.statusCode == 204) {
    return;
  }

  if (response.statusCode == 401) {
    throw Exception(
      'Your session has expired. Please log in again.',
    );
  }

  String errorMessage =
      'Unable to delete diary entry. '
      'HTTP ${response.statusCode}';

  try {
    final Map<String, dynamic> errorData =
        jsonDecode(response.body)
            as Map<String, dynamic>;

    if (errorData['detail'] != null) {
      errorMessage =
          errorData['detail'].toString();
    }
  } catch (_) {
    // Keep the default error message.
  }

  throw Exception(errorMessage);
}

  // ==========================================================
  // COMMON API ERROR
  // ==========================================================

  static String _getApiErrorMessage(
    http.Response response, {
    required String fallback,
  }) {
    try {
      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final dynamic detail =
            decoded['detail'];

        if (detail != null &&
            detail.toString().trim().isNotEmpty) {
          return detail.toString();
        }

        final dynamic message =
            decoded['message'];

        if (message != null &&
            message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {}

    return '$fallback HTTP ${response.statusCode}';
  }
}


// ============================================================
// AUTH USER MODEL
// ============================================================

class UserModel {
  final int id;
  final String fullName;
  final String email;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserModel(
      id: (json['id'] as num).toInt(),
      fullName:
          json['full_name'] as String? ?? '',
      email:
          json['email'] as String? ?? '',
    );
  }
}


// ============================================================
// AUTH RESPONSE MODEL
// ============================================================

class AuthResponseModel {
  final bool success;
  final String message;
  final String accessToken;
  final String tokenType;
  final UserModel user;

  const AuthResponseModel({
    required this.success,
    required this.message,
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AuthResponseModel(
      success:
          json['success'] as bool? ?? false,
      message:
          json['message'] as String? ?? '',
      accessToken:
          json['access_token'] as String? ?? '',
      tokenType:
          json['token_type'] as String? ?? 'bearer',
      user: UserModel.fromJson(
        json['user']
            as Map<String, dynamic>,
      ),
    );
  }
}


// ============================================================
// KNOWLEDGE ARTICLE
// ============================================================

class KnowledgeArticle {
  final int id;
  final String title;
  final String category;
  final String summary;
  final String content;

  const KnowledgeArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.content,
  });

  factory KnowledgeArticle.fromJson(
    Map<String, dynamic> json,
  ) {
    return KnowledgeArticle(
      id: (json['id'] as num).toInt(),
      title:
          json['title'] as String? ?? '',
      category:
          json['category'] as String? ?? '',
      summary:
          json['summary'] as String? ?? '',
      content:
          json['content'] as String? ?? '',
    );
  }
}


// ============================================================
// CROP RECOMMENDATION
// ============================================================

class CropRecommendation {
  final String crop;
  final String variety;
  final double score;

  const CropRecommendation({
    required this.crop,
    required this.variety,
    required this.score,
  });

  factory CropRecommendation.fromJson(
    Map<String, dynamic> json,
  ) {
    return CropRecommendation(
      crop:
          json['crop'] as String,
      variety:
          json['variety'] as String,
      score:
          (json['score'] as num).toDouble(),
    );
  }
}


// ============================================================
// CURRENT WEATHER
// ============================================================

class CurrentWeather {
  final double temperature;
  final double humidity;
  final double rainfall;
  final double windSpeed;
  final int weatherCode;

  const CurrentWeather({
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.windSpeed,
    required this.weatherCode,
  });

  factory CurrentWeather.fromJson(
    Map<String, dynamic> json,
  ) {
    return CurrentWeather(
      temperature:
          (json['temperature'] as num)
              .toDouble(),
      humidity:
          (json['humidity'] as num)
              .toDouble(),
      rainfall:
          (json['rainfall'] as num)
              .toDouble(),
      windSpeed:
          (json['wind_speed'] as num)
              .toDouble(),
      weatherCode:
          (json['weather_code'] as num)
              .toInt(),
    );
  }

  String get condition {
    return weatherCodeToText(
      weatherCode,
    );
  }

  static String weatherCodeToText(
    int code,
  ) {
    if (code == 0) {
      return 'Clear Sky';
    }

    if (code == 1) {
      return 'Mainly Clear';
    }

    if (code == 2) {
      return 'Partly Cloudy';
    }

    if (code == 3) {
      return 'Overcast';
    }

    if (code == 45 || code == 48) {
      return 'Foggy';
    }

    if (code == 51) {
      return 'Light Drizzle';
    }

    if (code == 53) {
      return 'Moderate Drizzle';
    }

    if (code == 55) {
      return 'Dense Drizzle';
    }

    if (code == 61) {
      return 'Light Rain';
    }

    if (code == 63) {
      return 'Moderate Rain';
    }

    if (code == 65) {
      return 'Heavy Rain';
    }

    if (code == 66) {
      return 'Light Freezing Rain';
    }

    if (code == 67) {
      return 'Heavy Freezing Rain';
    }

    if (code == 71) {
      return 'Light Snow';
    }

    if (code == 73) {
      return 'Moderate Snow';
    }

    if (code == 75) {
      return 'Heavy Snow';
    }

    if (code == 77) {
      return 'Snow Grains';
    }

    if (code == 80) {
      return 'Rain Showers';
    }

    if (code == 81) {
      return 'Moderate Rain Showers';
    }

    if (code == 82) {
      return 'Heavy Rain Showers';
    }

    if (code == 95) {
      return 'Thunderstorm';
    }

    if (code == 96 ||
        code == 99) {
      return 'Thunderstorm with Hail';
    }

    return 'Unknown Weather';
  }
}


// ============================================================
// WEATHER FORECAST
// ============================================================

class WeatherForecast {
  final String date;
  final double maxTemperature;
  final double minTemperature;
  final double rainProbability;
  final int weatherCode;

  const WeatherForecast({
    required this.date,
    required this.maxTemperature,
    required this.minTemperature,
    required this.rainProbability,
    required this.weatherCode,
  });

  factory WeatherForecast.fromJson(
    Map<String, dynamic> json,
  ) {
    return WeatherForecast(
      date:
          json['date'] as String,
      maxTemperature:
          (json['max_temperature'] as num)
              .toDouble(),
      minTemperature:
          (json['min_temperature'] as num)
              .toDouble(),
      rainProbability:
          (json['rain_probability'] as num)
              .toDouble(),
      weatherCode:
          (json['weather_code'] as num)
              .toInt(),
    );
  }

  String get condition {
    return CurrentWeather
        .weatherCodeToText(
      weatherCode,
    );
  }
}


// ============================================================
// WEATHER DATA
// ============================================================

class WeatherData {
  final double latitude;
  final double longitude;
  final CurrentWeather current;
  final List<WeatherForecast> forecast;

  const WeatherData({
    required this.latitude,
    required this.longitude,
    required this.current,
    required this.forecast,
  });

  factory WeatherData.fromJson(
    Map<String, dynamic> json,
  ) {
    final Map<String, dynamic> location =
        json['location']
            as Map<String, dynamic>;

    final Map<String, dynamic> current =
        json['current']
            as Map<String, dynamic>;

    final Map<String, dynamic> forecast =
        json['forecast']
            as Map<String, dynamic>;

    final List<dynamic> dates =
        forecast['dates']
            as List<dynamic>;

    final List<dynamic> weatherCodes =
        forecast['weather_codes']
            as List<dynamic>;

    final List<dynamic> maxTemperatures =
        forecast['max_temperature']
            as List<dynamic>;

    final List<dynamic> minTemperatures =
        forecast['min_temperature']
            as List<dynamic>;

    final List<dynamic> rainProbabilities =
        forecast['rain_probability']
            as List<dynamic>;

    final List<WeatherForecast>
        forecastList =
        List.generate(
      dates.length,
      (index) {
        return WeatherForecast(
          date:
              dates[index] as String,
          maxTemperature:
              (maxTemperatures[index]
                      as num)
                  .toDouble(),
          minTemperature:
              (minTemperatures[index]
                      as num)
                  .toDouble(),
          rainProbability:
              (rainProbabilities[index]
                      as num)
                  .toDouble(),
          weatherCode:
              (weatherCodes[index] as num)
                  .toInt(),
        );
      },
    );

    return WeatherData(
      latitude:
          (location['latitude'] as num)
              .toDouble(),
      longitude:
          (location['longitude'] as num)
              .toDouble(),
      current:
          CurrentWeather.fromJson(
        current,
      ),
      forecast:
          forecastList,
    );
  }
}


// ============================================================
// LOCATION SEARCH RESULT
// ============================================================

class LocationSearchResult {
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String admin1;
  final String admin2;

  const LocationSearchResult({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.admin1,
    required this.admin2,
  });

  factory LocationSearchResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return LocationSearchResult(
      name:
          json['name'] as String,
      latitude:
          (json['latitude'] as num)
              .toDouble(),
      longitude:
          (json['longitude'] as num)
              .toDouble(),
      country:
          json['country'] as String? ?? '',
      admin1:
          json['admin1'] as String? ?? '',
      admin2:
          json['admin2'] as String? ?? '',
    );
  }

  String get secondaryName {
    final parts = [
      admin2,
      admin1,
      country,
    ].where(
      (value) => value.isNotEmpty,
    ).toList();

    return parts.join(', ');
  }

  String get displayName {
    final secondary =
        secondaryName;

    return secondary.isEmpty
        ? name
        : '$name, $secondary';
  }

  static String getApiErrorMessage(
    http.Response response,
  ) {
    try {
      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      if (data['detail'] != null) {
        return data['detail'].toString();
      }
    } catch (_) {}

    return 'Request failed. '
        'HTTP ${response.statusCode}';
  }
}


// ============================================================
// DISEASE DETECTION RESPONSE
// ============================================================

class DiseaseDetectionResponse {
  final bool success;
  final bool modelReady;
  final String message;
  final String filename;
  final String contentType;
  final int imageSize;

  const DiseaseDetectionResponse({
    required this.success,
    required this.modelReady,
    required this.message,
    required this.filename,
    required this.contentType,
    required this.imageSize,
  });

  factory DiseaseDetectionResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return DiseaseDetectionResponse(
      success:
          json['success'] as bool? ?? false,
      modelReady:
          json['model_ready'] as bool? ?? false,
      message:
          json['message'] as String? ?? '',
      filename:
          json['filename'] as String? ?? '',
      contentType:
          json['content_type'] as String? ?? '',
      imageSize:
          (json['image_size'] as num?)
                  ?.toInt() ??
              0,
    );
  }
}


// ============================================================
// FARM DIARY ENTRY
// ============================================================

class DiaryEntryModel {
  final int id;
  final DateTime date;
  final String cropField;
  final String activity;
  final String notes;

  const DiaryEntryModel({
    required this.id,
    required this.date,
    required this.cropField,
    required this.activity,
    required this.notes,
  });

  factory DiaryEntryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DiaryEntryModel(
      id:
          (json['id'] as num).toInt(),
      date:
          DateTime.parse(
        json['date'] as String,
      ),
      cropField:
          json['crop_field'] as String? ?? '',
      activity:
          json['activity'] as String? ?? '',
      notes:
          json['notes'] as String? ?? '',
    );
  }
}