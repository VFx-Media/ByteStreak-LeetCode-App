// Riverpod providers: the "wiring diagram" of the app.
//
// A provider is a named, app-wide value that widgets can read. When its value
// changes, every widget that watches it rebuilds. Screens never construct
// repositories or controllers themselves; they ask for them here.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:bytestreak/data/fake/fake_backend.dart';
import 'package:bytestreak/data/fake/fake_content.dart';
import 'package:bytestreak/data/repositories.dart';
import 'package:bytestreak/domain/achievements.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/lesson_session.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/domain/path_progress.dart';
import 'package:bytestreak/state/player_controller.dart';
import 'package:bytestreak/state/settings_controller.dart';

/// Every backend dependency in one bundle.
///
/// **Person B:** this is the one place to swap the fakes for real
/// implementations. Build an `AppServices` with your drift/Supabase/Judge0
/// classes in `main.dart` instead of `AppServices.fake()`.
class AppServices {
  const AppServices({
    required this.content,
    required this.auth,
    required this.players,
    required this.settings,
    required this.leaderboard,
    required this.codeRunner,
    this.clock = DateTime.now,
  });

  factory AppServices.fake({
    DateTime Function()? clock,
    Duration latency = Duration.zero,
    bool signedIn = false,
    AppSettings settings = const AppSettings(),
  }) {
    final now = clock ?? DateTime.now;
    final backend = FakeBackend(clock: now, path: buildSamplePath(), latency: latency)..settings = settings;
    if (signedIn) backend.session = const AuthSession(userId: demoUserId, email: demoEmail);
    return AppServices(
      content: FakeContentRepository(),
      auth: backend.auth,
      players: backend.players,
      settings: backend.settingsRepo,
      leaderboard: backend.leaderboard,
      codeRunner: backend.codeRunner,
      clock: now,
    );
  }

  final ContentRepository content;
  final AuthRepository auth;
  final PlayerRepository players;
  final SettingsRepository settings;
  final LeaderboardRepository leaderboard;
  final CodeRunner codeRunner;
  final DateTime Function() clock;
}

/// Loads what the first screen needs before the app is shown, and returns
/// the provider overrides that hand it to the widget tree.
Future<List<Override>> bootstrap(AppServices services) async {
  final path = await services.content.loadPath();
  final settings = await services.settings.load();
  final session = await services.auth.restoreSession();
  final player = session == null ? null : await services.players.load(session.userId);
  return [
    servicesProvider.overrideWithValue(services),
    coursePathProvider.overrideWithValue(path),
    initialSettingsProvider.overrideWithValue(settings),
    initialPlayerProvider.overrideWithValue(player),
  ];
}

// ---- Set by bootstrap() -----------------------------------------------------

final servicesProvider = Provider<AppServices>((ref) => throw UnimplementedError('Call bootstrap() first'));
final coursePathProvider = Provider<CoursePath>((ref) => throw UnimplementedError('Call bootstrap() first'));
final initialSettingsProvider = Provider<AppSettings>((ref) => const AppSettings());
final initialPlayerProvider = Provider<PlayerState?>((ref) => null);

/// The current time. Tests replace this to control hearts and streaks.
final clockProvider = Provider<DateTime Function()>((ref) => ref.watch(servicesProvider).clock);

// ---- App state --------------------------------------------------------------

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// The player's data: null before anyone has signed in.
///
/// Signing out flips [signedInProvider] but leaves this in place until the
/// next sign-in replaces it. Clearing it straight away would crash any screen
/// still on display for the frame before the router moves to /welcome.
final playerProvider = NotifierProvider<PlayerController, PlayerState?>(PlayerController.new);

/// Whether someone is signed in. The router watches this to decide which
/// screens are reachable.
final signedInProvider = NotifierProvider<SignedIn, bool>(SignedIn.new);

class SignedIn extends Notifier<bool> {
  @override
  bool build() => ref.read(initialPlayerProvider) != null;

  void set(bool value) => state = value;
}

/// The player, for screens that are only reachable when signed in.
final currentPlayerProvider = Provider<PlayerState>((ref) {
  final player = ref.watch(playerProvider);
  if (player == null) throw StateError('No player is signed in');
  return player;
});

final pathProgressProvider = Provider<PathProgress>((ref) {
  return PathProgress(ref.watch(coursePathProvider), ref.watch(currentPlayerProvider));
});

final achievementDefsProvider = Provider<List<AchievementDef>>((ref) {
  return buildAchievements(ref.watch(coursePathProvider));
});

/// The global leaderboard. Re-fetched when your XP, name or privacy changes.
///
/// No automatic retry: Riverpod's default retries a failed load for ~40 s,
/// showing a spinner the whole time. Offline, it's better to say so right
/// away; the Leaderboard screen has a "Try again" button.
final leaderboardProvider = FutureProvider<LeaderboardPage>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  final shareStats = ref.watch(settingsProvider.select((s) => s.shareStats));
  return ref
      .watch(servicesProvider)
      .leaderboard
      .fetch(
        userId: player.profile.userId,
        username: player.profile.username,
        avatarIndex: player.profile.avatarIndex,
        xp: player.xp,
        shareStats: shareStats,
      );
}, retry: (_, _) => null);

/// Your league, from your leaderboard rank (unranked while loading).
final leagueProvider = Provider<League>((ref) {
  final rank = ref.watch(leaderboardProvider).value?.myRank;
  return GameRules.leagueForRank(rank);
});

/// The result of the session that just ended, for the Lesson complete screen.
final lastResultProvider = NotifierProvider<LastResult, LessonResult?>(LastResult.new);

class LastResult extends Notifier<LessonResult?> {
  @override
  LessonResult? build() => null;

  void set(LessonResult result) => state = result;
}

/// What the user typed on sign-up step 1, carried to step 2.
final signupDraftProvider = NotifierProvider<SignupDraftController, SignupDraft>(SignupDraftController.new);

class SignupDraft {
  const SignupDraft({
    this.username = '',
    this.email = '',
    this.password = '',
    this.avatarIndex = 0,
    this.experienceLevel = ExperienceLevel.beginner,
    this.goals = const {},
    this.dailyGoal = DailyGoal.regular,
  });

  final String username;
  final String email;
  final String password;
  final int avatarIndex;
  final ExperienceLevel experienceLevel;
  final Set<String> goals;
  final DailyGoal dailyGoal;

  SignupDraft copyWith({
    String? username,
    String? email,
    String? password,
    int? avatarIndex,
    ExperienceLevel? experienceLevel,
    Set<String>? goals,
    DailyGoal? dailyGoal,
  }) {
    return SignupDraft(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      goals: goals ?? this.goals,
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }
}

class SignupDraftController extends Notifier<SignupDraft> {
  @override
  SignupDraft build() => const SignupDraft();

  void update(SignupDraft Function(SignupDraft d) change) => state = change(state);
  void reset() => state = const SignupDraft();
}
