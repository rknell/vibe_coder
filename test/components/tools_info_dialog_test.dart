import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/components/common/dialogs/tools_info_dialog.dart';

void main() {
  group('ToolsInfoDialog Tests', () {
    testWidgets('renders correctly with empty tools list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolsInfoDialog(tools: []),
          ),
        ),
      );

      expect(find.byType(ToolsInfoDialog), findsOneWidget);
      expect(find.text('Available AI Tools'), findsOneWidget);
      expect(
          find.text('The AI assistant has access to 0 tools:'), findsOneWidget);
      expect(find.text('No tools currently available'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('renders correctly with tools list', (tester) async {
      const testTools = ['file_reader', 'code_generator', 'web_search'];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolsInfoDialog(tools: testTools),
          ),
        ),
      );

      expect(find.byType(ToolsInfoDialog), findsOneWidget);
      expect(find.text('Available AI Tools'), findsOneWidget);
      expect(
          find.text('The AI assistant has access to 3 tools:'), findsOneWidget);

      // Check each tool is displayed with icon
      for (final tool in testTools) {
        expect(find.text(tool), findsOneWidget);
      }

      // Check for tool icons
      expect(find.byIcon(Icons.build), findsNWidgets(testTools.length));
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('close button dismisses dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ToolsInfoDialog.show(context, ['test_tool']),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(ToolsInfoDialog), findsOneWidget);
      expect(find.text('test_tool'), findsOneWidget);

      // Tap close button
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(ToolsInfoDialog), findsNothing);
    });

    testWidgets('static show method works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    ToolsInfoDialog.show(context, ['tool1', 'tool2']),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Initially no dialog
      expect(find.byType(ToolsInfoDialog), findsNothing);

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.byType(ToolsInfoDialog), findsOneWidget);
      expect(find.text('tool1'), findsOneWidget);
      expect(find.text('tool2'), findsOneWidget);
    });

    testWidgets('dialog layout and styling is correct', (tester) async {
      const testTools = ['tool1'];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolsInfoDialog(tools: testTools),
          ),
        ),
      );

      // Check dialog structure
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));

      // Find the Column widget inside the SizedBox content (our specific content column)
      final contentColumn = find.descendant(
        of: find.byType(SizedBox),
        matching: find.byType(Column),
      );
      expect(contentColumn, findsOneWidget);

      final column = tester.widget<Column>(contentColumn);
      expect(column.mainAxisSize, MainAxisSize.min);
      expect(column.crossAxisAlignment, CrossAxisAlignment.start);

      // Check tool item row structure
      final rows = tester.widgetList<Row>(find.byType(Row));
      expect(rows.length, greaterThan(0));
    });
  });
}
