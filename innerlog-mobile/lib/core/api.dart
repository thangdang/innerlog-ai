import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:3000/api/v1';
  late final Dio _dio;
  late final Dio _refreshDio; // Separate Dio for refresh (no interceptors)

  ApiClient() {
    _refreshDio = Dio(BaseOptions(baseUrl: baseUrl));

    _dio = Dio(BaseOptions(baseUrl: baseUrl));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try token refresh
          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refreshToken');
          if (refreshToken != null) {
            try {
              final res = await _refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
              );
              final newToken = res.data['token'] as String;
              final newRefresh = res.data['refreshToken'] as String;
              await prefs.setString('token', newToken);
              await prefs.setString('refreshToken', newRefresh);

              // Retry original request with new token
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final retryRes = await _dio.fetch(error.requestOptions);
              handler.resolve(retryRes);
              return;
            } catch (_) {
              // Refresh failed — clear tokens
              await prefs.remove('token');
              await prefs.remove('refreshToken');
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  // ── Auth ──────────────────────────────────────────────────────
  Future<Response> login(String email, String password) =>
      _dio.post('/auth/login', data: {'email': email, 'password': password});

  Future<Response> register(String email, String password, String name) =>
      _dio.post('/auth/register', data: {'email': email, 'password': password, 'display_name': name});

  Future<Response> getMe() => _dio.get('/auth/me');

  // ── Check-ins ────────────────────────────────────────────────
  Future<Response> createCheckin(int mood, String energy, String? note, {List<String>? tags}) =>
      _dio.post('/checkins', data: {'mood_score': mood, 'energy_level': energy, 'text_note': note, 'tags': tags});

  Future<Response> getCheckins({String? from, String? to}) =>
      _dio.get('/checkins', queryParameters: {'from': from, 'to': to});

  Future<Response> getStreak() => _dio.get('/checkins/streak');

  Future<Response> getCheckinStats({int days = 30}) =>
      _dio.get('/checkins/stats', queryParameters: {'days': days});

  Future<Response> getHeatmap({int? year}) =>
      _dio.get('/checkins/heatmap', queryParameters: {'year': year});

  // ── Insights ─────────────────────────────────────────────────
  Future<Response> getLatestInsight() => _dio.get('/insights/latest');
  Future<Response> getInsightHistory() => _dio.get('/insights/history');
  Future<Response> generateInsight({String period = '7d'}) =>
      _dio.post('/insights/generate', data: {'period': period});

  // ── Goals ────────────────────────────────────────────────────
  Future<Response> getGoals({String? status}) =>
      _dio.get('/goals', queryParameters: status != null ? {'status': status} : null);

  Future<Response> createGoal(String title, String category) =>
      _dio.post('/goals', data: {'title': title, 'category': category});

  Future<Response> toggleTask(String goalId, int taskIndex) =>
      _dio.put('/goals/$goalId/tasks/$taskIndex/toggle');

  Future<Response> addTask(String goalId, String title) =>
      _dio.post('/goals/$goalId/tasks', data: {'title': title});

  // ── Coach ────────────────────────────────────────────────────
  Future<Response> checkCoach() => _dio.post('/coach/check');

  // ── Notifications ────────────────────────────────────────────
  Future<Response> getNotifications({bool unreadOnly = false}) =>
      _dio.get('/notifications', queryParameters: {'unread': unreadOnly ? 'true' : null});

  Future<Response> markRead(String id) => _dio.put('/notifications/$id/read');
  Future<Response> markAllRead() => _dio.put('/notifications/read-all');

  // ── Profile ──────────────────────────────────────────────────
  Future<Response> updateProfile(Map<String, dynamic> data) =>
      _dio.put('/auth/profile', data: data);

  Future<Response> changePassword(String current, String newPass) =>
      _dio.post('/auth/change-password', data: {'current_password': current, 'new_password': newPass});

  Future<Response> exportData() => _dio.get('/auth/export');
  Future<Response> deleteAccount() => _dio.delete('/auth/delete-account');
}
