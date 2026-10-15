import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';

// ─── Repository Providers ──────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ─── Registration & Login Results ─────────────────────────────
class RegisterResult {
  final bool success;
  final bool isPending;
  final String? message;
  final String? error;

  const RegisterResult({
    required this.success,
    this.isPending = false,
    this.message,
    this.error,
  });
}

class LoginResult {
  final bool success;
  final bool isPending;
  final bool isRejected;
  final String? rejectionReason;
  final String? message;
  final String? error;

  const LoginResult({
    required this.success,
    this.isPending = false,
    this.isRejected = false,
    this.rejectionReason,
    this.message,
    this.error,
  });
}

// ─── Auth State ────────────────────────────────────────────────
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Auth Notifier ─────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final hasToken = await _repo.hasToken();
    if (hasToken) {
      try {
        final user = await _repo.getMe();
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } catch (_) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> loginAnonymous() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.loginAnonymous();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: data['user'] as Map<String, dynamic>,
        isLoading: false,
      );
    } catch (e) {
      String message = e.toString();
      if (e is DioException && e.response?.data != null) {
        final resp = e.response!.data;
        if (resp is Map && resp['message'] != null) {
          message = resp['message'].toString();
        }
      }
      state = state.copyWith(error: message, isLoading: false);
    }
  }

  Future<LoginResult> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.login(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: data['user'] as Map<String, dynamic>,
        isLoading: false,
      );
      return const LoginResult(success: true);
    } catch (e) {
      String message = e.toString();
      bool isPending = false;
      bool isRejected = false;
      String? rejectionReason;

      if (e is DioException && e.response?.data != null) {
        final resp = e.response!.data;
        if (resp is Map) {
          if (resp['message'] != null) {
            message = resp['message'].toString();
          }
          final errorData = resp['data'];
          if (errorData is Map) {
            if (errorData['approvalStatus'] == 'pending') {
              isPending = true;
            } else if (errorData['approvalStatus'] == 'rejected') {
              isRejected = true;
              rejectionReason = errorData['rejectionReason']?.toString();
            }
          }
        }
      }
      state = state.copyWith(error: message, isLoading: false);
      return LoginResult(
        success: false,
        isPending: isPending,
        isRejected: isRejected,
        rejectionReason: rejectionReason,
        message: message,
        error: message,
      );
    }
  }

  Future<RegisterResult> register(
    String email,
    String password, {
    String? fullName,
    String? role,
    String? phone,
    String? nic,
    String? gender,
    String? province,
    String? district,
    String? policeId,
    String? lawyerId,
    String? courtNumber,
    String? certificateUrl,
    String? aboutMe,
    String? preferredLanguage,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.register(
        email,
        password,
        fullName: fullName,
        role: role,
        phone: phone,
        nic: nic,
        gender: gender,
        province: province,
        district: district,
        policeId: policeId,
        lawyerId: lawyerId,
        courtNumber: courtNumber,
        certificateUrl: certificateUrl,
        aboutMe: aboutMe,
        preferredLanguage: preferredLanguage,
      );

      final isPending = data['isPending'] == true;
      if (isPending) {
        // Pending approval: do not transition to authenticated
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          error: null,
        );
        return RegisterResult(
          success: true,
          isPending: true,
          message: data['message'] as String? ??
              'Registration submitted successfully. Your account is pending administrator verification.',
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: data['user'] as Map<String, dynamic>?,
          isLoading: false,
        );
        return const RegisterResult(success: true, isPending: false);
      }
    } catch (e) {
      String message = e.toString();
      if (e is DioException && e.response?.data != null) {
        final resp = e.response!.data;
        if (resp is Map && resp['message'] != null) {
          message = resp['message'].toString();
        }
      }
      state = state.copyWith(error: message, isLoading: false);
      return RegisterResult(success: false, error: message);
    }
  }

  void setUser(Map<String, dynamic> user) {
    state = state.copyWith(user: user);
  }

  Future<void> refreshUser() async {
    try {
      final user = await _repo.getMe();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
