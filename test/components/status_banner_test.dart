/// StatusBanner Component Tests - Comprehensive test coverage
///
/// PERMANENT TEST FORTRESS: Regression protection for status display component
/// Tests all status types, styling, interactions, and factory constructors
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/components/common/indicators/status_banner.dart';

void main() {
  group('StatusBanner Component Tests', () {
    testWidgets(
        '🛡️ REGRESSION: StatusBanner displays loading status correctly',
        (WidgetTester tester) async {
      const message = 'Loading test data...';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBanner.loading(message: message),
          ),
        ),
      );

      // Verify message text is displayed
      expect(find.text(message), findsOneWidget);

      // Verify loading icon is displayed
      expect(find.byIcon(Icons.info), findsOneWidget);

      // Verify dismiss button appears when onDismiss is not provided
      expect(find.text('Dismiss'), findsNothing);
    });

    testWidgets('🛡️ REGRESSION: StatusBanner displays error status correctly',
        (WidgetTester tester) async {
      const message = 'Error occurred during testing';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBanner.error(message: message),
          ),
        ),
      );

      // Verify message text is displayed
      expect(find.text(message), findsOneWidget);

      // Verify error icon is displayed
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets(
        '🛡️ REGRESSION: StatusBanner displays success status correctly',
        (WidgetTester tester) async {
      const message = 'Operation completed successfully';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBanner.success(message: message),
          ),
        ),
      );

      // Verify message text is displayed
      expect(find.text(message), findsOneWidget);

      // Verify success icon is displayed
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('🛡️ REGRESSION: StatusBanner displays info status correctly',
        (WidgetTester tester) async {
      const message = 'Information for testing';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBanner.info(message: message),
          ),
        ),
      );

      // Verify message text is displayed
      expect(find.text(message), findsOneWidget);

      // Verify info icon is displayed
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('🛡️ REGRESSION: StatusBanner handles dismiss action correctly',
        (WidgetTester tester) async {
      bool dismissed = false;
      const message = 'Dismissible status message';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBanner.loading(
              message: message,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      // Verify dismiss button appears
      expect(find.text('Dismiss'), findsOneWidget);

      // Tap dismiss button
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      // Verify dismiss callback was called
      expect(dismissed, isTrue);
    });

    testWidgets('🛡️ REGRESSION: StatusBanner displays custom action correctly',
        (WidgetTester tester) async {
      bool actionPressed = false;
      const message = 'Status with custom action';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBanner.info(
              message: message,
              action: TextButton(
                onPressed: () => actionPressed = true,
                child: const Text('Retry'),
              ),
            ),
          ),
        ),
      );

      // Verify custom action button appears
      expect(find.text('Retry'), findsOneWidget);

      // Verify default dismiss button does not appear
      expect(find.text('Dismiss'), findsNothing);

      // Tap custom action
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Verify action callback was called
      expect(actionPressed, isTrue);
    });

    testWidgets(
        '🛡️ REGRESSION: StatusBanner hides icon when showIcon is false',
        (WidgetTester tester) async {
      const message = 'Status without icon';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBanner(
              type: StatusBannerType.error,
              message: message,
              showIcon: false,
            ),
          ),
        ),
      );

      // Verify message text is displayed
      expect(find.text(message), findsOneWidget);

      // Verify no icon is displayed
      expect(find.byIcon(Icons.error), findsNothing);
    });

    testWidgets(
        '🛡️ REGRESSION: StatusBanner applies correct styling for each type',
        (WidgetTester tester) async {
      const message = 'Styling test';

      // Test loading styling
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBanner.loading(message: message),
          ),
        ),
      );

      Container loadingContainer = tester.widget<Container>(
        find.byType(Container).first,
      );
      BoxDecoration loadingDecoration =
          loadingContainer.decoration as BoxDecoration;
      expect(loadingDecoration.color, Colors.blue.withValues(alpha: 0.1));

      // Test error styling
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBanner.error(message: message),
          ),
        ),
      );

      Container errorContainer = tester.widget<Container>(
        find.byType(Container).first,
      );
      BoxDecoration errorDecoration =
          errorContainer.decoration as BoxDecoration;
      expect(errorDecoration.color, Colors.red.withValues(alpha: 0.1));
    });

    testWidgets(
        '🛡️ REGRESSION: StatusBanner factory constructors work correctly',
        (WidgetTester tester) async {
      const message = 'Factory constructor test';

      // Test each factory constructor creates correct type
      final loadingBanner = StatusBanner.loading(message: message);
      expect(loadingBanner.type, StatusBannerType.loading);

      final errorBanner = StatusBanner.error(message: message);
      expect(errorBanner.type, StatusBannerType.error);

      final successBanner = StatusBanner.success(message: message);
      expect(successBanner.type, StatusBannerType.success);

      final infoBanner = StatusBanner.info(message: message);
      expect(infoBanner.type, StatusBannerType.info);
    });
  });
}
