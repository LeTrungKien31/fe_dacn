class Env {
  // Chỉ chứa base URL, KHÔNG có /api/v1
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://be-dacn-production.up.railway.app',
// http://10.0.2.2:8080
    // ✅ Chỉ host:port
  );
}
