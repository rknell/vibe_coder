import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/components/agents/agent_sidebar_component.dart';
import 'package:vibe_coder/components/agents/agent_list_item.dart';
import 'package:vibe_coder/components/agents/agent_status_indicator.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/services/services.dart';
import 'package:vibe_coder/services/agent_service.dart';
import 'package:vibe_coder/services/layout_service.dart';
import 'package:vibe_coder/services/mcp_service.dart';
import 'package:vibe_coder/services/mcp_content_service.dart';
import 'package:vibe_coder/services/debug_logger.dart';
import 'package:vibe_coder/services/configuration_service.dart';

class MockAgentService extends ChangeNotifier implements AgentService {
  @override
  List<AgentModel> data = [];

  @override
  bool get isInitialized => true;

  @override
  List<AgentModel> get allAgents => data;

  @override
  List<AgentModel> get activeAgents => data.where((a) => a.isActive).toList();

  @override
  int get agentCount => data.length;

  void addAgent(AgentModel agent) {
    data.add(agent);
    notifyListeners();
  }

  void clearAgents() {
    data.clear();
    notifyListeners();
  }

  // Implement required abstract methods with correct signatures
  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadAll() async {}

  @override
  AgentModel? getById(String id) => data
      .cast<AgentModel?>()
      .firstWhere((a) => a?.id == id, orElse: () => null);

  @override
  AgentModel? getByName(String name) => data
      .cast<AgentModel?>()
      .firstWhere((a) => a?.name == name, orElse: () => null);

