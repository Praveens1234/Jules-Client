import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jules_client/models/jules_models.dart';
import 'package:jules_client/services/storage_service.dart';

final apiServiceProvider = Provider((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiService(storage);
});

class ApiService {
  final StorageService _storage;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://jules.googleapis.com/v1alpha',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  ApiService(this._storage) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print("DIO LOG: $obj"),
    ));
  }

  Future<Map<String, dynamic>> _getHeaders() async {
    final apiKey = await _storage.getApiKey();
    if (apiKey == null) throw Exception("API Key not found");
    return {
      'X-Goog-Api-Key': apiKey,
      'Content-Type': 'application/json',
    };
  }

  // --- Sources ---
  Future<List<Source>> listSources() async {
    final headers = await _getHeaders();
    final response = await _dio.get('/sources', options: Options(headers: headers));
    
    final List<dynamic> sourcesJson = response.data['sources'] ?? [];
    return sourcesJson.map((e) => Source.fromJson(e)).toList();
  }

  // --- Sessions ---
  Future<List<Session>> listSessions() async {
    final headers = await _getHeaders();
    final response = await _dio.get('/sessions?pageSize=20', options: Options(headers: headers));
    
    final List<dynamic> sessionsJson = response.data['sessions'] ?? [];
    return sessionsJson.map((e) => Session.fromJson(e)).toList();
  }

  Future<Session> createSession({
    required String prompt,
    required String sourceName,
    String? title,
  }) async {
    final headers = await _getHeaders();
    final data = {
      "prompt": prompt,
      "sourceContext": {
        "source": sourceName,
        "githubRepoContext": {
          "startingBranch": "main" 
        }
      },
      if (title != null) "title": title,
    };

    final response = await _dio.post(
      '/sessions', 
      data: data, 
      options: Options(headers: headers)
    );
    return Session.fromJson(response.data);
  }

  // --- Activities ---
  Future<List<Activity>> listActivities(String sessionId) async {
    final headers = await _getHeaders();
    
    // Ensure sessionId doesn't start with slash if we append it to empty string
    // But since baseUrl doesn't have trailing slash, and we start string with /, it replaces path?
    // Dio BaseURL: https://host/path
    // Request: /subpath -> https://host/subpath (Replaces /path)
    // Request: subpath -> https://host/path/subpath (Appends)
    
    // The BaseURL is 'https://jules.googleapis.com/v1alpha'.
    // If we send '/$sessionId...', it might resolve to 'https://jules.googleapis.com/sessions/...' removing v1alpha.
    // So we MUST NOT use leading slash if we want to append to v1alpha.
    
    // Also sessionId usually comes as "sessions/12345".
    // So "sessions/12345/activities" is the correct relative path.
    
    final path = '$sessionId/activities?pageSize=50';
    
    final response = await _dio.get(
      path,
      options: Options(headers: headers),
    );

    final List<dynamic> activitiesJson = response.data['activities'] ?? [];
    return activitiesJson.map((e) => Activity.fromJson(e)).toList();
  }

  Future<void> sendMessage(String sessionId, String message) async {
    final headers = await _getHeaders();
    final data = {"prompt": message};
    
    final path = '$sessionId:sendMessage';
    
    await _dio.post(
      path,
      data: data,
      options: Options(headers: headers),
    );
  }
}
