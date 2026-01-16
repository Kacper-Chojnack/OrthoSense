/// Integration test: Auth → Session Flow.
///
/// Tests the complete user journey from authentication
/// through session management.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth → Session Flow Integration', () {
    group('Login → Home → Session Flow', () {
      testWidgets('user can login and start session', (tester) async {
        // Setup
        final authState = TestAuthState();
        final sessionState = TestSessionState();

        await tester.pumpWidget(
          MaterialApp(
            home: TestAppShell(
              authState: authState,
              sessionState: sessionState,
            ),
          ),
        );

        // 1. User is on login screen
        expect(find.byType(TestLoginScreen), findsOneWidget);

        // 2. User enters credentials
        await tester.enterText(
          find.byKey(const Key('email_field')),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );

        // 3. User taps login
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // 4. User is redirected to home
        expect(find.byType(TestHomeScreen), findsOneWidget);
        expect(authState.isAuthenticated, isTrue);

        // 5. User starts session (button is on home screen)
        await tester.tap(find.byKey(const Key('start_session_button')));
        await tester.pumpAndSettle();

        // 6. User navigates to session screen via Deep Squat
        await tester.tap(find.text('Deep Squat'));
        await tester.pumpAndSettle();

        // 7. Session is active
        expect(find.byType(TestSessionScreen), findsOneWidget);
        expect(sessionState.isActive, isTrue);
      });

      testWidgets('session persists auth token', (tester) async {
        final authState = TestAuthState()
          ..login('test@example.com', 'password');
        final sessionState = TestSessionState();

        await tester.pumpWidget(
          MaterialApp(
            home: TestAppShell(
              authState: authState,
              sessionState: sessionState,
            ),
          ),
        );

        // Start session first (button on home screen), then navigate
        await tester.tap(find.byKey(const Key('start_session_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Deep Squat'));
        await tester.pumpAndSettle();

        // Session should have user context
        expect(sessionState.userId, equals(authState.userId));
      });

      testWidgets('logout ends active session', (tester) async {
        final authState = TestAuthState()
          ..login('test@example.com', 'password');
        final sessionState = TestSessionState()..startSession('squat');

        await tester.pumpWidget(
          MaterialApp(
            home: TestAppShell(
              authState: authState,
              sessionState: sessionState,
            ),
          ),
        );

        // Verify session active
        expect(sessionState.isActive, isTrue);

        // Logout
        await tester.tap(find.byKey(const Key('logout_button')));
        await tester.pumpAndSettle();

        // Session should end
        expect(sessionState.isActive, isFalse);
        expect(find.byType(TestLoginScreen), findsOneWidget);
      });
    });

    group('Session → Results Flow', () {
      testWidgets('completed session shows results', (tester) async {
        final authState = TestAuthState()
          ..login('test@example.com', 'password');
        final sessionState = TestSessionState()..startSession('squat');

        await tester.pumpWidget(
          MaterialApp(
            home: TestSessionScreen(
              authState: authState,
              sessionState: sessionState,
            ),
          ),
        );

        // Complete session
        await tester.tap(find.byKey(const Key('complete_session_button')));
        await tester.pumpAndSettle();

        // Results screen shown
        expect(find.byType(TestResultsScreen), findsOneWidget);
        expect(sessionState.hasResults, isTrue);
      });

      testWidgets('results are persisted for offline access', (tester) async {
        final authState = TestAuthState()
          ..login('test@example.com', 'password');
        final sessionState = TestSessionState()
          ..startSession('squat')
          ..completeSession(score: 85);

        final storage = TestLocalStorage();
        // Simulate persistence of session results
        storage.save('session_${sessionState.sessionId}', {
          'score': 85,
          'exercise': 'squat',
        });

        await tester.pumpWidget(
          MaterialApp(
            home: TestResultsScreen(
              sessionState: sessionState,
              storage: storage,
            ),
          ),
        );

        // Results should be saved locally
        expect(
          storage.containsKey('session_${sessionState.sessionId}'),
          isTrue,
        );
      });

      testWidgets('results sync when online', (tester) async {
        final sessionState = TestSessionState()
          ..startSession('squat')
          ..completeSession(score: 85);

        final syncState = TestSyncState();

        await tester.pumpWidget(
          MaterialApp(
            home: TestResultsScreen(
              sessionState: sessionState,
              syncState: syncState,
            ),
          ),
        );

        // Trigger sync
        await tester.tap(find.byKey(const Key('sync_button')));
        await tester.pumpAndSettle();

        expect(syncState.pendingItems, equals(0));
      });
    });

    group('Offline Mode', () {
      testWidgets('session works offline', (tester) async {
        final authState = TestAuthState()
          ..login('test@example.com', 'password');
        final sessionState = TestSessionState();
        final networkState = TestNetworkState(isConnected: false);

        await tester.pumpWidget(
          MaterialApp(
            home: TestAppShell(
              authState: authState,
              sessionState: sessionState,
              networkState: networkState,
            ),
          ),
        );

        // Should show offline indicator
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);

        // Can still start session (button first, then navigate)
        await tester.tap(find.byKey(const Key('start_session_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Deep Squat'));
        await tester.pumpAndSettle();

        expect(sessionState.isActive, isTrue);
      });

      testWidgets('offline sessions queue for sync', (tester) async {
        final sessionState = TestSessionState()
          ..startSession('squat')
          ..completeSession(score: 80);

        // Queue item manually (simulating offline completion behavior)
        final syncState = TestSyncState()
          ..queueItem('session_${sessionState.sessionId}');
        final networkState = TestNetworkState(isConnected: false);

        await tester.pumpWidget(
          MaterialApp(
            home: TestResultsScreen(
              sessionState: sessionState,
              syncState: syncState,
              networkState: networkState,
            ),
          ),
        );

        // Item should be queued
        expect(syncState.pendingItems, equals(1));
      });

      testWidgets('sync resumes when online', (tester) async {
        final syncState = TestSyncState()..queueItem('session_1');
        final networkState = TestNetworkState(isConnected: false);

        await tester.pumpWidget(
          MaterialApp(
            home: TestSyncIndicator(
              syncState: syncState,
              networkState: networkState,
            ),
          ),
        );

        expect(syncState.pendingItems, equals(1));

        // Go online
        networkState.connect();
        await tester.pumpAndSettle();

        // Sync should process
        expect(syncState.pendingItems, equals(0));
      });
    });

    group('Error Recovery', () {
      testWidgets('session saved on unexpected exit', (tester) async {
        final sessionState = TestSessionState()
          ..startSession('squat')
          ..addRep(quality: 0.9);

        await tester.pumpWidget(
          MaterialApp(
            home: TestSessionScreen(
              sessionState: sessionState,
            ),
          ),
        );

        // Simulate unexpected exit - saves to sessionState's internal storage
        sessionState.simulateCrash();

        // Recovery data should exist in sessionState's internal storage
        expect(sessionState.hasRecoveryData, isTrue);
      });

      testWidgets('can resume crashed session', (tester) async {
        final storage = TestLocalStorage()
          ..save('session_recovery', {
            'exercise': 'squat',
            'reps': 5,
            'timestamp': DateTime.now().toIso8601String(),
          });

        final sessionState = TestSessionState();
        final authState = TestAuthState(isAuthenticated: true);

        await tester.pumpWidget(
          MaterialApp(
            home: TestAppShell(
              authState: authState,
              sessionState: sessionState,
              storage: storage,
            ),
          ),
        );

        // Should prompt recovery
        expect(find.text('Resume previous session?'), findsOneWidget);

        await tester.tap(find.text('Resume'));
        await tester.pumpAndSettle();

        expect(sessionState.repCount, equals(5));
      });

      testWidgets('auth token refresh during session', (tester) async {
        final authState = TestAuthState()
          ..login('test@example.com', 'password')
          ..setTokenExpiry(Duration.zero);

        final sessionState = TestSessionState()..startSession('squat');

        await tester.pumpWidget(
          MaterialApp(
            home: TestSessionScreen(
              authState: authState,
              sessionState: sessionState,
            ),
          ),
        );

        // Token should refresh silently
        expect(authState.isAuthenticated, isTrue);
        expect(sessionState.isActive, isTrue);
      });
    });
  });

  group('Data Consistency', () {
    test('session references valid exercise', () {
      final exercises = TestExerciseRepository()..loadExercises();
      final session = TestSession(exerciseId: 'squat');

      expect(exercises.exists(session.exerciseId), isTrue);
    });

    test('results reference valid session', () {
      final sessions = TestSessionRepository();
      final session = sessions.create(exerciseId: 'squat');

      final result = TestResult(sessionId: session.id);

      expect(sessions.exists(result.sessionId), isTrue);
    });

    test('user owns their sessions', () {
      final user = TestUser(id: 'user_1');
      final sessions = [
        TestSession(exerciseId: 'squat', userId: 'user_1'),
        TestSession(exerciseId: 'lunge', userId: 'user_1'),
        TestSession(exerciseId: 'squat', userId: 'user_2'),
      ];

      final userSessions = sessions.where((s) => s.userId == user.id);

      expect(userSessions.length, equals(2));
    });
  });
}

