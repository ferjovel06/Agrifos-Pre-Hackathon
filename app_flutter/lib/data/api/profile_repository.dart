import '../../domain/entities/user_profile.dart';
import 'api_client.dart';

class ProfileRepository {
  ProfileRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<UserProfile> getProfile() async {
    final response = await _client.get('/users/me') as Map<String, dynamic>;
    return UserProfile.fromJson(response);
  }

  Future<UserProfile> updateProfile(UserProfileUpdate update) async {
    final response = await _client.patch('/users/me', update.toJson());
    return UserProfile.fromJson(response);
  }
}
