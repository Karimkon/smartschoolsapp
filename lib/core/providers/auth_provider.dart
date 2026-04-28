import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool loading;
  final String? error;

  const AuthState({this.user, this.loading = false, this.error});

  bool get isLoggedIn => user != null;

  AuthState copyWith({UserModel? user, bool? loading, String? error}) {
    return AuthState(
      user:    user    ?? this.user,
      loading: loading ?? this.loading,
      error:   error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  // ── Persist user profile locally so the app starts instantly ──────────────
  static Future<void> _save(UserModel u) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('auth_token',       u.token);
    await p.setString('user_id',          u.id.toString());
    await p.setString('user_name',        u.name);
    await p.setString('user_email',       u.email);
    await p.setString('user_role',        u.role);
    if (u.schoolId   != null) await p.setInt   ('user_school_id',   u.schoolId!);
    if (u.schoolName != null) await p.setString('user_school_name', u.schoolName!);
  }

  static Future<void> _clear() async {
    final p = await SharedPreferences.getInstance();
    for (final k in [
      'auth_token', 'user_id', 'user_name', 'user_email',
      'user_role', 'user_school_id', 'user_school_name',
    ]) {
      await p.remove(k);
    }
  }

  // ── On app start: restore from local prefs, verify in background ──────────
  Future<void> tryAutoLogin() async {
    final p     = await SharedPreferences.getInstance();
    final token = p.getString('auth_token');
    if (token == null) return;

    final id    = int.tryParse(p.getString('user_id') ?? '');
    final name  = p.getString('user_name');
    final email = p.getString('user_email');
    final role  = p.getString('user_role');

    if (id == null || name == null || email == null || role == null) {
      // Corrupted prefs — force re-login
      await _clear();
      return;
    }

    // Restore instantly — no network wait
    final user = UserModel(
      id:         id,
      name:       name,
      email:      email,
      role:       role,
      schoolId:   p.getInt('user_school_id'),
      schoolName: p.getString('user_school_name'),
      token:      token,
    );
    state = AuthState(user: user);

    // Verify token with server in background
    _verifyTokenInBackground(token);
  }

  void _verifyTokenInBackground(String token) {
    ApiService().get('/auth/me').then((res) {
      // Refresh local profile with latest server data
      final fresh = UserModel.fromJson(res.data['user'], token);
      _save(fresh);
      state = AuthState(user: fresh);
    }).catchError((e) {
      final msg = e.toString();
      // Only force logout on explicit auth rejection
      if (msg.contains('401') || msg.contains('403') || msg.contains('Unauthenticated')) {
        _clear();
        state = const AuthState();
      }
      // Ignore network errors — keep the user logged in
    });
  }

  void clearError() {
    if (state.error != null) state = AuthState(user: state.user);
  }

  // ── Login with live API ───────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    state = const AuthState(loading: true);
    try {
      final res = await ApiService().post('/auth/login', data: {
        'email':    email.trim(),
        'password': password,
      });

      final token = res.data['token'] as String;
      final user  = UserModel.fromJson(res.data['user'], token);

      await _save(user);
      state = AuthState(user: user);
      return true;
    } on Exception catch (e) {
      state = AuthState(error: _extractError(e));
      return false;
    }
  }

  Future<void> logout() async {
    try { await ApiService().post('/auth/logout'); } catch (_) {}
    await _clear();
    state = const AuthState();
  }

  String _extractError(Exception e) {
    final s = e.toString();
    if (s.contains('401') || s.contains('422') ||
        s.contains('nvalid') || s.contains('redentials') ||
        s.contains('nauthori')) {
      return 'Invalid email or password.';
    }
    if (s.contains('SocketException') || s.contains('connection') ||
        s.contains('timeout') || s.contains('Network')) {
      return 'No internet connection. Please try again.';
    }
    return 'Login failed. Please try again.';
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
