import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/components/common/indicators/chat_status_indicator.dart';

void main() {
  group('ChatStatusIndicator Tests', () {
    testWidgets('displays correct icon and color for uninitialized status',
        (WidgetTester tester) async {
      // GIVEN: Uninitialized status indicator
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatStatusIndicator(
              status: AgentStatus.uninitialized,
            ),
          ),
        ),
      );

      // WHEN: Widget is rendered
      await tester.pumpAndSettle();

      // THEN: Shows correct icon and tooltip
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.byTooltip('Uninitialized'), findsOneWidget);
    });

    testWidgets('displays correct icon and color for initializing status',
        (WidgetTester tester) async {
      // GIVEN: Initializing status indicator
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatStatusIndicator(
              status: AgentStatus.initializing,
            ),
          ),
        ),
      );

      // WHEN: Widget is rendered
      await tester.pumpAndSettle();

      // THEN: Shows correct icon and tooltip
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.byTooltip('Initializing'), findsOneWidget);
    });

    testWidgets('displays correct icon and color for ready status',
        (WidgetTester tester) async {
      // GIVEN: Ready status indicator
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatStatusIndicator(
              status: AgentStatus.ready,
            ),
          ),
        ),
      );

      // WHEN: Widget is rendered
      await tester.pumpAndSettle();

      // THEN: Shows correct icon and tooltip
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byTooltip('Ready'), findsOneWidget);
    });

    testWidgets('displays correct icon and color for processing status',
        (WidgetTester tester) async {
      // GIVEN: Processing status indicator
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatStatusIndicator(
              status: AgentStatus.processing,
            ),
          ),
        ),
      );

      // WHEN: Widget is rendered
      await tester.pumpAndSettle();

      // THEN: Shows correct icon and tooltip
      expect(find.byIcon(Icons.autorenew), findsOneWidget);
      expect(find.byTooltip('Processing'), findsOneWidget);
    });

    testWidgets('displays correct icon and color for error status',
        (WidgetTester tester) async {
      // GIVEN: Error status indicator
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatStatusIndicator(
              status: AgentStatus.error,
            ),
          ),
        ),
      );

      // WHEN: Widget is rendered
      await tester.pumpAndSettle();

      // THEN: Shows correct icon and tooltip
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.byTooltip('Error'), findsOneWidget);
    });

    testWidgets('accepts custom size and tooltip', (WidgetTester tester) async {
      // GIVEN: Custom size and tooltip
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatStatusIndicator(
              status: AgentStatus.ready,
              size: 24.0,
              tooltip: 'Custom tooltip',
            ),
          ),
        ),
      );

      // WHEN: Widget is rendered
      await tester.pumpAndSettle();

      // THEN: Shows custom tooltip
      expect(find.byTooltip('Custom tooltip'), findsOneWidget);

      // Find the Icon widget and verify its size
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(iconWidget.size, equals(24.0));
    });
  });

  group('AgentStatus enum tests', () {
    test('AgentStatus enum has all expected values', () {
      // GIVEN: AgentStatus enum

      // THEN: Contains all expected values
      expect(AgentStatus.values, contains(AgentStatus.uninitialized));
      expect(AgentStatus.values, contains(AgentStatus.initializing));
      expect(AgentStatus.values, contains(AgentStatus.ready));
      expect(AgentStatus.values, contains(AgentStatus.processing));
      expect(AgentStatus.values, contains(AgentStatus.error));
    });

    test('AgentStatus display names are correct', () {
      // GIVEN: AgentStatus values

      // THEN: Display names are correct
      expect(AgentStatus.uninitialized.displayName, equals('Uninitialized'));
      expect(AgentStatus.initializing.displayName, equals('Initializing'));
      expect(AgentStatus.ready.displayName, equals('Ready'));
      expect(AgentStatus.processing.displayName, equals('Processing'));
      expect(AgentStatus.error.displayName, equals('Error'));
    });
  });
}
