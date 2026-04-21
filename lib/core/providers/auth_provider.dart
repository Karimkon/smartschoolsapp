import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

// ── Demo accounts (offline mode) ──────────────────────────────────────────────
const _demoUsers = {
  'admin@school.com': {
    'id': 1, 'name': 'Alex Johnson', 'role': 'school_admin',
    'school_id': 1, 'school_name': 'Greenwood Academy',
  },
  'teacher@school.com': {
    'id': 2, 'name': 'Sarah Mitchell', 'role': 'teacher',
    'school_id': 1, 'school_name': 'Greenwood Academy',
  },
  'student@school.com': {
    'id': 3, 'name': 'James Okello', 'role': 'student',
    'school_id': 1, 'school_name': 'Greenwood Academy',
  },
  'parent@school.com': {
    'id': 4, 'name': 'Mary Nakato', 'role': 'parent',
    'school_id': 1, 'school_name': 'Greenwood Academy',
  },
  'accounts@school.com': {
    'id': 5, 'name': 'David Mugisha', 'role': 'accountant',
    'school_id': 1, 'school_name': 'Greenwood Academy',
  },
  'library@school.com': {
    'id': 6, 'name': 'Grace Apio', 'role': 'librarian',
    'school_id': 1, 'school_name': 'Greenwood Academy',
  },
  'super@smartschools.com': {
    'id': 7, 'name': 'Super Admin', 'role': 'super_admin',
    'school_id': null, 'school_name': null,
  },
};

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

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    // Demo token — restore demo user immediately
    if (token.startsWith('demo_')) {
      final email = prefs.getString('demo_email') ?? '';
      final demoData = _demoUsers[email];
      if (demoData != null) {
        final user = UserModel(
          id:         demoData['id'] as int,
          name:       demoData['name'] as String,
          email:      email,
          role:       demoData['role'] as String,
          schoolId:   demoData['school_id'] as int?,
          schoolName: demoData['school_name'] as String?,
          token:      token,
        );
        state = AuthState(user: user);
        return;
      }
    }

    // Real token — verify with server
    try {
      state = state.copyWith(loading: true);
      final res = await ApiService().get('/auth/me');
      final user = UserModel.fromJson(res.data['user'], token);
      state = AuthState(user: user);
    } catch (_) {
      await prefs.remove('auth_token');
      await prefs.remove('demo_email');
      state = const AuthState();
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);

    // ── Demo mode: instant offline login ──────────────────────────────────────
    final demoData = _demoUsers[email.toLowerCase().trim()];
    if (demoData != null && password == 'password') {
      await Future.delayed(const Duration(milliseconds: 600)); // feels real
      final token = 'demo_${DateTime.now().millisecondsSinceEpoch}';
      final user = UserModel(
        id:         demoData['id'] as int,
        name:       demoData['name'] as String,
        email:      email.toLowerCase().trim(),
        role:       demoData['role'] as String,
        schoolId:   demoData['school_id'] as int?,
        schoolName: demoData['school_name'] as String?,
        token:      token,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token',  token);
      await prefs.setString('demo_email',  email.toLowerCase().trim());
      state = AuthState(user: user);
      return true;
    }

    // ── Live API login ────────────────────────────────────────────────────────
    try {
      final res = await ApiService().post('/auth/login', data: {
        'email': email, 'password': password,
      });
      final token = res.data['token'] as String;
      final user  = UserModel.fromJson(res.data['user'], token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.remove('demo_email');

      state = AuthState(user: user);
      return true;
    } on Exception catch (e) {
      state = AuthState(error: _extractError(e));
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (!token.startsWith('demo_')) {
      try { await ApiService().post('/auth/logout'); } catch (_) {}
    }
    await prefs.remove('auth_token');
    await prefs.remove('demo_email');
    state = const AuthState();
  }

  String _extractError(Exception e) {
    final str = e.toString();
    if (str.contains('401') || str.contains('Unauthorised') || str.contains('credentials')) {
      return 'Invalid email or password';
    }
    if (str.contains('SocketException') || str.contains('connection') || str.contains('timeout')) {
      return 'Cannot reach server. Check your connection.';
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
