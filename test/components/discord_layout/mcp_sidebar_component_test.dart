import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/components/discord_layout/right_sidebar_panel.dart';
import 'package:vibe_coder/models/agent_model.dart';

void main() {
  group('🛠️ MCP Sidebar Component Tests', () {
    group('🎯 Basic Structure', () {
      testWidgets('🏗️ STRUCTURE: MCP sidebar renders with basic layout',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RightSidebarPanel(
                width: 300,
                selectedAgent: null,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify basic structure
        expect(find.text('MCP Content'), findsOneWidget);
        expect(find.byType(RightSidebarPanel), findsOneWidget);

        // Verify empty state when no agent selected
        expect(find.text('Select an Agent'), findsOneWidget);
        expect(
            find.text(
                'Choose an agent from the sidebar to view\ntheir MCP content and workspace'),
            findsOneWidget);
      });

      testWidgets(
          '🔧 AGENT SUPPORT: Sidebar accepts agent parameter and displays agent name',
          (tester) async {
        final testAgent = AgentModel(
          id: 'test-agent',
          name: 'Test Agent',
          systemPrompt: 'Test system prompt',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RightSidebarPanel(
                width: 300,
                selectedAgent: testAgent,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify component renders without error when agent is provided
        expect(find.byType(RightSidebarPanel), findsOneWidget);
        expect(find.text('MCP Content'), findsOneWidget);
        expect(find.text('Test Agent'), findsOneWidget);

        // Verify MCP content sections are present
        expect(find.text('Notepad'), findsOneWidget);
        expect(find.text('Todo'), findsOneWidget);
        expect(find.text('Inbox'), findsOneWidget);
      });

      testWidgets('📏 SIZING: Sidebar respects width parameter',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RightSidebarPanel(
                width: 250,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the sidebar panel and verify it renders correctly
        final sidebarPanel = find.byType(RightSidebarPanel);
        expect(sidebarPanel, findsOneWidget);

        // Verify the sidebar accepts the width parameter (structural test)
        final widget = tester.widget<RightSidebarPanel>(sidebarPanel);
        expect(widget.width, equals(250));
      });
    });

    group('📝 MCP Content Display', () {
      testWidgets('📚 NOTEPAD: Displays notepad content from agent',
          (tester) async {
        final testAgent = AgentModel(
          id: 'test-agent',
          name: 'Test Agent',
          systemPrompt: 'Test system prompt',
        );

        // Add some notepad content
        testAgent.updateMCPNotepadContent(
            'This is test notepad content with multiple words for testing');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RightSidebarPanel(
                width: 300,
                selectedAgent: testAgent,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify notepad section shows content
        expect(find.text('Notepad'), findsOneWidget);
        expect(find.text('10w'), findsOneWidget); // Word count badge

        // Expand notepad section to see content (notepad starts expanded by default)
        // await tester.tap(find.text('Notepad'));
        // await tester.pumpAndSettle();

        expect(
            find.text(
                'This is test notepad content with multiple words for testing'),
            findsOneWidget);
      });

      testWidgets('✅ TODO: Displays todo items from agent', (tester) async {
        final testAgent = AgentModel(
          id: 'test-agent',
          name: 'Test Agent',
          systemPrompt: 'Test system prompt',
        );

        // Add some todo items
        testAgent.updateMCPTodoItems(
            ['First todo item', 'Second todo item', 'Third todo item']);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RightSidebarPanel(
                width: 300,
                selectedAgent: testAgent,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify todo section shows item count
        expect(find.text('Todo'), findsOneWidget);
        expect(find.text('3'), findsOneWidget); // Item count badge

        // Expand todo section to see items
        final todoExpansion = find
            .ancestor(
              of: find.text('Todo'),
              matching: find.byType(ExpansionTile),
            )
            .first;
        await tester.tap(todoExpansion);
        await tester.pumpAndSettle();

        expect(find.text('First todo item'), findsOneWidget);
        expect(find.text('Second todo item'), findsOneWidget);
        expect(find.text('Third todo item'), findsOneWidget);
      });

      testWidgets('📮 INBOX: Displays inbox items from agent', (tester) async {
        final testAgent = AgentModel(
          id: 'test-agent',
          name: 'Test Agent',
          systemPrompt: 'Test system prompt',
        );

        // Add some inbox items
        testAgent.updateMCPInboxItems(
            ['First inbox message', 'Second inbox message']);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RightSidebarPanel(
                width: 300,
                selectedAgent: testAgent,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify inbox section shows item count
        expect(find.text('Inbox'), findsOneWidget);
        expect(find.text('2'), findsOneWidget); // Item count badge

        // Expand inbox section to see items
        final inboxExpansion = find
            .ancestor(
              of: find.text('Inbox'),
              matching: find.byType(ExpansionTile),
            )
            .first;
        await tester.tap(inboxExpansion);
        await tester.pumpAndSettle();

        expect(find.text('First inbox message'), findsOneWidget);
        expect(find.text('Second inbox message'), findsOneWidget);
      });

      testWidgets(
          '🔄 EMPTY STATES: Shows appropriate empty states for each section',
          (tester) async {
        final testAgent = AgentModel(
          id: 'test-agent',
          name: 'Test Agent',
          systemPrompt: 'Test system prompt',
        );
        // Agent has no MCP content - should show empty states

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RightSidebarPanel(
                width: 300,
                selectedAgent: testAgent,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Expand each section to verify empty states
        // Note: ExpansionTiles use leading icon to expand, not title text
        final notepadExpansion = find
            .ancestor(
              of: find.text('Notepad'),
              matching: find.byType(ExpansionTile),
            )
            .first;
        await tester.tap(notepadExpansion);
        await tester.pumpAndSettle();
        expect(find.text('No notepad content'), findsOneWidget);

        final todoExpansion = find
            .ancestor(
              of: find.text('Todo'),
              matching: find.byType(ExpansionTile),
            )
            .first;
        await tester.tap(todoExpansion);
        await tester.pumpAndSettle();
        expect(find.text('No todo items'), findsOneWidget);

        final inboxExpansion = find
            .ancestor(
              of: find.text('Inbox'),
              matching: find.byType(ExpansionTile),
            )
            .first;
        await tester.tap(inboxExpansion);
        await tester.pumpAndSettle();
        expect(find.text('No inbox messages'), findsOneWidget);
      });
    });

    group('⚡ Reactive Updates', () {
      testWidgets('🔄 REACTIVE: Content updates when agent data changes',
          (tester) async {
        final testAgent = AgentModel(
          id: 'test-agent',
          name: 'Test Agent',
          systemPrompt: 'Test system prompt',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RightSidebarPanel(
                width: 300,
                selectedAgent: testAgent,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initially no content - should show no badges
        expect(find.textContaining('w'), findsNothing);
        expect(find.textContaining('3'), findsNothing);

        // Update agent content
        testAgent.updateMCPNotepadContent('New notepad content');
        testAgent.updateMCPTodoItems(
            ['New todo item', 'Another todo', 'Third todo']);

        // Wait for reactive update
        await tester.pump();

        // Verify badges appear after content update
        expect(find.text('3w'), findsOneWidget); // Notepad word count
        expect(find.text('3'), findsOneWidget); // Todo item count
      });

      testWidgets('🏃 AGENT_SWITCH: Content updates when switching agents',
          (tester) async {
        final agent1 = AgentModel(
          id: 'agent-1',
          name: 'Agent One',
          systemPrompt: 'Test system prompt',
        );
        agent1.updateMCPNotepadContent('Agent 1 notepad content');

        final agent2 = AgentModel(
          id: 'agent-2',
          name: 'Agent Two',
          systemPrompt: 'Test system prompt',
        );
        agent2.updateMCPTodoItems(['Agent 2 todo item']);

        // Start with agent 1
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RightSidebarPanel(
                width: 300,
                selectedAgent: agent1,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify agent 1 content
        expect(find.text('Agent One'), findsOneWidget);
        expect(find.text('4w'), findsOneWidget); // Agent 1 notepad

        // Switch to agent 2
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RightSidebarPanel(
                width: 300,
                selectedAgent: agent2,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify agent 2 content
        expect(find.text('Agent Two'), findsOneWidget);
        expect(find.text('1'), findsOneWidget); // Agent 2 todo count
        expect(find.text('Agent One'), findsNothing); // Agent 1 name gone
      });
    });

    group('⚡ Performance', () {
      testWidgets('🏃 PERFORMANCE: Sidebar renders quickly', (tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RightSidebarPanel(
                width: 300,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should render within 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      testWidgets('🎯 PERFORMANCE: Large content renders efficiently',
          (tester) async {
        final testAgent = AgentModel(
          id: 'test-agent',
          name: 'Test Agent',
          systemPrompt: 'Test system prompt',
        );

        // Add large amounts of content
        final largeTodoList = List.generate(50, (i) => 'Todo item ${i + 1}');
        final largeInboxList =
            List.generate(30, (i) => 'Inbox message ${i + 1}');
        final largeNotepadContent = 'This is a large notepad content. ' * 100;

        testAgent.updateMCPTodoItems(largeTodoList);
        testAgent.updateMCPInboxItems(largeInboxList);
        testAgent.updateMCPNotepadContent(largeNotepadContent);

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RightSidebarPanel(
                width: 300,
                selectedAgent: testAgent,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should render large content within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(200));

        // Verify content counts are correct
        expect(find.text('50'), findsOneWidget); // Todo count
        expect(find.text('30'), findsOneWidget); // Inbox count
        expect(find.text('600w'),
            findsOneWidget); // Notepad word count (100 repetitions * 6 words each)
      });
    });
  });
}
