// The contract between the UI and the backend.
//
// The UI only ever talks to these interfaces. Right now they're backed by the
// in-memory fakes in `data/fake/`, so every screen works with no backend.
// Person B replaces each fake with a real implementation (drift for local
// SQLite, Supabase for the cloud, Judge0 for code) and changes one line in
// `state/providers.dart`. No screen needs to change.

import 'package:bytestreak/domain/models.dart';

/// The question bank. Real version: drift (SQLite) + content pull from Supabase.
abstract interface class ContentRepository {
  Future<CoursePath> loadPath();
}

class AuthSession {
  const AuthSession({required this.userId, required this.email});
  final String userId;
  final String email;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Accounts. Real version: Supabase Auth (email + password).
abstract interface class AuthRepository {
  /// The session saved from last time, if the user didn't log out.
  Future<AuthSession?> restoreSession();

  /// [identifier] is an email address or a username.
  /// Throws [AuthException] with a user-facing message on failure.
  Future<AuthSession> signIn({required String identifier, required String password});

  Future<AuthSession> signUp({required String email, required String password, required String username});

  Future<void> signOut();
  Future<void> sendPasswordReset(String identifier);
  Future<bool> isUsernameAvailable(String username);

  /// Shown under the login form while the fake backend is in use. The real
  /// implementation returns null.
  String? get demoHint;
}

/// The player's own progress. Real version: drift (SQLite, source of truth)
/// plus a background sync of XP events to Supabase.
abstract interface class PlayerRepository {
  Future<PlayerState?> load(String userId);

  /// Called after every change. Must be cheap: the UI doesn't wait for it.
  Future<void> save(PlayerState state);
}

/// Device settings. Real version: the drift `settings` table.
abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

/// The global leaderboard. Real version: a Supabase ranking query.
abstract interface class LeaderboardRepository {
  /// The fake uses the local values passed in to place you on the board;
  /// the real implementation can ignore them and read the server's numbers.
  Future<LeaderboardPage> fetch({
    required String userId,
    required String username,
    required int avatarIndex,
    required int xp,
    required bool shareStats,
  });
}

/// Runs code against test cases. Real version: the `run-code` Supabase Edge
/// Function in front of Judge0/Piston. Never run user code locally.
abstract interface class CodeRunner {
  Future<RunResult> run({
    required CodingQuestion question,
    required String language,
    required String code,
    required bool includeHidden,
  });
}