  @override
  Future<AgentModel> createAgent({
    required String name,
    required String systemPrompt,
    String notepad = '',
    bool isActive = true,
    bool isProcessing = false,
    double temperature = 0.7,
    int maxTokens = 4000,
    bool useBetaFeatures = false,
    bool useReasonerModel = false,
    String? mcpConfigPath,
    String? supervisorId,
    List<String>? contextFiles,
    List<String>? toDoList,
    List<dynamic>? conversationHistory,
    Map<String, dynamic>? metadata,
  }) async {
    final agent = AgentModel(
      name: name,
      systemPrompt: systemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    addAgent(agent);
    return agent;
  }

  // Fix: Match the actual AgentService.updateAgent signature
  @override
  Future<void> updateAgent(
    String agentId, {
    String? name,
    String? systemPrompt,
    bool? isActive,
    bool? isProcessing,
    double? temperature,
    int? maxTokens,
    bool? useBetaFeatures,
    bool? useReasonerModel,
    String? mcpConfigPath,
    String? supervisorId,
  }) async {
    notifyListeners();
  }

  // Fix: Match the actual AgentService.deleteAgent signature
  @override
  Future<void> deleteAgent(String agentId) async {
    data.removeWhere((agent) => agent.id == agentId);
    notifyListeners();
  }

  // Other required methods with basic implementations
  void rebuildIndex() {}

  Future<void> loadAgents() async {}

  Future<void> saveAgent(AgentModel agent) async {}

  Future<void> saveAllAgents() async {}

  void ensureInitialized() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockServices implements Services {
  @override
  final AgentService agentService = MockAgentService();

  // Fix: Return proper service instances instead of dynamic
  @override
  LayoutService get layoutService => throw UnimplementedError();

  @override
  MCPService get mcpService => throw UnimplementedError();

  @override
  MCPContentService get mcpContentService => throw UnimplementedError();

  @override
  DebugLogger get debugLogger => throw UnimplementedError();

  @override
  ConfigurationService get configurationService => throw UnimplementedError();

  @override
  void dispose() {
    // Mock dispose - no cleanup needed
  }

  @override
  Future<void> initialize() async {
    // Mock initialize - no setup needed
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('🛡️ REGRESSION: AgentSidebarComponent Tests', () {
    late MockServices mockServices;

    setUpAll(() {
      // Use the proper mock services registration
      mockServices = MockServices();
      registerMockServices(mockServices);
    });

    tearDownAll(() {
      resetServices();
    });

    group('✅ AGENT LIST RENDERING', () {
      testWidgets('renders empty state when no agents exist', (tester) async {
        // SETUP: Clear agents
        (mockServices.agentService as MockAgentService).clearAgents();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AgentSidebarComponent(
                width: 250,
                onCreateAgent: () {},
              ),
            ),
          ),
        );

        // VERIFY: Empty state elements present
        expect(find.text('No Agents Yet'), findsOneWidget);
        expect(find.text('Create your first AI agent to get started'),
            findsOneWidget);
        expect(find.byIcon(Icons.people_outline), findsOneWidget);
        expect(find.text('Create Agent'), findsOneWidget);
      });

      testWidgets('renders agent list when agents exist', (tester) async {
        // SETUP: Add test agents
        final mockAgentService = mockServices.agentService as MockAgentService;
        mockAgentService.clearAgents();

        final agent1 =
            AgentModel(name: 'Test Agent 1', systemPrompt: 'Test prompt 1');
        final agent2 =
            AgentModel(name: 'Test Agent 2', systemPrompt: 'Test prompt 2');

        mockAgentService.addAgent(agent1);
        mockAgentService.addAgent(agent2);

        // DEBUG: Verify agents were added
        expect(mockAgentService.data.length, equals(2));
        expect(mockAgentService.data[0].name, equals('Test Agent 1'));
        expect(mockAgentService.data[1].name, equals('Test Agent 2'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AgentSidebarComponent(
                width: 250,
                onCreateAgent: () {},
              ),
            ),
          ),
        );

        // CRITICAL: Allow ListenableBuilder to update after data change
        await tester.pump();
        await tester.pump(Duration.zero); // Extra pump to ensure updates

        // VERIFY: Agent list items present
        expect(find.byType(AgentListItem), findsNWidgets(2));
        expect(find.text('Test Agent 1'), findsOneWidget);
        expect(find.text('Test Agent 2'), findsOneWidget);
        expect(find.text('Create Agent'), findsOneWidget);
      });
    });

    group('✅ AGENT SELECTION', () {
      testWidgets('highlights selected agent correctly', (tester) async {
        // SETUP: Add test agent
        final mockAgentService = mockServices.agentService as MockAgentService;
        mockAgentService.clearAgents();

        final agent =
            AgentModel(name: 'Selected Agent', systemPrompt: 'Test prompt');
        mockAgentService.addAgent(agent);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AgentSidebarComponent(
                width: 250,
                selectedAgent: agent, // This agent should be highlighted
                onCreateAgent: () {},
              ),
            ),
          ),
        );

        await tester.pump(); // Allow ListenableBuilder to update

        // VERIFY: Agent is rendered and appears selected
        expect(find.byType(AgentListItem), findsOneWidget);

        // Get the AgentListItem widget to verify selection state
        final agentListItem =
            tester.widget<AgentListItem>(find.byType(AgentListItem));
        expect(agentListItem.isSelected, isTrue);
        expect(agentListItem.agent.id, equals(agent.id));
      });

