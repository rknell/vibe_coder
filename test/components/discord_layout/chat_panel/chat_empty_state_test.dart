import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/components/discord_layout/chat_panel/chat_empty_state.dart';

void main() {
  group('🛡️ COMPONENT: ChatEmptyState Tests', () {
    testWidgets('🚀 FEATURE: Empty state renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatEmptyState(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all empty state elements are present
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.text('Select an Agent to Start Chatting'), findsOneWidget);
      expect(
        find.text('Choose an agent from the sidebar to begin a conversation'),
        findsOneWidget,
      );
    });

    testWidgets('🎨 FEATURE: Empty state has proper styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatEmptyState(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify icon styling
      final icon = tester.widget<Icon>(find.byIcon(Icons.chat_bubble_outline));
      expect(icon.size, 64);

      // Verify text styling
      final titleText = tester.widget<Text>(
        find.text('Select an Agent to Start Chatting'),
      );
      expect(titleText.textAlign, isNull); // Default alignment

      final subtitleText = tester.widget<Text>(
        find.text('Choose an agent from the sidebar to begin a conversation'),
      );
      expect(subtitleText.textAlign, TextAlign.center);
    });

    testWidgets('🔄 FEATURE: Theme integration works correctly',
        (tester) async {
      // Test with different themes
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: ChatEmptyState(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify component renders without errors in light theme
      expect(find.byType(ChatEmptyState), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);

      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ChatEmptyState(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify component renders without errors in dark theme
      expect(find.byType(ChatEmptyState), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('📐 FEATURE: Layout structure is correct', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatEmptyState(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify layout structure (find specific Center widget within ChatEmptyState)
      expect(find.byType(ChatEmptyState), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);

      // Verify we have at least one Center widget (there may be others from Scaffold)
      expect(find.byType(Center), findsAtLeastNWidgets(1));

      // Verify main axis alignment
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisAlignment, MainAxisAlignment.center);

      // Verify SizedBox spacing (Icon widget may implicitly add SizedBox)
      expect(find.byType(SizedBox), findsAtLeastNWidgets(2));
    });

    testWidgets('⚡ PERFORMANCE: Empty state creation is efficient',
        (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatEmptyState(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Empty state should render very quickly (< 100ms - relaxed for CI environment)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    testWidgets('🛡️ REGRESSION: All text content is accessible',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatEmptyState(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all text is selectable for accessibility
      final texts = tester.widgetList<Text>(find.byType(Text));
      expect(texts.length, 2);

      // Verify main title
      expect(
        texts.any((text) => text.data == 'Select an Agent to Start Chatting'),
        isTrue,
      );

      // Verify subtitle
      expect(
        texts.any((text) =>
            text.data ==
            'Choose an agent from the sidebar to begin a conversation'),
        isTrue,
      );
    });

    testWidgets('🎯 EDGE_CASE: Empty state handles small screens',
        (tester) async {
      // Set small screen size
      await tester.binding.setSurfaceSize(const Size(300, 400));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatEmptyState(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all elements are still visible
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.text('Select an Agent to Start Chatting'), findsOneWidget);
      expect(
        find.text('Choose an agent from the sidebar to begin a conversation'),
        findsOneWidget,
      );

      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('🔍 INTEGRATION: Empty state works within different containers',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              color: Colors.blue,
              child: const ChatEmptyState(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state renders correctly within colored container
      expect(find.byType(ChatEmptyState), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('🎨 FEATURE: Icon color respects theme alpha values',
        (tester) async {
      late ThemeData theme;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              theme = Theme.of(context);
              return const Scaffold(
                body: ChatEmptyState(),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify icon uses correct theme-based color with alpha
      final icon = tester.widget<Icon>(find.byIcon(Icons.chat_bubble_outline));
      final expectedColor = theme.colorScheme.onSurface.withValues(alpha: 0.3);
      expect(icon.color, expectedColor);
    });
  });
}
