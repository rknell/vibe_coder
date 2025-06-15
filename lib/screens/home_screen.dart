import 'package:flutter/material.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/components/messaging_ui.dart';
import 'package:vibe_coder/components/agents/agent_list_component.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/services/multi_agent_chat_service.dart';
import 'dart:async';

/// HomeScreen - Multi-Agent Management & Chat Interface
///
/// ## MISSION ACCOMPLISHED
/// **ELIMINATES SINGLE-AGENT LIMITATION** by providing comprehensive multi-agent management.
/// Shows all registered agents, enables individual chat histories, and provides seamless agent switching.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Single Agent UI | Simple | Scalability limit | ELIMINATED - multi-agent required |
/// | Split Agent/Chat Views | Clean separation | Navigation complexity | Rejected - UX friction |
/// | Unified Multi-Agent Interface | Agent switching + chat | State complexity | CHOSEN - optimal UX |
/// | Tabbed Interface | Multiple contexts | Memory usage | Considered - may implement later |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Single-Agent Limitation Destruction**
///    - 🔍 Symptom: Can only interact with one agent at a time
///    - 🎯 Root Cause: ChatService single-agent architecture
///    - 💥 Kill Shot: MultiAgentChatService with agent registry and switching
///
/// 2. **Agent Discovery Challenge**
///    - 🔍 Symptom: No visibility into available agents
///    - 🎯 Root Cause: No agent list interface
///    - 💥 Kill Shot: AgentListComponent with real-time status updates
///
/// 3. **Context Switching Chaos**
///    - 🔍 Symptom: Losing conversation history when switching agents
///    - 🎯 Root Cause: Shared conversation state
///    - 💥 Kill Shot: Per-agent conversation isolation with seamless switching
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Agent switching: O(1) - HashMap-based lookup
/// - Agent list rendering: O(n) where n = number of agents
/// - Message streaming: O(1) per agent - isolated streams
/// - Memory usage: O(n) where n = active agents with conversation history
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MultiAgentChatService _multiAgentChatService = MultiAgentChatService();

  // UI State Management
  int _selectedIndex = 0; // 0 = agent list, 1 = current agent chat
  late TabController _tabController;

  // Agent & Message State
  List<AgentModel> _agents = [];
  AgentModel? _currentAgent;
  final Map<String, List<ChatMessage>> _agentMessages = {};

  // Service State Tracking
  bool _isLoading = false;
  String? _errorMessage;
  bool _isServiceInitialized = false;

  // Stream Subscriptions for Reactive UI
  StreamSubscription<ChatMessage>? _currentAgentMessageSubscription;
  final Map<String, StreamSubscription<ChatMessage>>
      _agentMessageSubscriptions = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeMultiAgentService();
  }

  @override
  void dispose() {
    _currentAgentMessageSubscription?.cancel();
    for (final sub in _agentMessageSubscriptions.values) {
      sub.cancel();
    }
    _multiAgentChatService.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Initialize multi-agent service and set up reactive streams
  ///
  /// PERF: O(1) initialization with lazy agent loading
  /// ARCHITECTURAL: Stream-based reactive architecture for real-time updates
  Future<void> _initializeMultiAgentService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _multiAgentChatService.initialize();

      // Load existing agents and set up reactive updates
      setState(() {
        _agents = _multiAgentChatService.allAgents;
        _isServiceInitialized = true;
      });

      // Set up initial agent if available
      if (_agents.isNotEmpty && _multiAgentChatService.currentAgentId == null) {
        await _switchToAgent(_agents.first.id);
      } else if (_multiAgentChatService.currentAgentId != null) {
        _currentAgent = _multiAgentChatService.currentAgent;
        await _setupCurrentAgentStreams();
      }

      // Create default agent if none exist
      if (_agents.isEmpty) {
        await _createDefaultAgent();
      }

      _errorMessage = null;
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize multi-agent service: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Create default agent for first-time users
  ///
  /// PERF: O(1) - single agent creation
  /// ARCHITECTURAL: Provides immediate value for new users
  Future<void> _createDefaultAgent() async {
    try {
      final defaultAgent = await _multiAgentChatService.createAgent(
        name: 'VibeCoder Assistant',
        systemPrompt:
            '''You are VibeCoder, an expert Flutter and Dart development assistant. 
You help developers with code review, debugging, architecture decisions, and best practices.
You are direct, helpful, and provide actionable solutions.''',
        temperature: 0.7,
        maxTokens: 4000,
      );

      setState(() {
        _agents = _multiAgentChatService.allAgents;
      });

      await _switchToAgent(defaultAgent.id);
      _addWelcomeMessage(defaultAgent);
    } catch (e) {
      _showSnackBar('Failed to create default agent: $e');
    }
  }

  /// Switch to a different agent and set up its chat interface
  ///
  /// PERF: O(1) - HashMap lookup with stream management
  /// ARCHITECTURAL: Preserves conversation state while switching context
  Future<void> _switchToAgent(String agentId) async {
    if (_currentAgent?.id == agentId) return;

    try {
      // Cancel current agent streams
      await _currentAgentMessageSubscription?.cancel();

      // Switch service context
      await _multiAgentChatService.switchToAgent(agentId);

      // Update UI state
      setState(() {
        _currentAgent = _multiAgentChatService.currentAgent;
        _selectedIndex = 1; // Switch to chat view
      });

      // Update tab controller
      _tabController.animateTo(1);

      // Set up new agent streams
      await _setupCurrentAgentStreams();

      // Load existing messages for this agent
      _loadAgentMessages(agentId);
    } catch (e) {
      _showSnackBar('Failed to switch to agent: $e');
    }
  }

  /// Set up message streams for current agent
  ///
  /// PERF: O(1) - stream setup
  /// ARCHITECTURAL: Reactive message updates for real-time chat
  Future<void> _setupCurrentAgentStreams() async {
    if (_currentAgent == null) return;

    final agentId = _currentAgent!.id;

    // Get agent-specific message stream
    final messageStream = _multiAgentChatService.getAgentMessageStream(agentId);

    _currentAgentMessageSubscription = messageStream.listen(
      (message) {
        setState(() {
          _agentMessages[agentId] = _agentMessages[agentId] ?? [];
          _agentMessages[agentId]!.add(message);
        });
      },
      onError: (error) {
        _showSnackBar('Message stream error: $error');
      },
    );
  }

  /// Load existing messages for an agent
  ///
  /// PERF: O(n) where n = agent's conversation history
  /// ARCHITECTURAL: Displays persistent conversation history
  void _loadAgentMessages(String agentId) {
    final agent = _agents.firstWhere((a) => a.id == agentId);
    setState(() {
      _agentMessages[agentId] = List.from(agent.conversationHistory);
    });
  }

  /// Add welcome message for new agents
  ///
  /// PERF: O(1) - single message addition
  void _addWelcomeMessage(AgentModel agent) {
    final welcomeMessage = ChatMessage(
      role: MessageRole.assistant,
      content: '''👋 **Hello! I'm ${agent.name}**

I'm ready to help you with:
• Flutter & Dart development
• Code review and debugging
• Architecture and best practices  
• Project planning and optimization

What would you like to work on today?''',
    );

    setState(() {
      _agentMessages[agent.id] = _agentMessages[agent.id] ?? [];
      _agentMessages[agent.id]!.add(welcomeMessage);
    });
  }

  /// Handle sending message to current agent
  ///
  /// PERF: O(1) - direct service delegation
  /// ERROR HANDLING: Comprehensive exception management
  Future<void> _handleSendMessage(String messageText) async {
    if (_currentAgent == null) {
      _showSnackBar('No agent selected');
      return;
    }

    if (!_isServiceInitialized || _isLoading) {
      _showSnackBar('Service is not ready yet');
      return;
    }

    if (messageText.trim().isEmpty) {
      _showSnackBar('Message cannot be empty');
      return;
    }

    try {
      await _multiAgentChatService.sendMessage(messageText);
    } catch (e) {
      _showSnackBar('Failed to send message: $e');
    }
  }

  /// Show agent creation dialog
  ///
  /// PERF: O(1) - dialog display
  Future<void> _showCreateAgentDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _CreateAgentDialog(),
    );

    if (result != null) {
      await _createAgent(
        name: result['name']!,
        systemPrompt: result['systemPrompt']!,
      );
    }
  }

  /// Create new agent with specified configuration
  ///
  /// PERF: O(1) - direct service delegation
  Future<void> _createAgent({
    required String name,
    required String systemPrompt,
  }) async {
    if (name.trim().isEmpty || systemPrompt.trim().isEmpty) {
      _showSnackBar('Name and system prompt are required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final agent = await _multiAgentChatService.createAgent(
        name: name,
        systemPrompt: systemPrompt,
      );

      setState(() {
        _agents = _multiAgentChatService.allAgents;
      });

      await _switchToAgent(agent.id);
      _addWelcomeMessage(agent);

      _showSnackBar('Agent "${agent.name}" created successfully');
    } catch (e) {
      _showSnackBar('Failed to create agent: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Delete agent with confirmation
  ///
  /// PERF: O(1) - direct service delegation
  Future<void> _deleteAgent(String agentId) async {
    final agent = _agents.firstWhere((a) => a.id == agentId);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Agent'),
        content: Text(
            'Are you sure you want to delete "${agent.name}"?\n\nThis will permanently remove the agent and all its conversation history.'),
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
      try {
        await _multiAgentChatService.deleteAgent(agentId);

        setState(() {
          _agents = _multiAgentChatService.allAgents;
          _agentMessages.remove(agentId);

          // Switch to first available agent or go back to agent list
          if (_currentAgent?.id == agentId) {
            if (_agents.isNotEmpty) {
              _switchToAgent(_agents.first.id);
            } else {
              _currentAgent = null;
              _selectedIndex = 0;
              _tabController.animateTo(0);
            }
          }
        });

        _showSnackBar('Agent "${agent.name}" deleted');
      } catch (e) {
        _showSnackBar('Failed to delete agent: $e');
      }
    }
  }

  /// Show user feedback via SnackBar
  ///
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
        title: _currentAgent != null
            ? Text(_currentAgent!.name)
            : const Text('VibeCoder - Multi-Agent System'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          tabs: [
            Tab(
              icon: Icon(Icons.group),
              text: 'Agents (${_agents.length})',
            ),
            Tab(
              icon: Icon(
                  _currentAgent != null ? Icons.chat : Icons.chat_outlined),
              text: _currentAgent?.name ?? 'No Agent Selected',
            ),
          ],
        ),
        actions: [
          // Service status indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
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
                      _errorMessage!,
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
                  agents: _agents,
                  currentAgentId: _currentAgent?.id,
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  onAgentSelected: _switchToAgent,
                  onCreateAgent: _showCreateAgentDialog,
                  onDeleteAgent: _deleteAgent,
                  onViewAgent: _switchToAgent,
                ),

                // Current Agent Chat Tab
                _currentAgent != null
                    ? MessagingUI(
                        messages: _agentMessages[_currentAgent!.id] ?? [],
                        onSendMessage: _handleSendMessage,
                        showTimestamps: true,
                        inputPlaceholder:
                            _multiAgentChatService.isCurrentAgentProcessing
                                ? '${_currentAgent!.name} is thinking...'
                                : 'Ask ${_currentAgent!.name} anything...',
                        showInput: _isServiceInitialized && !_isLoading,
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No Agent Selected',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Select an agent from the Agents tab to start chatting',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Create Agent Dialog - Agent creation interface
///
/// ARCHITECTURAL: Extracted dialog component following Flutter architecture rules
class _CreateAgentDialog extends StatefulWidget {
  @override
  _CreateAgentDialogState createState() => _CreateAgentDialogState();
}

class _CreateAgentDialogState extends State<_CreateAgentDialog> {
  final _nameController = TextEditingController();
  final _systemPromptController = TextEditingController(
    text: '''You are a helpful AI assistant specialized in software development.
You provide clear, actionable advice and help with coding questions.
You are direct, professional, and solution-focused.''',
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create New Agent'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Agent Name',
                hintText: 'e.g., Flutter Expert, Code Reviewer',
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Agent name is required';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _systemPromptController,
              decoration: InputDecoration(
                labelText: 'System Prompt',
                hintText: 'Define the agent\'s role and behavior',
              ),
              maxLines: 4,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'System prompt is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'systemPrompt': _systemPromptController.text.trim(),
              });
            }
          },
          child: Text('Create Agent'),
        ),
      ],
    );
  }
}
