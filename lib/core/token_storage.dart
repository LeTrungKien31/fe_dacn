import 'package:shared_preferences/shared_preferences.dart';
class TokenStorage {
  static const _key='auth_token';
  Future<void> save(String t) async { final sp=await SharedPreferences.getInstance(); await sp.setString(_key,t); }
  Future<String?> load() async { final sp=await SharedPreferences.getInstance(); return sp.getString(_key); }
  Future<void> clear() async { final sp=await SharedPreferences.getInstance(); await sp.remove(_key); }
}
