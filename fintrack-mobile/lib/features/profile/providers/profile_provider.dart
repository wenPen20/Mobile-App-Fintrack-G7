import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

// Provider to fetch the logged-in user's profile metadata
final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getProfile();
});

// Action provider to update the profile name and refresh the local cache
final updateProfileNameProvider = Provider((ref) {
  return (String name) async {
    final api = ref.read(apiServiceProvider);
    await api.updateProfileName(name);
    ref.invalidate(profileProvider);
  };
});

// Action provider to confirm the current password
final confirmPasswordProvider = Provider((ref) {
  return (String password) async {
    final api = ref.read(apiServiceProvider);
    await api.confirmPassword(password);
  };
});

// Action provider to set the new password
final updatePasswordProvider = Provider((ref) {
  return (String newPassword) async {
    final api = ref.read(apiServiceProvider);
    await api.updatePassword(newPassword);
  };
});
