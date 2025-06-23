import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibe_coder/components/agents/agent_list_component.dart';
import 'package:vibe_coder/components/agents/agent_settings_dialog.dart';
import 'package:vibe_coder/components/agents/agent_tab_bar.dart';
import 'package:vibe_coder/components/common/dialogs/confirmation_dialog.dart';
import 'package:vibe_coder/components/common/dialogs/mcp_server_management_dialog.dart';
import 'package:vibe_coder/components/common/indicators/mcp_status_icon.dart';
import 'package:vibe_coder/components/common/indicators/status_banner.dart';
import 'package:vibe_coder/components/messaging_ui.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/models/mcp_server_info.dart';
import 'package:vibe_coder/models/mcp_server_model.dart';
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

/// Agent Tab Data - CLEAN ARCHITECTURE: Direct AgentModel reference with reactive state
///
/// ARCHITECTURAL: Each tab maintains direct reference to AgentModel (extends ChangeNotifier)
/// PERF: O(1) access to conversation state via model with reactive updates
class AgentTabData {
  final AgentModel agent;
  final StreamSubscription<ChatMessage>? messageSubscription;
  final String? error;

  const AgentTabData({
    required this.agent,
    this.messageSubscription,
    this.error,
  });

  /// Create copy with updated values
  /// PERF: O(1) - immutable update pattern
  AgentTabData copyWith({
    AgentModel? agent,
    StreamSubscription<ChatMessage>? messageSubscription,
    String? error,
  }) {
    return AgentTabData(
      agent: agent ?? this.agent,
      messageSubscription: messageSubscription ?? this.messageSubscription,
      error: error ?? this.error,
    );
  }
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // CLEAN ARCHITECTURE: Direct service usage for factory operations only
  late TabController _tabController;
  final List<AgentTabData> _agentTabs = [];
  int _selectedTabIndex = 0;

  // Available agents registry - loaded from AgentService
  // ❌ ARCHITECTURAL VIOLATION: Manual state duplication
  // List<AgentModel> _availableAgents = [];

  // Service State Tracking
  bool _isLoading = false;
  String? _errorMessage;
  String? _loadingStatus;
  bool _isServiceInitialized = false;

  // ✅ ARCHITECTURAL COMPLIANCE: Direct service access via reactive patterns
  List<AgentModel> get _availableAgents => services.agentService.data;

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
        // _availableAgents = services.agentService.data;
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
      // No setState needed - AgentModel now extends ChangeNotifier and MessagingUI will update reactively
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

