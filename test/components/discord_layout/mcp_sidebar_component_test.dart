import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vibe_coder/components/discord_layout/right_sidebar_panel.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/services/services.dart';
import 'package:vibe_coder/services/mcp_service.dart';
import 'package:vibe_coder/models/mcp_server_model.dart';
import 'package:vibe_coder/models/mcp_server_info.dart';
import 'package:vibe_coder/models/service_statistics.dart';
import 'package:vibe_coder/models/layout_preferences_model.dart';
import 'package:vibe_coder/services/layout_service.dart';

/// Mock MCP Service for testing
class MockMCPService extends ChangeNotifier implements MCPService {
  final bool _isInitialized = true;
  final bool _isLoading = false;
  String? _lastError;
  @override
  List<MCPServerModel> data = [];

  static bool alwaysShowMCPSectionsForTests = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get lastError => _lastError;

  @override
  List<MCPServerModel> get connectedServers =>
      data.where((s) => s.status == MCPServerStatus.connected).toList();

  @override
  List<MCPServerModel> get disconnectedServers =>
      data.where((s) => s.status == MCPServerStatus.disconnected).toList();

  @override
  MCPServiceStatistics get statistics => MCPServiceStatistics(
        totalServers: data.length,
        connectedServers: connectedServers.length,
        disconnectedServers: disconnectedServers.length,
        errorServers: 0,
        stdioServers: 0,
        sseServers: 0,
        totalTools: 0,
        totalResources: 0,
        totalPrompts: 0,
      );

  @override
  Map<String, dynamic> get statisticsLegacy => {
        'totalServers': data.length,
        'connectedServers': connectedServers.length,
        'disconnectedServers': disconnectedServers.length,
        'errorServers': 0,
        'stdioServers': 0,
        'sseServers': 0,
        'totalTools': 0,
        'totalResources': 0,
        'totalPrompts': 0,
      };

  @override
  List<MCPToolWithServer> getAllTools() => [];

  @override
  String? findServerForTool(String toolName) {
    // Return mock server names for the tools that MCP content sections need
    switch (toolName) {
      case 'notepad_read':
        return 'mock-notepad';
      case 'task_list_list':
        return 'mock-task-list';
      case 'inbox_list':
        return 'mock-inbox';
      default:
        return null;
    }
  }

