import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';

class CurrentUserNotifier extends Notifier<AppUserModel> {
  @override
  AppUserModel build() {
    if (Firebase.apps.isNotEmpty) {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        return AppUserModel.fromFirebase(auth.currentUser!);
      }
      auth.authStateChanges().listen((user) {
        if (user != null) {
          state = AppUserModel.fromFirebase(user);
        }
      });
    }
    return AppUserModel.mock;
  }

  void setUser(AppUserModel user) => state = user;
}

final currentUserProvider =
    NotifierProvider<CurrentUserNotifier, AppUserModel>(CurrentUserNotifier.new);

class ThemeModeNotifier extends Notifier<String> {
  @override
  String build() => 'dark';

  void toggle() => state = state == 'dark' ? 'light' : 'dark';
  void setMode(String mode) => state = mode;
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, String>(ThemeModeNotifier.new);