  /// Clear agent conversation - ARCHITECTURAL: Direct agent model manipulation
  /// PERF: O(1) - direct AgentModel method call
  Future<void> _clearAgentConversation(String agentId) async {
    if (!_isServiceInitialized) {
      _showSnackBar('Service is not ready yet');
      return;
    }

    // Find agent tab
    final tabIndex = _agentTabs.indexWhere((tab) => tab.agent.id == agentId);
    if (tabIndex == -1) {
      _showSnackBar('Agent tab not found');
      return;
    }

    final agentTab = _agentTabs[tabIndex];

    // Show confirmation dialog
    final confirmed = await ConfirmationDialog.showClear(
      context,
      itemName: agentTab.agent.name,
      customContent:
          'Are you sure you want to clear the conversation with "${agentTab.agent.name}"? This action cannot be undone.',
    );

    if (confirmed == true) {
      if (!mounted) return;

      try {
        // CLEAN ARCHITECTURE: Direct AgentModel usage
        agentTab.agent.clearConversation();

        // Save the updated agent state
        await agentTab.agent.save();

        if (mounted) {
          _showSnackBar(
              'Conversation with "${agentTab.agent.name}" cleared successfully');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Failed to clear conversation: $e');
        }
      }
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
    final agentTab = AgentTabData(agent: agent);

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
        mcpServerInfo: mcpServerInfo?.toJson(),
      );

      if (!mounted) return;

      if (result != null) {
        // WARRIOR PROTOCOL: Direct agent mutation - single source of truth
        // Add the new agent directly to the service collection
        services.agentService.addAgentDirectly(result);

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
    final confirmed = await ConfirmationDialog.showDelete(
      context,
      itemName: agent.name,
    );

    if (confirmed == true) {
      if (!mounted) return;

      try {
        await services.agentService.deleteAgent(agentId);
        // setState() no longer needed - ListenableBuilder handles updates
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
        mcpServerInfo: mcpServerInfo?.toJson(),
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
        mcpServerInfo: mcpServerInfo?.toJson(),
      );

      if (!mounted) return;

      if (result != null) {
        // WARRIOR PROTOCOL: Direct agent mutation - single source of truth
        // Replace the agent in the service collection with the updated one
        try {
          await services.agentService.replaceAgent(agentId, result);

          // CRITICAL FIX: Update any open AgentTab references to use the new AgentModel
          // This ensures MCP preferences are immediately effective in active conversations
          final tabIndex =
              _agentTabs.indexWhere((tab) => tab.agent.id == agentId);
          if (tabIndex != -1) {
            // Invalidate old agent instance to force recreation with new preferences
            _agentTabs[tabIndex].agent.invalidateAgentInstance();

            // Update tab to reference the new AgentModel
            setState(() {
              _agentTabs[tabIndex] =
                  _agentTabs[tabIndex].copyWith(agent: result);
            });
          }

          if (mounted) {
            _showSnackBar('Agent "${result.name}" updated successfully');
          }
        } catch (e) {
          if (mounted) {
            _showSnackBar('Agent not found in collection');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to edit agent: $e');
      }
    }
  }

  /// Show MCP Server Management Dialog
  ///
  /// ARCHITECTURAL: Comprehensive MCP server management with refresh capabilities
  /// PERF: O(1) - dialog display with service integration for real-time updates
  Future<void> _showMCPServerManager() async {
    if (!_isServiceInitialized) {
      _showSnackBar('Please wait for services to initialize');
      return;
    }

    try {
      final mcpInfo = await _getMCPServerInfoForDialog();
      if (mcpInfo == null) {
        _showSnackBar('MCP server information is not available yet');
        return;
      }
      if (!mounted) return;

      await MCPServerManagementDialog.show(
        context,
        mcpInfo,
        onRefreshAll: _refreshAllMCPServers,
        onRefreshServer: _refreshMCPServer,
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to show MCP manager: $e');
      }
    }
  }

  /// Refresh all MCP servers
  ///
  /// ARCHITECTURAL: Service-mediated bulk server refresh
  /// PERF: O(n) - parallel server refresh operations
  Future<MCPServerInfoResponse> _refreshAllMCPServers() async {
    try {
      // Get all configured servers (not just connected ones)
      final allServers = services.mcpService.data;

      // Connect/refresh each server
      for (final server in allServers) {
        try {
          if (server.status != MCPServerStatus.connected) {
            await services.mcpService.connectServer(server.id);
          } else {
            await services.mcpService.refreshServer(server.id);
          }
        } catch (e) {
          // Continue with other servers even if one fails
          continue;
        }
      }

      // Return updated server information (strongly-typed response)
      return services.mcpService.getMCPServerInfo();
    } catch (e) {
      // Re-throw to let dialog handle error display
      rethrow;
    }
  }

  /// Refresh individual MCP server
  ///
  /// ARCHITECTURAL: Service-mediated individual server refresh
  /// PERF: O(1) - single server refresh with targeted reconnection
  Future<MCPServerInfoResponse> _refreshMCPServer(String serverName) async {
    try {
      // Find server by name to get its ID
      final server = services.mcpService.getByName(serverName);
      if (server == null) {
        throw Exception('Server not found: $serverName');
      }

      // If server is not connected, connect it. Otherwise, refresh capabilities
      if (server.status != MCPServerStatus.connected) {
        await services.mcpService.connectServer(server.id);
      } else {
        await services.mcpService.refreshServer(server.id);
      }

      // Return updated server information (strongly-typed response)
      return services.mcpService.getMCPServerInfo();
    } catch (e) {
      // Re-throw to let dialog handle error display
      rethrow;
    }
  }

  /// Get MCP server information for dialog display
  ///
  /// ARCHITECTURAL: Service-mediated MCP server information gathering
  /// PERF: O(1) - service method call or fallback to configuration
  Future<MCPServerInfoResponse?> _getMCPServerInfoForDialog() async {
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AgentTabBar(
            tabController: _tabController,
            agentTabs: _agentTabs
                .map((tabData) => AgentTab(
                      agent: tabData.agent,
                      error: tabData.error,
                    ))
                .toList(),
            onCloseTab: _closeAgentTab,
          ),
        ),
        actions: [
          // MCP Status Icon - Compact status indicator with management access
          MCPStatusIcon(
            isServiceInitialized: _isServiceInitialized,
            onTap: _isServiceInitialized ? _showMCPServerManager : null,
          ),

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
          // Status banners - ARCHITECTURAL: Extracted component usage
          if (_loadingStatus != null)
            StatusBanner.loading(
              message: _loadingStatus!,
              onDismiss: () => setState(() => _loadingStatus = null),
            ),

          if (_errorMessage != null)
            StatusBanner.error(
              message: _errorMessage!,
              onDismiss: () => setState(() => _errorMessage = null),
            ),

          // Main content based on selected tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Agents List Tab - ARCHITECTURAL: ListenableBuilder positioned close to changing content
                ListenableBuilder(
                  listenable: services.agentService,
                  builder: (context, child) {
                    return AgentListComponent(
                      agents:
                          services.agentService.data, // Direct service access
                      currentAgentId: null, // No current agent concept
                      isLoading: _isLoading,
                      errorMessage: _errorMessage,
                      onAgentSelected:
                          _openAgentInTab, // Open in tab instead of switching
                      onCreateAgent: _showCreateAgentDialog,
                      onDeleteAgent: _deleteAgent,
                      onViewAgent: _viewAgentDetails,
                      onEditAgent: _editAgentSettings,
                    );
                  },
                ),

                // Agent Chat Tabs - ARCHITECTURAL: ListenableBuilder for reactive agent updates
                ..._agentTabs.map((tab) {
                  return ListenableBuilder(
                    listenable: tab.agent, // Listen to AgentModel changes
                    builder: (context, child) {
                      return MessagingUI(
                        messages: tab.agent.conversationHistory,
                        onSendMessage: (message) =>
                            _handleSendMessage(tab.agent.id, message),
                        onClearConversation: () =>
                            _clearAgentConversation(tab.agent.id),
                        showTimestamps: true,
                        inputPlaceholder: tab.agent.isProcessing
                            ? '${tab.agent.name} is thinking...'
                            : 'Ask ${tab.agent.name} anything...',
                        showInput: _isServiceInitialized && !_isLoading,
                      );
                    },
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