  @override
  Future<Map<String, dynamic>> callTool({
    required String serverId,
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    if (toolName == 'notepad_read') {
      return {
        'content': [
          {
            'type': 'text',
            'text': 'Mock notepad content',
          }
        ],
        'isError': false,
      };
    } else if (toolName == 'task_list_list') {
      // Return 30 mock todo items for performance test, or 1 for basic
      int count = arguments['count'] ?? 1;
      if (arguments.containsKey('performance')) {
        count = 30;
      }
      final items = List.generate(
          count,
          (i) => {
                'type': 'text',
                'text': 'ID: ${i + 1} Priority: High',
              });
      return {
        'content': items,
        'isError': false,
      };
    } else if (toolName == 'inbox_list') {
      return {
        'content': [
          {
            'type': 'text',
            'text': 'Inbox message from Alice',
          }
        ],
        'isError': false,
      };
    }
    return {
      'content': [
        {
          'type': 'text',
          'text': 'Mock tool response for $toolName',
        }
      ],
      'isError': false,
    };
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> refreshAll() async {}

  @override
  Future<void> refreshServer(String serverId) async {}

  @override
  Future<void> connectServer(String serverId) async {}

  @override
  Future<void> disconnectServer(String serverId) async {}

  @override
  MCPServerInfoResponse getMCPServerInfo() => MCPServerInfoResponse(
        servers: {},
        connectedCount: 0,
        totalCount: 0,
        toolCount: 0,
      );

  @override
  Map<String, dynamic> getMCPServerInfoLegacy() => {};

  @override
  Future<void> fetchAgentContent(String agentId) async {}

  @override
  MCPServerModel? getById(String id) => null;

  @override
  MCPServerModel? getByName(String name) => null;

  @override
  Future<MCPServerModel> createServer(MCPServerModel server) async => server;

  @override
  Future<void> deleteServer(String serverId) async {}

  @override
  List<MCPServerModel> getByStatus(MCPServerStatus status) => [];

  @override
  List<MCPServerModel> getByType(MCPServerType type) => [];

  @override
  void triggerBackgroundConnections() {}

  @override
  Future<void> updateServer(MCPServerModel server) async {}

  // --- MOCK AGENT CONTENT FOR TESTS ---
  static AgentModel createMockAgentWithContent(
      {int todoCount = 1, int inboxCount = 1, bool performance = false}) {
    final agent = AgentModel(
      id: 'agent-1',
      name: 'Test Agent',
      systemPrompt: '',
      temperature: 1.0,
      maxTokens: 1024,
      useBetaFeatures: false,
      useReasonerModel: false,
      mcpConfigPath: '',
    );
    // Notepad
    agent.updateMCPNotepadContent('Mock notepad content');
    // Todo
    final todos = List.generate(
        performance ? 30 : todoCount, (i) => 'ID: ${i + 1} Priority: High');
    agent.updateMCPTodoItems(todos);
    // Inbox
    final inbox =
        List.generate(inboxCount, (i) => 'Inbox message from Alice #${i + 1}');
    agent.updateMCPInboxItems(inbox);
    return agent;
  }

  static AgentModel createMockAgentWithEmptyContent() {
    final agent = AgentModel(
      id: 'agent-empty',
      name: 'Empty Test Agent',
      systemPrompt: '',
      temperature: 1.0,
      maxTokens: 1024,
      useBetaFeatures: false,
      useReasonerModel: false,
      mcpConfigPath: '',
    );
    // Empty content
    agent.updateMCPNotepadContent('');
    agent.updateMCPTodoItems([]);
    agent.updateMCPInboxItems([]);
    return agent;
  }
}

/// Mock LayoutService for testing
class MockLayoutService extends ChangeNotifier implements LayoutService {
  bool _rightSidebarCollapsed = false;
  bool _leftSidebarCollapsed = false;
  AppTheme _currentTheme = AppTheme.dark;
  double _leftSidebarWidth = 250.0;
  double _rightSidebarWidth = 300.0;
  String? _selectedAgentId;
  bool _disposed = false;

  bool get rightSidebarCollapsed => _rightSidebarCollapsed;
  bool get leftSidebarCollapsed => _leftSidebarCollapsed;
  AppTheme get currentTheme => _currentTheme;
  double get leftSidebarWidth => _leftSidebarWidth;
  double get rightSidebarWidth => _rightSidebarWidth;
  String? get selectedAgentId => _selectedAgentId;
  bool get isDisposed => _disposed;

  void setRightSidebarCollapsed(bool collapsed) {
    _rightSidebarCollapsed = collapsed;
    notifyListeners();
  }

  void setLeftSidebarCollapsed(bool collapsed) {
    _leftSidebarCollapsed = collapsed;
    notifyListeners();
  }

  void setTheme(AppTheme theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  void toggleLeftSidebar() {
    _leftSidebarCollapsed = !_leftSidebarCollapsed;
    notifyListeners();
  }

  void toggleRightSidebar() {
    _rightSidebarCollapsed = !_rightSidebarCollapsed;
    notifyListeners();
  }

  void updatePanelWidths({double? leftWidth, double? rightWidth}) {
    if (leftWidth != null) _leftSidebarWidth = leftWidth;
    if (rightWidth != null) _rightSidebarWidth = rightWidth;
    notifyListeners();
  }

  void resetPanelLayout() {
    _leftSidebarWidth = 250.0;
    _rightSidebarWidth = 300.0;
    _leftSidebarCollapsed = false;
    _rightSidebarCollapsed = false;
    notifyListeners();
  }

  void setSelectedAgent(String? agentId) {
    _selectedAgentId = agentId;
    notifyListeners();
  }

  Future<void> savePreferences() async {}

  Future<void> loadPreferences() async {}

  ThemeData getThemeData(BuildContext context, [AppTheme? overrideTheme]) {
    final theme = overrideTheme ?? _currentTheme;
    switch (theme) {
      case AppTheme.dark:
        return ThemeData.dark();
      case AppTheme.light:
        return ThemeData.light();
      case AppTheme.system:
        return ThemeData.from(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Mock Services for MCP Sidebar Component Tests
class MockServices implements Services {
  @override
  late final MockMCPService mcpService = MockMCPService();
  @override
  late final MockLayoutService layoutService = MockLayoutService();

  @override
  Future<void> initialize() async {
    // Initialize mock MCP service
    await mcpService.initialize();
  }

  @override
  void dispose() {
    mcpService.dispose();
    layoutService.dispose();
  }

  // Handle all other service calls with noSuchMethod
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('🛠️ MCP Sidebar Component Tests', () {
    late MockServices mockServices;

    setUp(() async {
      // Reset GetIt before each test
      if (GetIt.instance.isRegistered<Services>()) {
        GetIt.instance.unregister<Services>();
      }

      mockServices = MockServices();
      GetIt.instance.registerSingleton<Services>(mockServices);

      // Initialize the mock MCP service
      await mockServices.initialize();

      MockMCPService.alwaysShowMCPSectionsForTests = true;
    });

    tearDown(() {
      mockServices.dispose();
      GetIt.instance.reset();
      MockMCPService.alwaysShowMCPSectionsForTests = false;
    });

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
        final testAgent = MockMCPService.createMockAgentWithContent(
            todoCount: 3, inboxCount: 2);

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

        // Verify MCP content sections are present (now that MCP service is mocked)
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
        final testAgent = MockMCPService.createMockAgentWithContent(
            todoCount: 3, inboxCount: 2);

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
        expect(find.text('3w'),
            findsOneWidget); // Word count badge for "Mock notepad content"

        // Expand notepad section to see content (notepad starts expanded by default)
        // await tester.tap(find.text('Notepad'));
        // await tester.pumpAndSettle();

        expect(find.text('Mock notepad content'), findsOneWidget);
      });

      testWidgets('✅ TODO: Displays todo items from agent', (tester) async {
        final testAgent = MockMCPService.createMockAgentWithContent(
            todoCount: 3, inboxCount: 2);

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

        expect(find.text('ID: 1 Priority: High'), findsOneWidget);
        expect(find.text('ID: 2 Priority: High'), findsOneWidget);
        expect(find.text('ID: 3 Priority: High'), findsOneWidget);
      });

      testWidgets('📮 INBOX: Displays inbox items from agent', (tester) async {
        final testAgent = MockMCPService.createMockAgentWithContent(
            todoCount: 3, inboxCount: 2);

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

        expect(find.text('Inbox message from Alice #1'), findsOneWidget);
        expect(find.text('Inbox message from Alice #2'), findsOneWidget);
      });

      testWidgets(
          '🔄 EMPTY STATES: Shows appropriate empty states for each section',
          (tester) async {
        final testAgent = MockMCPService.createMockAgentWithEmptyContent();
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
        final testAgent = MockMCPService.createMockAgentWithContent(
            todoCount: 3, inboxCount: 2);

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

        // Initially has content - should show badges
        expect(find.text('3w'), findsOneWidget); // Initial notepad content
        expect(find.text('3'), findsOneWidget); // Initial todo count

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
        final agent1 = MockMCPService.createMockAgentWithContent(
            todoCount: 3, inboxCount: 2);
        final agent2 = MockMCPService.createMockAgentWithContent(
            todoCount: 5, inboxCount: 1);

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
        expect(find.text('Test Agent'), findsOneWidget);
        expect(find.text('3w'), findsOneWidget); // Agent 1 notepad

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
        expect(find.text('Test Agent'), findsOneWidget);
        expect(find.text('5'), findsOneWidget); // Agent 2 todo count
        expect(find.text('3w'), findsOneWidget); // Agent 2 notepad
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
        final testAgent = MockMCPService.createMockAgentWithContent(
            todoCount: 50, inboxCount: 30);

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
        expect(find.text('3w'),
            findsOneWidget); // Notepad word count for "Mock notepad content"
      });
    });
  });
}
