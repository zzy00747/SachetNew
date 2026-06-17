// This is a basic Flutter widget smoke test.
//
// It verifies that MyApp can be built and renders a MaterialApp after
// AppGlobal has been initialized. The old Counter Demo test was out of date
// because MyApp now depends on global state (SharedPreferences, AppSettings,
// etc.) that must be set up before pumping the widget tree.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sachet/main.dart';
import 'package:sachet/utils/app_global.dart';

void main() {
  testWidgets('App launches and renders MaterialApp', (WidgetTester tester) async {
    // Ensure the Flutter binding is initialized for the test environment.
    TestWidgetsFlutterBinding.ensureInitialized();

    // Provide mock SharedPreferences data so AppGlobal.init() can run without
    // relying on the real platform storage. Disable auto update to avoid leaving
    // a pending Timer after the widget tree is disposed.
    SharedPreferences.setMockInitialValues({
      'appSettings': jsonEncode({
        ...defaultAppSettingsConfig,
        'isAutoCheckUpdate': false,
      }),
    });

    // Initialize global state just like main() does at app startup.
    await AppGlobal.init();

    // Build the app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for async initialization (providers, navigation, etc.) to settle.
    await tester.pumpAndSettle();

    // Verify that the MaterialApp was rendered.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
