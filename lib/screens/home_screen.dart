import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/components/messaging_ui.dart';
import 'package:vibe_coder/components/agents/agent_list_component.dart';
import 'package:vibe_coder/components/agents/agent_settings_dialog.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/services/services.dart';

/// HomeScreen - Clean Architecture Agent-Centric Multi-Tab Design
///
/// ## MISSION ACCOMPLISHED
/// **ELIMINATES MULTIAGENTTCHATSERVICE ANTI-PATTERN** by implementing direct AgentModel usage.
/// Each tab maintains its own AgentModel with isolated conversation state and persistence.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | MultiAgentChatService | Centralized | Breaks Clean Architecture | ELIMINATED - violates layer separation |
/// | Direct AgentModel | Clean, isolated | Direct dependency | CHOSEN - follows Data Model Layer pattern |
/// | Service Factory | Centralized creation | Complex routing | REJECTED - unnecessary abstraction |
/// | Agent Passing | Clean architecture | Parameter threading | CHOSEN - dependency injection |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Service Layer Violation Elimination**
///    - 🔍 Symptom: MultiAgentChatService acts as conversation manager instead of factory
///    - 🎯 Root Cause: Service layer handling data model responsibilities
///    - 💥 Kill Shot: Direct AgentModel conversation with service as factory only
///
/// 2. **Single Source of Truth Achievement**
///    - 🔍 Symptom: Conversation state duplicated between service and model
///    - 🎯 Root Cause: Multiple conversation management layers
///    - 💥 Kill Shot: AgentModel as single conversation owner with persistence
///
/// 3. **Clean Architecture Compliance**
///    - 🔍 Symptom: UI depending on service for data model responsibilities
///    - 🎯 Root Cause: Inverted dependency hierarchy
///    - 💥 Kill Shot: UI → Service (factory) → Model (data + behavior)
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Agent tab creation: O(1) - direct model instantiation
/// - Tab switching: O(1) - no service state management
/// - Message sending: O(1) - direct model method call
/// - Memory usage: O(n) where n = number of open agent tabs
/// - Conversation persistence: O(1) - model handles own persistence
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Agent Tab Data - CLEAN ARCHITECTURE: Direct AgentModel reference
///
/// ARCHITECTURAL: Each tab maintains direct reference to AgentModel
/// PERF: O(1) access to conversation state via model
class AgentTab {
  final AgentModel agent;
  final StreamSubscription<ChatMessage>? messageSubscription;
  final String? error;

  const AgentTab({
    required this.agent,
    this.messageSubscription,
    this.error,
  });

  /// Create copy with updated values
  /// PERF: O(1) - immutable update pattern
  AgentTab copyWith({
    AgentModel? agent,
    StreamSubscription<ChatMessage>? messageSubscription,
    String? error,
  }) {
    return AgentTab(
      agent: agent ?? this.agent,
      messageSubscription: messageSubscription ?? this.messageSubscription,
      error: error ?? this.error,
    );
  }

  /// Get conversation messages directly from agent model
  /// PERF: O(1) - direct model access
  List<ChatMessage> get messages => agent.conversationHistory;

  /// Get processing state directly from agent model
  /// PERF: O(1) - direct model access
  bool get isProcessing => agent.isProcessing;
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // CLEAN ARCHITECTURE: Direct service usage for factory operations only
  late TabController _tabController;
  final List<AgentTab> _agentTabs = [];
  int _selectedTabIndex = 0;

  // Available agents registry - loaded from AgentService
  List<AgentModel> _availableAgents = [];

  // Service State Tracking
  bool _isLoading = false;
  String? _errorMessage;
  String? _loadingStatus;
  bool _isServiceInitialized = false;

  @override
  void initState() {
    super.initState();
    // Start with agents list tab + space for agent tabs
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initializeServices();
  }

  @override
  void dispose() {
    // Clean up all agent tab subscriptions
    for (final tab in _agentTabs) {
      tab.messageSubscription?.cancel();
      tab.agent.disposeAgent(); // Clean up agent instances
    }
    _tabController.dispose();
    super.dispose();
  }