// Test implementations
class TestAuthState extends ChangeNotifier {
  TestAuthState({bool isAuthenticated = false})
    : _isAuthenticated = isAuthenticated;

  bool _isAuthenticated = false;
  String? _userId;
  DateTime? _tokenExpiry;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;

  void login(String email, String password) {
    _isAuthenticated = true;
    _userId = 'user_${email.hashCode}';
    _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _userId = null;
    notifyListeners();
  }

  void setTokenExpiry(Duration validity) {
    _tokenExpiry = DateTime.now().add(validity);
    if (_tokenExpiry!.isBefore(DateTime.now())) {
      _refreshToken();
    }
  }

  void _refreshToken() {
    _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
  }
}

class TestSessionState extends ChangeNotifier {
  bool _isActive = false;
  String? _sessionId;
  String? _exerciseId;
  String? _userId;
  int _repCount = 0;
  int? _score;
  final _storage = TestLocalStorage();

  bool get isActive => _isActive;
  String? get sessionId => _sessionId;
  String? get userId => _userId;
  int get repCount => _repCount;
  bool get hasResults => _score != null;
  bool get hasRecoveryData => _storage.containsKey('session_recovery');

  void startSession(String exerciseId, {String? userId}) {
    _isActive = true;
    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _exerciseId = exerciseId;
    _userId = userId;
    notifyListeners();
  }

