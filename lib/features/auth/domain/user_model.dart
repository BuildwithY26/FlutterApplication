import 'package:firebase_auth/firebase_auth.dart';

class AppUserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;

  const AppUserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  factory AppUserModel.fromFirebase(User user) {
    return AppUserModel(
      id: user.uid,
      email: user.email ?? 'developer@antigravity.ai',
      displayName: user.displayName ?? (user.email?.split('@').first ?? 'Developer'),
      photoUrl: user.photoURL,
    );
  }

  static const AppUserModel mock = AppUserModel(
    id: 'dev_user_001',
    email: 'developer@antigravity.ai',
    displayName: 'Lead Architect',
    photoUrl: null,
  );
}
