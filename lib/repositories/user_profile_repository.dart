// lib/repositories/user_profile_repository.dart
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileRepository {
  Future<Map<String, String>> loadUserInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'userName': prefs.getString('userName') ?? 'Nome não disponível',
      'userEmail': prefs.getString('userEmail') ?? 'Email não disponível',
      'profileImageUrl': prefs.getString('profileImageUrl') ?? '',
    };
  }

  Future<void> saveUserInfo(String name, String email, String imageUrl) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('profileImageUrl', imageUrl);
  }
}