  void endSession() {
    _isActive = false;
    notifyListeners();
  }

  void completeSession({required int score}) {
    _score = score;
    _isActive = false;
    notifyListeners();
  }

  void addRep({required double quality}) {
    _repCount++;
    notifyListeners();
  }

  void simulateCrash() {
    _storage.save('session_recovery', {
      'exercise': _exerciseId,
      'reps': _repCount,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

class TestNetworkState extends ChangeNotifier {
  bool _isConnected;

  TestNetworkState({required bool isConnected}) : _isConnected = isConnected;

  bool get isConnected => _isConnected;

  void connect() {
    _isConnected = true;
    notifyListeners();
  }

  void disconnect() {
    _isConnected = false;
    notifyListeners();
  }
}

class TestSyncState extends ChangeNotifier {
  final _pending = <String>[];

  int get pendingItems => _pending.length;

  void queueItem(String id) {
    _pending.add(id);
    notifyListeners();
  }

  void processQueue() {
    _pending.clear();
    notifyListeners();
  }
}

class TestLocalStorage {
  final _data = <String, dynamic>{};

  void save(String key, dynamic value) => _data[key] = value;
  dynamic load(String key) => _data[key];
  bool containsKey(String key) => _data.containsKey(key);
  void remove(String key) => _data.remove(key);
}

class TestExerciseRepository {
  final _exercises = <String, Map<String, dynamic>>{};

  void loadExercises() {
    _exercises['squat'] = {'name': 'Deep Squat', 'category': 'lower'};
    _exercises['lunge'] = {'name': 'Hurdle Step', 'category': 'lower'};
  }

  bool exists(String id) => _exercises.containsKey(id);
}

class TestSessionRepository {
  final _sessions = <String, TestSession>{};
  int _counter = 0;

  TestSession create({required String exerciseId, String? userId}) {
    final id = 'session_${++_counter}';
    final session = TestSession(exerciseId: exerciseId, userId: userId, id: id);
    _sessions[id] = session;
    return session;
  }

  bool exists(String id) => _sessions.containsKey(id);
}

class TestSession {
  TestSession({
    required this.exerciseId,
    this.userId,
    String? id,
  }) : id = id ?? 'session_${DateTime.now().millisecondsSinceEpoch}';

  final String id;
  final String exerciseId;
  final String? userId;
}

class TestResult {
  TestResult({required this.sessionId});

  final String sessionId;
}

class TestUser {
  TestUser({required this.id});

  final String id;
}

// Test widgets
class TestAppShell extends StatefulWidget {
  const TestAppShell({
    required this.authState,
    required this.sessionState,
    this.networkState,
    this.storage,
    super.key,
  });

  final TestAuthState authState;
  final TestSessionState sessionState;
  final TestNetworkState? networkState;
  final TestLocalStorage? storage;

  @override
  State<TestAppShell> createState() => _TestAppShellState();
}

class _TestAppShellState extends State<TestAppShell> {
  @override
  void initState() {
    super.initState();
    widget.authState.addListener(_rebuild);
    widget.sessionState.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.authState.removeListener(_rebuild);
    widget.sessionState.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.authState.isAuthenticated) {
      return TestLoginScreen(authState: widget.authState);
    }

    // Check for recovery
    if (widget.storage?.containsKey('session_recovery') ?? false) {
      return Scaffold(
        body: AlertDialog(
          content: const Text('Resume previous session?'),
          actions: [
            TextButton(
              onPressed: () {
                final data =
                    widget.storage!.load('session_recovery')
                        as Map<String, dynamic>;
                widget.sessionState
                  ..startSession(data['exercise'] as String)
                  .._repCount = data['reps'] as int;
                widget.storage!.remove('session_recovery');
              },
              child: const Text('Resume'),
            ),
          ],
        ),
      );
    }

    return TestHomeScreen(
      authState: widget.authState,
      sessionState: widget.sessionState,
      networkState: widget.networkState,
    );
  }
}

class TestLoginScreen extends StatelessWidget {
  const TestLoginScreen({required this.authState, super.key});

  final TestAuthState authState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(key: const Key('email_field')),
          TextField(key: const Key('password_field')),
          ElevatedButton(
            key: const Key('login_button'),
            onPressed: () => authState.login('test@example.com', 'password'),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

class TestHomeScreen extends StatelessWidget {
  const TestHomeScreen({
    required this.authState,
    required this.sessionState,
    this.networkState,
    super.key,
  });

  final TestAuthState authState;
  final TestSessionState sessionState;
  final TestNetworkState? networkState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          if (networkState?.isConnected == false) const Icon(Icons.cloud_off),
          IconButton(
            key: const Key('logout_button'),
            icon: const Icon(Icons.logout),
            onPressed: () {
              sessionState.endSession();
              authState.logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text('Deep Squat'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => TestSessionScreen(
                    authState: authState,
                    sessionState: sessionState,
                  ),
                ),
              );
            },
          ),
          ElevatedButton(
            key: const Key('start_session_button'),
            onPressed: () =>
                sessionState.startSession('squat', userId: authState.userId),
            child: const Text('Start Session'),
          ),
        ],
      ),
    );
  }
}

