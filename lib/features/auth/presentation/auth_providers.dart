import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';

class CurrentUserNotifier extends Notifier<AppUserModel> {
  @override
  AppUserModel build() => AppUserModel.mock;

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
