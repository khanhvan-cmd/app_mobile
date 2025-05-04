import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baicuoiki/main.dart';

void main() {
  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the login screen is displayed (initial route is '/login').
    expect(find.text('Task Manager'), findsOneWidget); // Check for the app title
    expect(find.text('Login'), findsOneWidget); // Check for the "Login" button
    expect(find.text('Sign in with Google'), findsOneWidget); // Check for Google sign-in button
    expect(find.text('Don\'t have an account? Register'), findsOneWidget); // Check for register link

    // Tap the register link and verify navigation to RegisterScreen.
    await tester.tap(find.text('Don\'t have an account? Register'));
    await tester.pumpAndSettle(); // Wait for navigation to complete

    // Verify that the register screen is displayed.
    expect(find.text('Register'), findsOneWidget); // Check for the "Register" title
  });
}