class Env {
  // Chỉ chứa base URL, KHÔNG có /api/v1
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
    //defaultValue: 'https://be-dacn-production.up.railway.app',
    // ✅ Chỉ host:port
  );
}