      testWidgets('calls onAgentSelected when agent is tapped', (tester) async {
        // SETUP: Add test agent and selection callback
        final mockAgentService = mockServices.agentService as MockAgentService;
        mockAgentService.clearAgents();

        final agent =
            AgentModel(name: 'Tappable Agent', systemPrompt: 'Test prompt');
        mockAgentService.addAgent(agent);

        AgentModel? selectedAgent;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AgentSidebarComponent(
                width: 250,
                onAgentSelected: (agent) => selectedAgent = agent,
                onCreateAgent: () {},
              ),
            ),
          ),
        );

        await tester.pump(); // Allow ListenableBuilder to update

        // ACTION: Tap the agent item
        await tester.tap(find.byType(AgentListItem));
        await tester.pump();

        // VERIFY: Selection callback was called with correct agent
        expect(selectedAgent, isNotNull);
        expect(selectedAgent!.id, equals(agent.id));
        expect(selectedAgent!.name, equals('Tappable Agent'));
      });
    });

    group('✅ STATUS INDICATORS', () {
      testWidgets('displays agent status indicators correctly', (tester) async {
        // SETUP: Add agents with different statuses
        final mockAgentService = mockServices.agentService as MockAgentService;
        mockAgentService.clearAgents();

        final idleAgent = AgentModel(name: 'Idle Agent', systemPrompt: 'Test');
        final processingAgent =
            AgentModel(name: 'Processing Agent', systemPrompt: 'Test');
        final errorAgent =
            AgentModel(name: 'Error Agent', systemPrompt: 'Test');

        // Set different statuses
        idleAgent.setIdleStatus();
        processingAgent.setProcessingStatus();
        errorAgent.setErrorStatus('Test error');

        mockAgentService.addAgent(idleAgent);
        mockAgentService.addAgent(processingAgent);
        mockAgentService.addAgent(errorAgent);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AgentSidebarComponent(
                width: 250,
                onCreateAgent: () {},
              ),
            ),
          ),
        );

        await tester.pump(); // Allow ListenableBuilder to update

        // VERIFY: Status indicators are present
        expect(find.byType(AgentStatusIndicator), findsNWidgets(3));

        // VERIFY: Different agent items are displayed
        expect(find.text('Idle Agent'), findsOneWidget);
        expect(find.text('Processing Agent'), findsOneWidget);
        expect(find.text('Error Agent'), findsOneWidget);
      });
    });

    group('✅ CREATE AGENT INTEGRATION', () {
      testWidgets('calls onCreateAgent when create button pressed',
          (tester) async {
        // SETUP: Empty agent list and create callback
        final mockAgentService = mockServices.agentService as MockAgentService;
        mockAgentService.clearAgents();

        bool createAgentCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AgentSidebarComponent(
                width: 250,
                onCreateAgent: () => createAgentCalled = true,
              ),
            ),
          ),
        );

        // ACTION: Tap create agent button
        await tester.tap(find.text('Create Agent'));
        await tester.pump();

        // VERIFY: Create callback was called
        expect(createAgentCalled, isTrue);
      });

      testWidgets('create button present in both empty and populated states',
          (tester) async {
        final mockAgentService = mockServices.agentService as MockAgentService;

        // TEST 1: Empty state
        mockAgentService.clearAgents();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AgentSidebarComponent(
                width: 250,
                onCreateAgent: () {},
              ),
            ),
          ),
        );

        expect(find.text('Create Agent'), findsOneWidget);

        // TEST 2: Populated state
        final agent = AgentModel(name: 'Test Agent', systemPrompt: 'Test');
        mockAgentService.addAgent(agent);

        await tester.pump(); // Allow ListenableBuilder to update

        expect(find.text('Create Agent'), findsOneWidget);
      });
    });

    group('🚀 PERFORMANCE: Reactive Updates', () {
      testWidgets('updates UI when agent service data changes', (tester) async {
        // SETUP: Start with empty agents
        final mockAgentService = mockServices.agentService as MockAgentService;
        mockAgentService.clearAgents();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AgentSidebarComponent(
                width: 250,
                onCreateAgent: () {},
              ),
            ),
          ),
        );

        // VERIFY: Initially empty
        expect(find.text('No Agents Yet'), findsOneWidget);
        expect(find.byType(AgentListItem), findsNothing);

        // ACTION: Add agent to service
        final agent = AgentModel(name: 'Dynamic Agent', systemPrompt: 'Test');
        mockAgentService.addAgent(agent);

        await tester.pump(); // Allow ListenableBuilder to react to change

        // VERIFY: UI updated to show agent
        expect(find.text('No Agents Yet'), findsNothing);
        expect(find.byType(AgentListItem), findsOneWidget);
        expect(find.text('Dynamic Agent'), findsOneWidget);
      });
    });
  });
}