  /// Handle tab changes
  /// PERF: O(1) - direct index tracking
  void _onTabChanged() {
    if (_tabController.index != _selectedTabIndex) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    }
  }

  /// Initialize services and load agents
  ///
  /// PERF: O(1) initialization with instant agent access
  /// ARCHITECTURAL: Clean service initialization pattern
  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
      _loadingStatus = 'Initializing services...';
      _errorMessage = null;
    });

    try {
      // Phase 1: Initialize core services
      setState(() => _loadingStatus = 'Initializing MCP infrastructure...');
      await services.initialize();

      // Phase 2: Load agents from persistence via AgentService
      setState(() => _loadingStatus = 'Loading agents...');
      await services.agentService.loadAll();

      _availableAgents = services.agentService.data;
      _isServiceInitialized = true;

      // Create default agent if none exist
      if (_availableAgents.isEmpty) {
        await _createDefaultAgent();
      }

      setState(() {
        _loadingStatus = 'Ready!';
        _isLoading = false;
      });

      // Clear loading status after brief display
      Timer(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _loadingStatus = null);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize: $e';
        _loadingStatus = null;
      });
    }
  }

  /// Create default agent when none exist
  /// PERF: O(1) - direct AgentService usage
  Future<void> _createDefaultAgent() async {
    try {
      setState(() => _loadingStatus = 'Creating default agent...');

      final defaultAgent = await services.agentService.createAgent(
        name: 'VibeCoder Assistant',
        systemPrompt:
            '''You are VibeCoder Assistant, an expert Flutter and Dart developer.

Help users with:
- Flutter widget development and optimization
- Dart language features and best practices  
- State management patterns (Provider, Bloc, Riverpod)
- Performance optimization techniques
- Testing strategies and implementation
- Architecture decisions and code organization

What would you like to work on today?''',
      );

      setState(() {
        _availableAgents = services.agentService.data;
      });

      // Create welcome message for default agent
      final welcomeMessage = ChatMessage(
        role: MessageRole.assistant,
        content: '''👋 **Welcome to VibeCoder!**

I'm your AI Flutter development assistant. I can help you with:

🚀 **Flutter Development**
- Widget creation and optimization
- State management patterns
- Custom animations and UI

📱 **Mobile App Architecture** 
- Clean code principles
- Testing strategies
- Performance optimization

💡 **Dart Language**
- Language features and syntax
- Best practices and patterns
- Debugging techniques

What would you like to work on today?''',
      );

      defaultAgent.addMessage(welcomeMessage);
      // AgentModel is now a simple data model - persistence is handled by AgentService
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create default agent: $e';
        _loadingStatus = null;
      });
    }
  }

  /// Handle sending message to specific agent - CLEAN ARCHITECTURE
  /// PERF: O(1) - direct AgentModel method call
  Future<void> _handleSendMessage(String agentId, String messageText) async {
    if (!_isServiceInitialized || _isLoading) {
      _showSnackBar('Service is not ready yet');
      return;
    }

    if (messageText.trim().isEmpty) {
      _showSnackBar('Message cannot be empty');
      return;
    }

    // Find agent tab
    final tabIndex = _agentTabs.indexWhere((tab) => tab.agent.id == agentId);
    if (tabIndex == -1) {
      _showSnackBar('Agent tab not found');
      return;
    }

    final agentTab = _agentTabs[tabIndex];

    try {
      // CLEAN ARCHITECTURE: Direct AgentModel usage - no service intermediary
      await agentTab.agent.sendMessage(messageText);

      // Agent state is automatically updated - AgentModel handles its own state

      // Update UI - the agent model handles its own state
      setState(() {}); // Trigger rebuild to show updated conversation
    } catch (e) {
      _handleAgentError(agentId, 'Failed to send message: $e');
    }
  }

  /// Handle agent error
  /// PERF: O(1) - direct tab error state update
  void _handleAgentError(String agentId, String error) {
    final tabIndex = _agentTabs.indexWhere((tab) => tab.agent.id == agentId);
    if (tabIndex != -1) {
      setState(() {
        _agentTabs[tabIndex] = _agentTabs[tabIndex].copyWith(error: error);
      });
    }
  }

  /// Close agent tab
  /// PERF: O(1) - direct tab removal and cleanup
  Future<void> _closeAgentTab(int tabIndex) async {
    if (tabIndex < 0 || tabIndex >= _agentTabs.length) return;

    final agentTab = _agentTabs[tabIndex];

    // Cancel message subscription
    await agentTab.messageSubscription?.cancel();

    setState(() {
      _agentTabs.removeAt(tabIndex);

      // Update tab controller
      _tabController.dispose();
      _tabController =
          TabController(length: _agentTabs.length + 1, vsync: this);
      _tabController.addListener(_onTabChanged);

      // Adjust selected tab if necessary
      if (_selectedTabIndex > _agentTabs.length) {
        _selectedTabIndex = _agentTabs.length; // Go to agents list
        _tabController.animateTo(_selectedTabIndex);
      }
    });
  }

  /// Open agent in new tab - CLEAN ARCHITECTURE
  /// PERF: O(1) - direct tab creation
  Future<void> _openAgentInTab(AgentModel agent) async {
    // Check if agent is already open in a tab
    final existingTabIndex =
        _agentTabs.indexWhere((tab) => tab.agent.id == agent.id);
    if (existingTabIndex != -1) {
      // Switch to existing tab
      _tabController.animateTo(existingTabIndex + 1); // +1 for agents list tab
      return;
    }

    // Create new agent tab
    final agentTab = AgentTab(agent: agent);

    setState(() {
      _agentTabs.add(agentTab);
      // Update tab controller length
      _tabController.dispose();
      _tabController =
          TabController(length: _agentTabs.length + 1, vsync: this);
      _tabController.addListener(_onTabChanged);
      // Switch to new tab
      _tabController.animateTo(_agentTabs.length); // Last tab (new agent tab)
    });
  }

  /// Show agent creation dialog
  ///
  /// ARCHITECTURAL: Uses AgentSettingsDialog for comprehensive agent configuration
  /// PERF: O(1) - direct dialog display with proper service integration
  Future<void> _showCreateAgentDialog() async {
    if (!_isServiceInitialized) {
      _showSnackBar('Please wait for services to initialize');
      return;
    }

    try {
      final mcpServerInfo = await _getMCPServerInfoForDialog();
      if (!mounted) return;

      final result = await AgentSettingsDialog.showCreateDialog(
        context,
        mcpServerInfo: mcpServerInfo,
      );

      if (!mounted) return;

      if (result != null) {
        // Use AgentService to properly create the agent with proper ID generation and persistence
        await services.agentService.createAgent(
          name: result.name,
          systemPrompt: result.systemPrompt,
          notepad: result.notepad,
          isActive: result.isActive,
          isProcessing: result.isProcessing,
          temperature: result.temperature,
          maxTokens: result.maxTokens,
          useBetaFeatures: result.useBetaFeatures,
          useReasonerModel: result.useReasonerModel,
          mcpConfigPath: result.mcpConfigPath,
          supervisorId: result.supervisorId,
          contextFiles: result.contextFiles,
          toDoList: result.toDoList,
          conversationHistory: result.conversationHistory,
          metadata: result.metadata,
        );

        // Reload agents from service to get the properly created agent
        await services.agentService.loadAll();
        _availableAgents = services.agentService.data;
        setState(() {});
        if (mounted) {
          _showSnackBar('Agent "${result.name}" created successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to create agent: $e');
      }
    }
  }

  /// Delete agent
  ///
  /// ARCHITECTURAL: Service-mediated agent deletion with UI confirmation
  /// PERF: O(1) - direct service method call with confirmation dialog
  Future<void> _deleteAgent(String agentId) async {
    if (!_isServiceInitialized) {
      _showSnackBar('Please wait for services to initialize');
      return;
    }

    final agent = _availableAgents.where((a) => a.id == agentId).firstOrNull;
    if (agent == null) {
      _showSnackBar('Agent not found');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Agent'),
        content: Text(
            'Are you sure you want to delete "${agent.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      try {
        await services.agentService.deleteAgent(agentId);
        _availableAgents.removeWhere((a) => a.id == agentId);

        // Also close any open tabs for this agent
        final tabIndexToRemove =
            _agentTabs.indexWhere((tab) => tab.agent.id == agentId);
        if (tabIndexToRemove != -1) {
          _closeAgentTab(tabIndexToRemove);
        }

        setState(() {});
        if (mounted) {
          _showSnackBar('Agent "${agent.name}" deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Failed to delete agent: $e');
        }
      }
    }
  }

  /// View agent details
  ///
  /// ARCHITECTURAL: Uses AgentSettingsDialog in view-only mode
  /// PERF: O(1) - direct dialog display with agent data
  Future<void> _viewAgentDetails(String agentId) async {
    final agent = _availableAgents.where((a) => a.id == agentId).firstOrNull;
    if (agent == null) {
      _showSnackBar('Agent not found');
      return;
    }

    try {
      final mcpServerInfo = await _getMCPServerInfoForDialog();
      if (!mounted) return;

      await AgentSettingsDialog.showViewDialog(
        context,
        agent,
        mcpServerInfo: mcpServerInfo,
      );

      if (!mounted) return;
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to show agent details: $e');
      }
    }
  }

  /// Edit agent settings
  ///
  /// ARCHITECTURAL: Uses AgentSettingsDialog for comprehensive agent editing
  /// PERF: O(1) - direct dialog display with service integration for updates
  Future<void> _editAgentSettings(String agentId) async {
    if (!_isServiceInitialized) {
      _showSnackBar('Please wait for services to initialize');
      return;
    }

    final agentIndex = _availableAgents.indexWhere((a) => a.id == agentId);
    if (agentIndex == -1) {
      _showSnackBar('Agent not found');
      return;
    }

    final agent = _availableAgents[agentIndex];

    try {
      final mcpServerInfo = await _getMCPServerInfoForDialog();
      if (!mounted) return;

      final result = await AgentSettingsDialog.showEditDialog(
        context,
        agent,
        mcpServerInfo: mcpServerInfo,
      );

      if (!mounted) return;

      if (result != null) {
        // Use AgentService to properly update the agent with persistence
        await services.agentService.updateAgent(
          agentId,
          name: result.name,
          systemPrompt: result.systemPrompt,
          temperature: result.temperature,
          maxTokens: result.maxTokens,
          useBetaFeatures: result.useBetaFeatures,
          useReasonerModel: result.useReasonerModel,
          mcpConfigPath: result.mcpConfigPath,
        );

        // Reload agents from service to get the updated agent
        await services.agentService.loadAll();
        _availableAgents = services.agentService.data;

        // Update any open tabs for this agent with the updated agent data
        final updatedAgent =
            _availableAgents.where((a) => a.id == agentId).firstOrNull;
        if (updatedAgent != null) {
          final tabIndex =
              _agentTabs.indexWhere((tab) => tab.agent.id == agentId);
          if (tabIndex != -1) {
            _agentTabs[tabIndex] =
                _agentTabs[tabIndex].copyWith(agent: updatedAgent);
          }
        }

        setState(() {});
        if (mounted) {
          _showSnackBar('Agent "${result.name}" updated successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to edit agent: $e');
      }
    }
  }

  /// Get MCP server information for dialog display
  ///
  /// ARCHITECTURAL: Service-mediated MCP server information gathering
  /// PERF: O(1) - service method call or fallback to configuration
  Future<Map<String, dynamic>?> _getMCPServerInfoForDialog() async {
    try {
      // Try to get MCP server info from services if available
      if (_isServiceInitialized) {
        return services.mcpService.getMCPServerInfo();
      }
      return null;
    } catch (e) {
      // Graceful fallback - dialog can work without MCP info
      return null;
    }
  }

  /// Show user feedback via SnackBar
  /// PERF: O(1) - immediate UI feedback
  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VibeCoder - Multi-Agent System'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            // Agents list tab
            Tab(
              icon: const Icon(Icons.group),
              text: 'Agents (${_availableAgents.length})',
            ),
            // Agent conversation tabs
            ..._agentTabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              return Tab(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.isProcessing ? Icons.hourglass_empty : Icons.chat),
                    if (tab.error != null)
                      const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _closeAgentTab(index),
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
                text: tab.agent.name,
              );
            }),
          ],
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Loading status banner
          if (_loadingStatus != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_loadingStatus ?? '')),
                  TextButton(
                    onPressed: () {
                      setState(() => _loadingStatus = null);
                    },
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),

          // Error banner
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage ?? '',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _errorMessage = null);
                    },
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),

          // Main content based on selected tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Agents List Tab
                AgentListComponent(
                  agents: _availableAgents,
                  currentAgentId: null, // No current agent concept
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  onAgentSelected:
                      _openAgentInTab, // Open in tab instead of switching
                  onCreateAgent: _showCreateAgentDialog,
                  onDeleteAgent: _deleteAgent,
                  onViewAgent: _viewAgentDetails,
                  onEditAgent: _editAgentSettings,
                ),

                // Agent Chat Tabs
                ..._agentTabs.map((tab) {
                  return MessagingUI(
                    messages: tab.messages,
                    onSendMessage: (message) =>
                        _handleSendMessage(tab.agent.id, message),
                    showTimestamps: true,
                    inputPlaceholder: tab.isProcessing
                        ? '${tab.agent.name} is thinking...'
                        : 'Ask ${tab.agent.name} anything...',
                    showInput: _isServiceInitialized &&
                        !_isLoading &&
                        !tab.isProcessing,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
