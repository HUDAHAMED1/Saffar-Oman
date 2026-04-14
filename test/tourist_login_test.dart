import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cp12/touristlogin.dart';

class FakeUser implements User {
  @override
  final String uid;

  @override
  final String? email;

  FakeUser({
    required this.uid,
    this.email,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserCredential implements UserCredential {
  @override
  final User? user;

  FakeUserCredential(this.user);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _fakeSignOut() async {}

void main() {
  testWidgets('Login screen shows email, password, and button',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TouristLoginScreen(
              signIn: (_, __) async => FakeUserCredential(
                FakeUser(uid: '123', email: 'test@test.com'),
              ),
              readUserData: (_) async => {
                'role': 'tourist',
                'status': 'approved',
              },
              signOut: _fakeSignOut,
            ),
            routes: {
              '/explore': (_) => const Scaffold(body: Text('Explore Screen')),
            },
          ),
        );

        expect(find.byKey(const Key('emailField')), findsOneWidget);
        expect(find.byKey(const Key('passwordField')), findsOneWidget);
        expect(find.byKey(const Key('loginButton')), findsOneWidget);
      });

  testWidgets('Tourist login success navigates to explore',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TouristLoginScreen(
              signIn: (_, __) async => FakeUserCredential(
                FakeUser(uid: '123', email: 'tourist@test.com'),
              ),
              readUserData: (_) async => {
                'role': 'tourist',
                'status': 'approved',
              },
              signOut: _fakeSignOut,
            ),
            routes: {
              '/explore': (_) => const Scaffold(body: Text('Explore Screen')),
            },
          ),
        );

        await tester.enterText(
          find.byKey(const Key('emailField')),
          'tourist@test.com',
        );
        await tester.enterText(
          find.byKey(const Key('passwordField')),
          '12345678',
        );
        await tester.tap(find.byKey(const Key('loginButton')));
        await tester.pumpAndSettle();

        expect(find.text('Explore Screen'), findsOneWidget);
      });

  testWidgets('Guide approved login success navigates to guide home',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TouristLoginScreen(
              signIn: (_, __) async => FakeUserCredential(
                FakeUser(uid: '456', email: 'guide@test.com'),
              ),
              readUserData: (_) async => {
                'role': 'guide',
                'status': 'approved',
              },
              signOut: _fakeSignOut,
            ),
            routes: {
              '/guideHome': (_) => const Scaffold(body: Text('Guide Home Screen')),
            },
          ),
        );

        await tester.enterText(
          find.byKey(const Key('emailField')),
          'guide@test.com',
        );
        await tester.enterText(
          find.byKey(const Key('passwordField')),
          '12345678',
        );
        await tester.tap(find.byKey(const Key('loginButton')));
        await tester.pumpAndSettle();

        expect(find.text('Guide Home Screen'), findsOneWidget);
      });

  testWidgets('Guide pending shows approval message',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TouristLoginScreen(
              signIn: (_, __) async => FakeUserCredential(
                FakeUser(uid: '456', email: 'guide@test.com'),
              ),
              readUserData: (_) async => {
                'role': 'guide',
                'status': 'pending',
              },
              signOut: _fakeSignOut,
            ),
          ),
        );

        await tester.enterText(
          find.byKey(const Key('emailField')),
          'guide@test.com',
        );
        await tester.enterText(
          find.byKey(const Key('passwordField')),
          '12345678',
        );
        await tester.tap(find.byKey(const Key('loginButton')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byKey(const Key('errorText')), findsOneWidget);
        expect(
          find.text('Your guide account is pending approval. Please try again later.'),
          findsOneWidget,
        );
      });

  testWidgets('Admin login success navigates to admin dashboard',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TouristLoginScreen(
              signIn: (_, __) async => FakeUserCredential(
                FakeUser(uid: '999', email: 'admin@test.com'),
              ),
              readUserData: (_) async => {
                'role': 'admin',
                'status': 'approved',
              },
              signOut: _fakeSignOut,
            ),
            routes: {
              '/adminDashboard': (_) =>
              const Scaffold(body: Text('Admin Dashboard Screen')),
            },
          ),
        );

        await tester.enterText(
          find.byKey(const Key('emailField')),
          'admin@test.com',
        );
        await tester.enterText(
          find.byKey(const Key('passwordField')),
          '12345678',
        );
        await tester.tap(find.byKey(const Key('loginButton')));
        await tester.pumpAndSettle();

        expect(find.text('Admin Dashboard Screen'), findsOneWidget);
      });

  testWidgets('Missing role shows error message',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TouristLoginScreen(
              signIn: (_, __) async => FakeUserCredential(
                FakeUser(uid: '789', email: 'user@test.com'),
              ),
              readUserData: (_) async => {
                'status': 'approved',
              },
              signOut: _fakeSignOut,
            ),
          ),
        );

        await tester.enterText(
          find.byKey(const Key('emailField')),
          'user@test.com',
        );
        await tester.enterText(
          find.byKey(const Key('passwordField')),
          '12345678',
        );
        await tester.tap(find.byKey(const Key('loginButton')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byKey(const Key('errorText')), findsOneWidget);
        expect(find.text('User role is invalid or missing.'), findsOneWidget);
      });
}