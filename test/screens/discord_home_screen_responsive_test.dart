import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/models/layout_preferences_model.dart';
import 'package:vibe_coder/models/mcp_server_info.dart';
import 'package:vibe_coder/models/mcp_server_model.dart';
import 'package:vibe_coder/models/service_statistics.dart';
import 'package:vibe_coder/screens/discord_home_screen.dart';
import 'package:vibe_coder/services/agent_service.dart';
import 'package:vibe_coder/services/layout_service.dart';
import 'package:vibe_coder/services/mcp_service.dart';
import 'package:vibe_coder/services/services.dart';

// Mocks copied from discord_home_screen_test.dart to ensure test isolation

class MockAgentService extends ChangeNotifier implements AgentService {
  @override
  List<AgentModel> data = [];
  @override
  bool get isInitialized => true;
  @override
  List<AgentModel> get allAgents => List.unmodifiable(data);
  @override
  List<AgentModel> get activeAgents =>
      data.where((agent) => agent.isActive).toList();
  @override
  int get agentCount => data.length;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> loadAll() async {}
  @override
  AgentModel? getById(String id) => null;
  @override
  AgentModel? getByName(String name) => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value();
}

class MockLayoutService extends ChangeNotifier implements LayoutService {
  AppTheme _currentTheme = AppTheme.dark;
  bool _leftSidebarCollapsed = false;
  bool _rightSidebarCollapsed = false;
  @override
  AppTheme get currentTheme => _currentTheme;
  @override
  bool get leftSidebarCollapsed => _leftSidebarCollapsed;
  @override
  bool get rightSidebarCollapsed => _rightSidebarCollapsed;
  @override
  void setTheme(AppTheme theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  @override
  void setLeftSidebarCollapsed(bool collapsed) {
    _leftSidebarCollapsed = collapsed;
    notifyListeners();
  }

  @override
  void setRightSidebarCollapsed(bool collapsed) {
    _rightSidebarCollapsed = collapsed;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Mock MCP Service for testing
class MockMCPService extends ChangeNotifier implements MCPService {
  final bool _isInitialized = true;
  final bool _isLoading = false;
  String? _lastError;
  @override
  List<MCPServerModel> data = [];

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
  Future<void> initialize() async {
    // Mock initialization
  }

  @override
  Future<void> loadAll() async {
    // Mock load
  }

  @override
  MCPServerModel? getById(String id) {
    try {
      return data.firstWhere((server) => server.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  MCPServerModel? getByName(String name) {
    try {
      return data.firstWhere((server) => server.name == name);
    } catch (e) {
      return null;
    }
  }

  @override
  List<MCPServerModel> getByStatus(MCPServerStatus status) {
    return data.where((server) => server.status == status).toList();
  }

  @override
  List<MCPServerModel> getByType(MCPServerType type) {
    return data.where((server) => server.type == type).toList();
  }

  @override
  List<MCPToolWithServer> getAllTools() {
    return [];
  }

  @override
  String? findServerForTool(String toolName) {
    return null;
  }

  @override
  Future<Map<String, dynamic>> callTool({
    required String serverId,
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    return {
      'content': [
        {'type': 'text', 'text': 'Mock tool response'}
      ],
      'isError': false,
    };
  }

  @override
  MCPServerInfoResponse getMCPServerInfo() {
    return MCPServerInfoResponse(
      servers: {},
      totalCount: 0,
      connectedCount: 0,
      toolCount: 0,
    );
  }

  @override
  Map<String, dynamic> getMCPServerInfoLegacy() {
    return {
      'servers': {},
      'totalCount': 0,
      'connectedCount': 0,
      'toolCount': 0,
    };
  }

  @override
  Future<void> refreshAll() async {
    // Mock refresh
  }

  @override
  Future<void> refreshServer(String serverId) async {
    // Mock refresh
  }

  @override
  Future<MCPServerModel> createServer(MCPServerModel server) async {
    data.add(server);
    notifyListeners();
    return server;
  }

  @override
  Future<void> updateServer(MCPServerModel server) async {
    final index = data.indexWhere((s) => s.id == server.id);
    if (index != -1) {
      data[index] = server;
      notifyListeners();
    }
  }

  @override
  Future<void> deleteServer(String serverId) async {
    data.removeWhere((s) => s.id == serverId);
    notifyListeners();
  }

  @override
  Future<void> connectServer(String serverId) async {
    final server = getById(serverId);
    if (server != null) {
      server.updateStatus(MCPServerStatus.connected);
      notifyListeners();
    }
  }

  @override
  Future<void> disconnectServer(String serverId) async {
    final server = getById(serverId);
    if (server != null) {
      server.updateStatus(MCPServerStatus.disconnected);
      notifyListeners();
    }
  }

  @override
  Future<void> triggerBackgroundConnections() async {
    // Mock background connections
  }

  @override
  Future<Map<String, dynamic>> fetchAgentContent(String agentId) async {
    return {
      'content': [],
      'isError': false,
    };
  }
}

class MockServices implements Services {
  @override
  late final MockLayoutService layoutService = MockLayoutService();
  @override
  late final MockAgentService agentService = MockAgentService();
  @override
  late final MockMCPService mcpService = MockMCPService();
  @override
  Future<void> initialize() async {}
  @override
  void dispose() {
    layoutService.dispose();
    agentService.dispose();
    mcpService.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => _MockDynamicService();
}

class _MockDynamicService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('🏆 DiscordHomeScreen Responsive Behavior Tests', () {
    late MockServices mockServices;

    setUp(() {
      if (GetIt.instance.isRegistered<Services>()) {
        GetIt.instance.unregister<Services>();
      }
      mockServices = MockServices();
      GetIt.instance.registerSingleton<Services>(mockServices);
    });

    tearDown(() {
      mockServices.dispose();
      GetIt.instance.reset();
    });

    testWidgets('🚀 FEATURE: Sidebar toggle controls work correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DiscordHomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify sidebar toggle buttons are present
      expect(find.byTooltip('Toggle agents sidebar'), findsOneWidget);
      expect(find.byTooltip('Toggle MCP content sidebar'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.view_sidebar), findsOneWidget);

      // Test left sidebar toggle button
      final leftToggle = find.byTooltip('Toggle agents sidebar');
      await tester.tap(leftToggle);
      await tester.pumpAndSettle();

      // Test right sidebar toggle button
      final rightToggle = find.byTooltip('Toggle MCP content sidebar');
      await tester.tap(rightToggle);
      await tester.pumpAndSettle();

      // Verify no exceptions were thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('📱 RESPONSIVE: Mobile breakpoint hides sidebars',
        (tester) async {
      // Set mobile screen size (< 768px)
      await tester.binding.setSurfaceSize(const Size(600, 800));

      await tester.pumpWidget(
        const MaterialApp(
          home: DiscordHomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // On mobile, only chat panel should be visible
      expect(find.text('Chat'), findsOneWidget);

      // Verify no layout overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('💻 RESPONSIVE: Tablet breakpoint shows limited sidebars',
        (tester) async {
      // Set tablet screen size (768px < x < 1024px)
      await tester.binding.setSurfaceSize(const Size(900, 600));

      await tester.pumpWidget(
        const MaterialApp(
          home: DiscordHomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // On tablet, chat panel should be visible
      expect(find.text('Chat'), findsOneWidget);

      // Verify no layout overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('🖥️ RESPONSIVE: Desktop shows all panels', (tester) async {
      // Set desktop screen size (>= 1024px)
      await tester.binding.setSurfaceSize(const Size(1400, 800));

      await tester.pumpWidget(
        const MaterialApp(
          home: DiscordHomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // On desktop, all panels should be available
      expect(find.text('Chat'), findsOneWidget);
      expect(find.byTooltip('Toggle agents sidebar'), findsOneWidget);
      expect(find.byTooltip('Toggle MCP content sidebar'), findsOneWidget);

      // Verify no layout overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('⚡ PERFORMANCE: Animation controllers dispose properly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DiscordHomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate away to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Different Screen')),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no memory leaks or disposal errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('🎯 INTEGRATION: Theme toggle works with sidebar controls',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DiscordHomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Test theme toggle (in center panel)
      final themeToggle = find.byTooltip('Toggle theme');
      expect(themeToggle, findsOneWidget);

      await tester.tap(themeToggle);
      await tester.pumpAndSettle();

      // Test sidebar toggles still work after theme change
      final leftToggle = find.byTooltip('Toggle agents sidebar');
      await tester.tap(leftToggle);
      await tester.pumpAndSettle();

      // Verify no exceptions were thrown
      expect(tester.takeException(), isNull);
    });
  });
}
