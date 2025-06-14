import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/components/common/indicators/chat_status_indicator.dart';
import 'package:vibe_coder/services/chat_service.dart';

void main() {
  group('ChatStatusIndicator Tests', () {
    testWidgets('renders correctly with uninitialized state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatStatusIndicator(
              serviceState: ChatServiceState.uninitialized,
            ),
          ),
        ),
      );

      expect(find.byType(ChatStatusIndicator), findsOneWidget);
      expect(find.text('UNINITIALIZED'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders correctly with initializing state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatStatusIndicator(
              serviceState: ChatServiceState.initializing,
            ),
          ),
        ),
      );

      expect(find.byType(ChatStatusIndicator), findsOneWidget);
      expect(find.text('INITIALIZING'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders correctly with ready state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatStatusIndicator(
              serviceState: ChatServiceState.ready,
            ),
          ),
        ),
      );

      expect(find.byType(ChatStatusIndicator), findsOneWidget);
      expect(find.text('READY'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders correctly with processing state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatStatusIndicator(
              serviceState: ChatServiceState.processing,
            ),
          ),
        ),
      );

      expect(find.byType(ChatStatusIndicator), findsOneWidget);
      expect(find.text('PROCESSING'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders correctly with error state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatStatusIndicator(
              serviceState: ChatServiceState.error,
            ),
          ),
        ),
      );

      expect(find.byType(ChatStatusIndicator), findsOneWidget);
      expect(find.text('ERROR'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('uses proper styling and layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatStatusIndicator(
              serviceState: ChatServiceState.ready,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('READY'),
          matching: find.byType(Container),
        ),
      );

      expect(container.padding,
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4));
      expect(container.decoration, isA<BoxDecoration>());

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisSize, MainAxisSize.min);
    });
  });
}