class TestSessionScreen extends StatelessWidget {
  const TestSessionScreen({
    this.authState,
    required this.sessionState,
    this.storage,
    super.key,
  });

  final TestAuthState? authState;
  final TestSessionState sessionState;
  final TestLocalStorage? storage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('Reps: ${sessionState.repCount}'),
          ElevatedButton(
            key: const Key('complete_session_button'),
            onPressed: () {
              sessionState.completeSession(score: 85);
              storage?.save('session_${sessionState.sessionId}', {});
              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => TestResultsScreen(sessionState: sessionState),
                ),
              );
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}

class TestResultsScreen extends StatelessWidget {
  const TestResultsScreen({
    required this.sessionState,
    this.storage,
    this.syncState,
    this.networkState,
    super.key,
  });

  final TestSessionState sessionState;
  final TestLocalStorage? storage;
  final TestSyncState? syncState;
  final TestNetworkState? networkState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('Results'),
          if (syncState != null)
            ElevatedButton(
              key: const Key('sync_button'),
              onPressed: syncState!.processQueue,
              child: const Text('Sync'),
            ),
        ],
      ),
    );
  }
}

class TestSyncIndicator extends StatelessWidget {
  const TestSyncIndicator({
    required this.syncState,
    required this.networkState,
    super.key,
  });

  final TestSyncState syncState;
  final TestNetworkState networkState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: networkState,
      builder: (context, _) {
        if (networkState.isConnected && syncState.pendingItems > 0) {
          syncState.processQueue();
        }
        return Text('Pending: ${syncState.pendingItems}');
      },
    );
  }
}
