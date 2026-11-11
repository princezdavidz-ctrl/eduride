// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trend/core/navigation/app_drawer_navigation.dart';
import 'package:trend/features/auth/presentation/login_screen.dart';
import 'package:trend/features/auth/presentation/forgot_password_screen.dart';
import 'package:trend/features/auth/presentation/language_screen.dart';
import 'package:trend/features/auth/presentation/otp_verification_screen.dart';
import 'package:trend/features/auth/presentation/splash_screen.dart';
import 'package:trend/features/family/domain/entities/child.dart';
import 'package:trend/features/family/domain/repositories/children_repository.dart';
import 'package:trend/features/family/presentation/child_setup_screen.dart';
import 'package:trend/features/family/presentation/children_screen.dart';
import 'package:trend/features/family/presentation/providers/children_provider.dart';
import 'package:trend/features/navigation/presentation/drawer_page_shell.dart';
import 'package:trend/features/navigation/presentation/providers/drawer_data_provider.dart';
import 'package:trend/features/navigation/presentation/trip_history_screen.dart';
import 'package:trend/features/notifications/presentation/notifications_screen.dart';

void main() {
  testWidgets('notifications render the alerts returned by the service', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawerRecordsProvider('/notifications').overrideWith(
            (ref) async => [
              {
                'id': 'alert-live-1',
                'severity': 'info',
                'title': 'Route update received',
                'message': 'A service update for this route.',
                'createdAt': '2026-10-28T10:00:00Z',
                'read': true,
              },
            ],
          ),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Route update received'), findsOneWidget);
    expect(find.text('A service update for this route.'), findsOneWidget);
    expect(find.textContaining('Bus 24 departed'), findsNothing);
  });

  testWidgets('trip history renders records returned by the service', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawerRecordsProvider('/journeys').overrideWith(
            (ref) async => [
              {
                'busId': '077',
                'route': 'Lake Route',
                'status': 'completed',
                'departureAt': '07:30',
                'arrivalAt': '08:05',
              },
            ],
          ),
        ],
        child: const MaterialApp(home: TripHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bus 077 · Lake Route'), findsOneWidget);
    expect(
      find.text('Status: completed • Departure: 07:30 • Arrival: 08:05'),
      findsOneWidget,
    );
    expect(find.textContaining('Maya Morgan'), findsNothing);
  });

  testWidgets('manage children can add a child and change their school', (
    WidgetTester tester,
  ) async {
    final repository = _FakeChildrenRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [childrenRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ChildrenScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maya Morgan'), findsOneWidget);
    expect(find.text('Oakwood School'), findsOneWidget);

    await tester.tap(find.text('Change school'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Riverside Academy');
    await tester.tap(find.text('Save school'));
    await tester.pumpAndSettle();

    expect(find.text('Riverside Academy'), findsOneWidget);
    expect(find.text('School updated and sent for approval.'), findsOneWidget);

    await tester.tap(find.byTooltip('Add child'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Noah Morgan');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Greenfield Campus',
    );
    await tester.tap(find.text('Add child'));
    await tester.pumpAndSettle();

    expect(find.text('Noah Morgan'), findsOneWidget);
    expect(find.text('Greenfield Campus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer page menu returns home and opens the app drawer', (
    WidgetTester tester,
  ) async {
    var drawerTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: appHomeScaffoldKey,
          drawer: Drawer(
            child: ListTile(
              title: const Text('Main navigation'),
              onTap: () => drawerTapped = true,
            ),
          ),
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DrawerPageShell(
                    title: 'Settings',
                    description: 'Manage your preferences.',
                    items: [],
                  ),
                ),
              ),
              child: const Text('Open settings'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Main navigation'), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
    await tester.tap(find.text('Main navigation'));
    expect(drawerTapped, isTrue);
  });

  testWidgets('language choices slide over the background image', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: LanguageScreen()));
    await tester.pump();

    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Kiswahili'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LanguageScreen),
        matching: find.byType(SlideTransition),
      ),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: find.byType(Stack), matching: find.byType(Image)),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('child profiles continue to school approval', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChildSetupScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'Maya Morgan');
    await tester.enterText(find.byType(TextFormField).at(1), '10');
    await tester.enterText(find.byType(TextFormField).at(2), 'Oakwood School');
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Waiting for school verification'), findsOneWidget);
    expect(
      find.text('Maya Morgan · 10 years old\nOakwood School'),
      findsOneWidget,
    );
    expect(find.text('Continue to home'), findsNothing);
  });

  testWidgets('login and signup switch in place', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('auth-form-card')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );

    final formCard = find.byKey(const ValueKey('auth-form-card'));
    expect(
      find.descendant(of: formCard, matching: find.text('Welcome Back')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: formCard,
        matching: find.text('Sign in to continue your school journey.'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: formCard, matching: find.text('Edu Ride')),
      findsNothing,
    );
    expect(
      find.descendant(of: formCard, matching: find.text('Sign in with Google')),
      findsNothing,
    );

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);
  });

  testWidgets(
    'splash requests permissions and continues without an extra page',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      var permissionsRequested = false;
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/language': (_) =>
                const Scaffold(body: Text('Choose your language')),
          },
          home: SplashScreen(
            internetCheck: () async => true,
            permissionRequester: () async {
              permissionsRequested = true;
              return null;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Edu Ride'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Internet connection ready'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_rounded), findsNothing);
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
      expect(permissionsRequested, isTrue);
      expect(find.text('Choose your language'), findsOneWidget);
    },
  );

  testWidgets('OTP screen clearly reports verification is unavailable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OtpVerificationScreen(
          email: 'test@gmail.com',
          purpose: OtpPurpose.signIn,
        ),
      ),
    );

    expect(find.text('Verify your sign in'), findsOneWidget);
    expect(find.textContaining('OTP verification is not configured'), findsOneWidget);
    final verifyButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Verify code'),
    );
    expect(verifyButton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('forgot password layout fits a narrow screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ForgotPasswordScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeChildrenRepository implements ChildrenRepository {
  final List<Child> _children = [
    const Child(
      id: 'child-1',
      firstName: 'Maya',
      lastName: 'Morgan',
      schoolName: 'Oakwood School',
    ),
  ];

  @override
  Future<List<Child>> fetchChildren() async => List.of(_children);

  @override
  Future<Child> addChild({required String name, required String school}) async {
    final names = name.split(' ');
    final child = Child(
      id: 'child-${_children.length + 1}',
      firstName: names.first,
      lastName: names.skip(1).join(' '),
      schoolName: school,
    );
    _children.add(child);
    return child;
  }

  @override
  Future<Child> changeSchool({
    required String childId,
    required String school,
  }) async {
    final index = _children.indexWhere((child) => child.id == childId);
    final updatedChild = _children[index].copyWith(schoolName: school);
    _children[index] = updatedChild;
    return updatedChild;
  }
}
