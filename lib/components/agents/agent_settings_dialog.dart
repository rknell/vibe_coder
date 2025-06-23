/// AgentSettingsDialog - Comprehensive Agent Configuration Interface
library;

///
/// ## MISSION ACCOMPLISHED
/// **ELIMINATES BASIC AGENT CREATION** by providing comprehensive agent configuration interface.
/// Supports creation, viewing, and editing of agents with full validation and error handling.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Basic Text Fields | Simple | Limited features | ELIMINATED - need full configuration |
/// | Component Extraction | Reusable | Complex | CHOSEN - architectural excellence |
/// | Tabbed Interface | Organized | Navigation | CHOSEN - better UX for many settings |
/// | Single Form | Simple | Overwhelming | Rejected - too many fields |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Basic Agent Creation Limitation**
///    - 🔍 Symptom: Only name and system prompt configurable
///    - 🎯 Root Cause: Insufficient configuration interface
///    - 💥 Kill Shot: Comprehensive settings with all AgentModel fields
///
/// 2. **Configuration Validation Chaos**
///    - 🔍 Symptom: Invalid agent configurations possible
///    - 🎯 Root Cause: No validation during creation/editing
///    - 💥 Kill Shot: Real-time validation with error prevention
///
/// 3. **View/Edit Mode Separation**
///    - 🔍 Symptom: Separate dialogs for view vs edit
///    - 🎯 Root Cause: No unified interface
///    - 💥 Kill Shot: Single dialog with mode switching capability
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Form validation: O(1) - immediate field validation
/// - Agent updates: O(1) - direct field updates with copyWith
/// - UI rendering: O(1) - stateful widget with controlled rebuilds
import 'package:flutter/material.dart';
import 'package:vibe_coder/models/agent_model.dart';

/// AgentSettingsDialog - Comprehensive Agent Configuration Interface
class AgentSettingsDialog extends StatefulWidget {
  final AgentModel? agent; // null for creation, AgentModel for edit/view
  final bool isViewOnly;
  final bool isCreationMode;
  final Map<String, dynamic>?
      mcpServerInfo; // MCP server information for display

  const AgentSettingsDialog({
    super.key,
    this.agent,
    this.isViewOnly = false,
    this.mcpServerInfo,
  }) : isCreationMode = agent == null;

  /// Show dialog for creating new agent
  static Future<AgentModel?> showCreateDialog(BuildContext context,
      {Map<String, dynamic>? mcpServerInfo}) {
    return showDialog<AgentModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AgentSettingsDialog(mcpServerInfo: mcpServerInfo),
    );
  }

  /// Show dialog for viewing agent details
  static Future<void> showViewDialog(BuildContext context, AgentModel agent,
      {Map<String, dynamic>? mcpServerInfo}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AgentSettingsDialog(
        agent: agent,
        isViewOnly: true,
        mcpServerInfo: mcpServerInfo,
      ),
    );
  }

  /// Show dialog for editing agent
  static Future<AgentModel?> showEditDialog(
      BuildContext context, AgentModel agent,
      {Map<String, dynamic>? mcpServerInfo}) {
    return showDialog<AgentModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AgentSettingsDialog(agent: agent, mcpServerInfo: mcpServerInfo),
    );
  }

  @override
  State<AgentSettingsDialog> createState() => _AgentSettingsDialogState();
}

class _AgentSettingsDialogState extends State<AgentSettingsDialog>
    with TickerProviderStateMixin {
  // WARRIOR PROTOCOL EXCEPTION: TabController requires late initialization for TickerProviderStateMixin
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form Controllers - WARRIOR PROTOCOL: Direct initialization eliminates late variable vulnerability
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  final TextEditingController _mcpConfigPathController =
      TextEditingController();
  // NOTE: notepad functionality is now handled by MCP notepad server
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _maxTokensController = TextEditingController();

  // Configuration Values - WARRIOR PROTOCOL: Safe initialization with defaults
  double _temperature = 0.7;
  int _maxTokens = 4000;
  bool _useBetaFeatures = false;
  bool _useReasonerModel = false;

  // MCP Server Configuration - WARRIOR PROTOCOL: Dynamic server state management
  final Map<String, bool?> _mcpServerStates = {};

  // Validation State
  final Map<String, String> _validationErrors = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize form controllers with agent data
    _nameController.text = widget.agent?.name ?? '';
    _systemPromptController.text =
        widget.agent?.systemPrompt ?? _getDefaultSystemPrompt();
    _mcpConfigPathController.text = widget.agent?.mcpConfigPath ?? '';
    // NOTE: notepad is now handled by MCP notepad server
    _temperatureController.text = (widget.agent?.temperature ?? 0.7).toString();
    _maxTokensController.text = (widget.agent?.maxTokens ?? 4000).toString();

    // Initialize configuration values from agent or defaults
    _temperature = widget.agent?.temperature ?? 0.7;
    _maxTokens = widget.agent?.maxTokens ?? 4000;
    _useBetaFeatures = widget.agent?.useBetaFeatures ?? false;
    _useReasonerModel = widget.agent?.useReasonerModel ?? false;

    // Initialize MCP state from agent preferences
    _initializeMCPStateFromAgent();

    // Set up change listeners for validation
    _nameController.addListener(_validateAndSetChanges);
    _systemPromptController.addListener(_validateAndSetChanges);
    _mcpConfigPathController.addListener(_validateAndSetChanges);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _systemPromptController.dispose();
    _mcpConfigPathController.dispose();
    // NOTE: notepad controller removed - handled by MCP server
    _temperatureController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  /// Initialize MCP state from agent's saved preferences
  ///
  /// ARCHITECTURAL: Load saved preferences into dialog state
  void _initializeMCPStateFromAgent() {
    if (widget.agent != null) {
      final agent = widget.agent!;

      // Initialize server states from agent preferences
      _mcpServerStates.clear();
      _mcpServerStates.addAll(agent.mcpServerPreferences);

      // Initialize tool states from agent preferences
      _mcpServerStates.addAll(agent.mcpToolPreferences);
    }
  }

  /// Get default system prompt for new agents
  ///
  /// PERF: O(1) - static string return
  String _getDefaultSystemPrompt() {
    return '''You are a helpful AI assistant specialized in software development.
You provide clear, actionable advice and help with coding questions.
You are direct, professional, and solution-focused.''';
  }

  /// Validate form and track changes
  ///
  /// PERF: O(1) - immediate validation with state updates
  void _validateAndSetChanges() {
    setState(() {
      _validationErrors.clear();
      _validateFields();
      _hasChanges = _checkForChanges();
    });
  }

  /// Validate all form fields
  ///
  /// PERF: O(1) - direct field validation
  void _validateFields() {
    if (_nameController.text.trim().isEmpty) {
      _validationErrors['name'] = 'Agent name is required';
    } else if (_nameController.text.trim().length > 50) {
      _validationErrors['name'] = 'Agent name must be 50 characters or less';
    }

    if (_systemPromptController.text.trim().isEmpty) {
      _validationErrors['systemPrompt'] = 'System prompt is required';
    } else if (_systemPromptController.text.trim().length > 2000) {
      _validationErrors['systemPrompt'] =
          'System prompt must be 2000 characters or less';
    }

    if (_temperature < 0.0 || _temperature > 2.0) {
      _validationErrors['temperature'] =
          'Temperature must be between 0.0 and 2.0';
    }

    if (_maxTokens < 100 || _maxTokens > 32000) {
      _validationErrors['maxTokens'] =
          'Max tokens must be between 100 and 32000';
    }
  }

  /// Check if any changes have been made
  ///
  /// PERF: O(1) - direct value comparison
  bool _checkForChanges() {
    final agent = widget.agent;
    if (widget.isCreationMode) {
      return true; // Always has changes in creation mode
    }

    // Check for MCP server state changes
    bool mcpStatesChanged = false;
    if (!widget.isCreationMode && widget.agent != null) {
      // Compare current states with saved states
      final agent = widget.agent;
      final savedStates = agent != null
          ? agent.metadata['mcpServerStates'] as Map<String, dynamic>?
          : null;
      final currentExplicitStates = <String, bool>{};

      // Extract current explicit states (non-null)
      for (final entry in _mcpServerStates.entries) {
        final entryValue = entry.value;
        if (entryValue != null) {
          currentExplicitStates[entry.key] = entryValue;
        }
      }

      // Compare saved vs current states
      if (savedStates == null && currentExplicitStates.isNotEmpty) {
        mcpStatesChanged = true;
      } else if (savedStates != null) {
        // Check if any states have changed
        final savedMap =
            Map<String, bool>.from(savedStates.cast<String, bool>());
        if (!_mapsEqual(savedMap, currentExplicitStates)) {
          mcpStatesChanged = true;
        }
      }
    } else if (widget.isCreationMode) {
      // In creation mode, any explicit state counts as a change
      mcpStatesChanged = _mcpServerStates.values.any((state) => state != null);
    }

    return agent?.name != _nameController.text.trim() ||
        agent?.systemPrompt != _systemPromptController.text.trim() ||
        agent?.mcpConfigPath != _mcpConfigPathController.text.trim() ||
        agent?.temperature != _temperature ||
        agent?.maxTokens != _maxTokens ||
        agent?.useBetaFeatures != _useBetaFeatures ||
        agent?.useReasonerModel != _useReasonerModel ||
        mcpStatesChanged;
  }

  /// Create AgentModel from current form values
  ///
  /// PERF: O(1) - direct object creation
  AgentModel _createAgentFromForm() {
    final agent = widget.agent;

    // Separate server and tool preferences from the combined state
    final serverPreferences = <String, bool>{};
    final toolPreferences = <String, bool>{};

    // Process MCP states to separate servers from tools
    for (final entry in _mcpServerStates.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value != null) {
        // If key contains colon, it's a tool (server:tool format)
        if (key.contains(':')) {
          toolPreferences[key] = value;
        } else {
          // Otherwise it's a server
          serverPreferences[key] = value;
        }
      }
    }

    if (widget.isCreationMode) {
      // Create new agent
      return AgentModel(
        id: null,
        name: _nameController.text.trim(),
        systemPrompt: _systemPromptController.text.trim(),
        temperature: _temperature,
        maxTokens: _maxTokens,
        useBetaFeatures: _useBetaFeatures,
        useReasonerModel: _useReasonerModel,
        mcpConfigPath: _mcpConfigPathController.text.trim().isEmpty
            ? null
            : _mcpConfigPathController.text.trim(),
        mcpServerPreferences: serverPreferences,
        mcpToolPreferences: toolPreferences,
        supervisorId: agent?.supervisorId,
        contextFiles: agent?.contextFiles ?? [],
        metadata: agent?.metadata ?? {},
      );
    } else {
      // Update existing agent
      final agentValue = agent;
      if (agentValue != null) {
        return agentValue.copyWith(
          name: _nameController.text.trim(),
          systemPrompt: _systemPromptController.text.trim(),
          temperature: _temperature,
          maxTokens: _maxTokens,
          useBetaFeatures: _useBetaFeatures,
          useReasonerModel: _useReasonerModel,
          mcpConfigPath: _mcpConfigPathController.text.trim().isEmpty
              ? null
              : _mcpConfigPathController.text.trim(),
          mcpServerPreferences: serverPreferences,
          mcpToolPreferences: toolPreferences,
        );
      } else {
        throw StateError('Cannot update agent: agent is null in edit mode');
      }
    }
  }

  /// Handle save action with validation
  ///
  /// PERF: O(1) - validation and form submission
  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_validationErrors.isEmpty) {
        final updatedAgent = _createAgentFromForm();
        Navigator.of(context).pop(updatedAgent);
      }
    }
  }

  /// Handle cancel with unsaved changes check
  ///
  /// PERF: O(1) - state check with user confirmation
  Future<void> _handleCancel() async {
    if (_hasChanges && !widget.isViewOnly) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
              'You have unsaved changes. Are you sure you want to close without saving?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Editing'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Discard'),
            ),
          ],
        ),
      );

      if (shouldDiscard == true) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Set all MCP servers enabled/disabled state
  ///
  /// PERF: O(n*m) where n = number of MCP servers, m = tools per server - bulk state update
  void _setAllMCPServers(bool enabled) {
    setState(() {
      final mcpInfo = _getAgentMCPInfo();
      final servers = (mcpInfo['servers'] as List<dynamic>?) ?? [];

      // Set state for all configured servers and their tools
      for (final serverData in servers) {
        final serverMap = serverData as Map<String, dynamic>;
        final serverName = serverMap['name'] as String;

        // Set server state
        _mcpServerStates[serverName] = enabled;

        // Set all tool states for this server
        final toolsData = serverMap['tools'] as List<dynamic>? ?? [];
        for (final toolData in toolsData) {
          final toolMap = toolData as Map<String, dynamic>;
          final toolUniqueId = toolMap['uniqueId'] as String? ??
              '$serverName:${toolMap['name']}';
          _mcpServerStates[toolUniqueId] = enabled;
        }
      }

      _validateAndSetChanges();
    });
  }

  /// Toggle individual MCP server state
  ///
  /// PERF: O(1) - direct state update
  void _toggleMCPServer(String serverName, bool enabled) {
    setState(() {
      // Always set the user preference, regardless of connection status
      _mcpServerStates[serverName] = enabled;

      // If disabling server, also disable all its tools
      if (!enabled) {
        final mcpInfo = _getAgentMCPInfo();
        final servers = (mcpInfo['servers'] as List<dynamic>?) ?? [];

        for (final serverData in servers) {
          final serverMap = serverData as Map<String, dynamic>;
          if (serverMap['name'] == serverName) {
            final toolsData = serverMap['tools'] as List<dynamic>? ?? [];
            for (final toolData in toolsData) {
              final toolMap = toolData as Map<String, dynamic>;
              final toolUniqueId = toolMap['uniqueId'] as String? ??
                  '$serverName:${toolMap['name']}';
              _mcpServerStates[toolUniqueId] = false;
            }
            break;
          }
        }
      }

      _validateAndSetChanges();
    });
  }

  /// Toggle all tools for a server
  ///
  /// PERF: O(n) where n = number of tools in server
  void _toggleAllServerTools(String serverName, bool enabled) {
    setState(() {
      final mcpInfo = _getAgentMCPInfo();
      final servers = (mcpInfo['servers'] as List<dynamic>?) ?? [];

      for (final serverData in servers) {
        final serverMap = serverData as Map<String, dynamic>;
        if (serverMap['name'] == serverName) {
          final toolsData = serverMap['tools'] as List<dynamic>? ?? [];
          for (final toolData in toolsData) {
            final toolMap = toolData as Map<String, dynamic>;
            final toolUniqueId = toolMap['uniqueId'] as String? ??
                '$serverName:${toolMap['name']}';
            _mcpServerStates[toolUniqueId] = enabled;
          }
          break;
        }
      }

      _validateAndSetChanges();
    });
  }

  /// Toggle individual MCP tool state
  ///
  /// PERF: O(1) - direct state update
  void _toggleMCPTool(String toolUniqueId, bool enabled) {
    setState(() {
      _mcpServerStates[toolUniqueId] = enabled;
      _validateAndSetChanges();
    });
  }

  /// Compare two maps for equality
  ///
  /// PERF: O(n) where n = number of entries
  bool _mapsEqual(Map<String, bool> map1, Map<String, bool> map2) {
    if (map1.length != map2.length) return false;

    for (final entry in map1.entries) {
      if (map2[entry.key] != entry.value) return false;
    }

    return true;
  }

  /// Build MCP server cards from available data
  ///
  /// PERF: O(n) where n = number of configured servers
  /// ARCHITECTURAL: Handles both real server data and placeholder states
  List<Widget> _buildMCPServerCards() {
    if (widget.isCreationMode) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'MCP Server Configuration',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'MCP server settings will be available after agent creation.\n'
                'The agent will automatically discover and configure available MCP servers based on your system configuration.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ];
    }

    // For existing agents, get real MCP server data
    return _buildRealMCPServerCards();
  }

  /// Build MCP server cards from real agent data
  ///
  /// PERF: O(n log n) where n = number of configured servers (due to sorting)
  /// ARCHITECTURAL: Gets real MCP data from active agent or shows loading state
  List<Widget> _buildRealMCPServerCards() {
    try {
      final mcpInfo = _getAgentMCPInfo();
      final servers = (mcpInfo['servers'] as List<dynamic>?) ?? [];

      if (servers.isEmpty) {
        return [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'No MCP Servers Configured',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'No MCP servers are currently configured for this agent.\n'
                  'Check your MCP configuration file or agent settings.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ];
      }

      // Sort servers: connected first, disconnected last
      final sortedServers = List<dynamic>.from(servers);
      sortedServers.sort((a, b) {
        final aMap = a as Map<String, dynamic>;
        final bMap = b as Map<String, dynamic>;
        final aConnected =
            (aMap['status'] as String? ?? 'unknown') == 'connected';
        final bConnected =
            (bMap['status'] as String? ?? 'unknown') == 'connected';

        // Connected servers first (true sorts before false when reversed)
        if (aConnected && !bConnected) return -1;
        if (!aConnected && bConnected) return 1;

        // Within same connection status, sort alphabetically by name
        final aName = aMap['name'] as String? ?? '';
        final bName = bMap['name'] as String? ?? '';
        return aName.compareTo(bName);
      });

      return sortedServers.map((serverData) {
        return _buildMCPServerCard(serverData as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      // Fallback to error state if MCP data can't be retrieved
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'MCP Data Unavailable',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to load MCP server information: $e\n'
                'The agent may need to be activated first.',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ];
    }
  }

  /// Get MCP server information for the current agent
  ///
  /// PERF: O(1) - direct parameter access
  /// ARCHITECTURAL: Uses passed MCP data instead of accessing services directly
  Map<String, dynamic> _getAgentMCPInfo() {
    // Use passed MCP server info if available
    final mcpServerInfo = widget.mcpServerInfo;
    if (mcpServerInfo != null) {
      // Handle legacy Map format from toJson()
      final serversMap =
          mcpServerInfo['servers'] as Map<String, dynamic>? ?? {};
      final serversList = serversMap.values.toList();

      return {
        'servers': serversList,
        'totalTools': mcpServerInfo['toolCount'] ?? 0,
        'connectedServers': mcpServerInfo['connectedCount'] ?? 0,
        'configuredServers': mcpServerInfo['totalCount'] ?? 0,
      };
    }

    // Fallback for cases where no MCP info is provided
    return {
      'servers': <Map<String, dynamic>>[],
      'totalTools': 0,
      'connectedServers': 0,
      'configuredServers': 0,
    };
  }

  /// Build MCP server configuration card from dynamic server data
  ///
  /// ARCHITECTURAL: Individual server control with tool-level granularity
  Widget _buildMCPServerCard(Map<String, dynamic> serverData) {
    final String serverName = serverData['name'] as String;
    final String status = serverData['status'] as String? ?? 'unknown';
    final int toolCount = serverData['toolCount'] as int? ?? 0;
    final List<dynamic> toolsData = serverData['tools'] as List<dynamic>? ?? [];
    final String serverType = serverData['type'] as String? ?? 'unknown';
    final bool isConnected = status == 'connected';

    // Separate user preference from connection status
    final bool? userEnabledState = _mcpServerStates[serverName];
    final bool userWantsEnabled = userEnabledState ??
        true; // Default to enabled unless user explicitly disabled

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // Grey out entire card if server is disconnected
      color: isConnected ? null : Colors.grey.withValues(alpha: 0.1),
      child: Container(
        // Add subtle overlay for disconnected servers
        decoration: isConnected
            ? null
            : BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.withValues(alpha: 0.05),
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Server Header - Enhanced with clearer status indicators
              Row(
                children: [
                  // Connection Status Icon
                  Icon(
                    isConnected ? Icons.wifi : Icons.wifi_off,
                    color: isConnected ? Colors.green : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),

                  // User Preference Icon
                  Icon(
                    userWantsEnabled
                        ? Icons.check_circle
                        : (isConnected ? Icons.cancel : Icons.link_off),
                    color: userWantsEnabled
                        ? (isConnected ? Colors.green : Colors.orange)
                        : (isConnected ? Colors.red : Colors.grey),
                    size: 20,
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              serverName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isConnected ? null : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isConnected
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isConnected
                                      ? Colors.green.withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                isConnected ? 'Connected' : 'Disconnected',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isConnected
                                      ? Colors.green[700]
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$serverType server',
                          style: TextStyle(
                            color: isConnected
                                ? Colors.grey[600]
                                : Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // User Preference Toggle
                  Switch(
                    value: userWantsEnabled,
                    onChanged: widget.isViewOnly
                        ? null
                        : (value) => _toggleMCPServer(serverName, value),
                    // Disable switch if server is disconnected
                    activeColor: isConnected ? null : Colors.orange,
                  ),
                ],
              ),

              // Server Description (if available)
              if (serverData['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  serverData['description'] as String,
                  style: TextStyle(
                    color: isConnected ? Colors.grey[600] : Colors.grey[500],
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // Disconnection Warning (show if user wants enabled but server is disconnected)
              if (userWantsEnabled && !isConnected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Server is enabled in preferences but currently disconnected. Tools will be available when connection is restored.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Tools Section (show if user wants enabled and has tools)
              if (userWantsEnabled && toolsData.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Tools Header with Bulk Controls
                Row(
                  children: [
                    Icon(
                      Icons.build,
                      color: isConnected ? Colors.blue[600] : Colors.grey[500],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tools ($toolCount):',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isConnected ? null : Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (!widget.isViewOnly) ...[
                      TextButton(
                        onPressed: () =>
                            _toggleAllServerTools(serverName, true),
                        child: Text(
                          'Enable All',
                          style: TextStyle(
                            fontSize: 12,
                            color: isConnected
                                ? Colors.blue[600]
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () =>
                            _toggleAllServerTools(serverName, false),
                        child: Text(
                          'Disable All',
                          style: TextStyle(
                            fontSize: 12,
                            color: isConnected
                                ? Colors.red[600]
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Individual Tool Controls
                ...toolsData.map((toolData) {
                  final toolMap = toolData as Map<String, dynamic>;
                  final toolName = toolMap['name'] as String? ?? 'Unknown';
                  final toolDescription =
                      toolMap['description'] as String? ?? '';
                  final toolUniqueId =
                      toolMap['uniqueId'] as String? ?? '$serverName:$toolName';

                  // Get tool enabled state - defaults to server enabled state
                  final bool toolEnabled =
                      _mcpServerStates[toolUniqueId] ?? userWantsEnabled;

                  return _buildToolCard(
                    serverName: serverName,
                    toolName: toolName,
                    toolDescription: toolDescription,
                    toolUniqueId: toolUniqueId,
                    isEnabled: toolEnabled,
                    isServerEnabled: userWantsEnabled,
                    isServerConnected: isConnected,
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build individual tool card with enable/disable control
  ///
  /// ARCHITECTURAL: Granular tool control component
  Widget _buildToolCard({
    required String serverName,
    required String toolName,
    required String toolDescription,
    required String toolUniqueId,
    required bool isEnabled,
    required bool isServerEnabled,
    required bool isServerConnected,
  }) {
    final bool effectivelyAvailable =
        isEnabled && isServerEnabled && isServerConnected;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: effectivelyAvailable
          ? Colors.green.withValues(alpha: 0.02)
          : isServerConnected
              ? Colors.grey.withValues(alpha: 0.02)
              : Colors.grey.withValues(alpha: 0.01),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: effectivelyAvailable
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Tool Icon
            Icon(
              isEnabled
                  ? Icons.check_circle_outline
                  : Icons.radio_button_unchecked,
              color: isEnabled
                  ? (isServerConnected ? Colors.green : Colors.orange)
                  : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 12),

            // Tool Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toolName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: effectivelyAvailable
                          ? Colors.green[800]
                          : isServerConnected
                              ? (isEnabled
                                  ? Colors.orange[800]
                                  : Colors.grey[600])
                              : Colors.grey[500],
                    ),
                  ),
                  if (toolDescription.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      toolDescription,
                      style: TextStyle(
                        fontSize: 11,
                        color: isServerConnected
                            ? Colors.grey[600]
                            : Colors.grey[500],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Tool Toggle
            if (!widget.isViewOnly && isServerEnabled)
              Switch(
                value: isEnabled,
                onChanged: (value) => _toggleMCPTool(toolUniqueId, value),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: isServerConnected ? null : Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Dialog(
      child: SizedBox(
        width: isLargeScreen ? 700 : double.infinity,
        height: isLargeScreen ? 600 : double.infinity,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.isCreationMode
                ? 'Create Agent'
                : widget.isViewOnly
                    ? 'Agent Details'
                    : 'Edit Agent'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _handleCancel,
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.person), text: 'Basic'),
                Tab(icon: Icon(Icons.tune), text: 'Settings'),
                Tab(icon: Icon(Icons.extension), text: 'MCP'),
                Tab(icon: Icon(Icons.info), text: 'Info'),
              ],
            ),
            actions: widget.isViewOnly
                ? null
                : [
                    TextButton(
                      onPressed: _validationErrors.isEmpty && _hasChanges
                          ? _handleSave
                          : null,
                      child: Text(widget.isCreationMode ? 'Create' : 'Save'),
                    ),
                  ],
          ),
          body: Form(
            key: _formKey,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicSettingsTab(),
                _buildSettingsTab(),
                _buildAdvancedSettingsTab(),
                _buildInfoTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build basic settings tab
  ///
  /// ARCHITECTURAL: Core agent identity settings
  Widget _buildBasicSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agent Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Agent Name *',
              hintText: 'e.g., Flutter Expert, Code Reviewer',
              prefixIcon: const Icon(Icons.badge),
              errorText: _validationErrors['name'],
              counter: Text('${_nameController.text.length}/50'),
            ),
            maxLength: 50,
            readOnly: widget.isViewOnly,
            validator: (value) => _validationErrors['name'],
          ),

          const SizedBox(height: 16),

          // System Prompt
          TextFormField(
            controller: _systemPromptController,
            decoration: InputDecoration(
              labelText: 'System Prompt *',
              hintText: 'Define the agent\'s role and behavior',
              prefixIcon: const Icon(Icons.psychology),
              errorText: _validationErrors['systemPrompt'],
              counter: Text('${_systemPromptController.text.length}/2000'),
            ),
            maxLines: 8,
            maxLength: 2000,
            readOnly: widget.isViewOnly,
            validator: (value) => _validationErrors['systemPrompt'],
          ),

          const SizedBox(height: 16),

          // System Prompt Guidelines
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'System Prompt Best Practices',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Be specific about the assistant\'s role and expertise\n'
                  '• Include behavioral guidelines (tone, formality level)\n'
                  '• Specify output format preferences when relevant\n'
                  '• Keep instructions clear and concise\n'
                  '• Test changes with sample conversations',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build settings tab
  ///
  /// ARCHITECTURAL: Core agent settings with temperature and token controls
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Beta Features Toggle
          SwitchListTile(
            title: const Text('Enable Beta Features'),
            subtitle: const Text('Access to experimental AI capabilities'),
            value: _useBetaFeatures,
            onChanged: widget.isViewOnly
                ? null
                : (value) {
                    setState(() {
                      _useBetaFeatures = value;
                      _validateAndSetChanges();
                    });
                  },
            secondary: const Icon(Icons.science),
          ),

          const Divider(),

          // Reasoner Model Toggle
          SwitchListTile(
            title: const Text('Use Reasoner Model'),
            subtitle: const Text('Advanced reasoning with chain-of-thought'),
            value: _useReasonerModel,
            onChanged: widget.isViewOnly
                ? null
                : (value) {
                    setState(() {
                      _useReasonerModel = value;
                      _validateAndSetChanges();
                    });
                  },
            secondary: const Icon(Icons.auto_awesome),
          ),

          const Divider(),

          // Temperature Control
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.thermostat, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Temperature: ${_temperature.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _temperature,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                onChanged: widget.isViewOnly
                    ? null
                    : (value) {
                        setState(() {
                          _temperature = value;
                          _validateAndSetChanges();
                        });
                      },
              ),
              Text(
                'Controls randomness: Lower = more focused, Higher = more creative',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Max Tokens Control
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.format_list_numbered, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Max Tokens: $_maxTokens',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _maxTokens.toDouble(),
                min: 100,
                max: 32000,
                divisions: 100,
                onChanged: widget.isViewOnly
                    ? null
                    : (value) {
                        setState(() {
                          _maxTokens = value.round();
                          _validateAndSetChanges();
                        });
                      },
              ),
              Text(
                'Maximum response length (roughly 1 token = 0.75 words)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Model Configuration Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.purple[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Model Configuration Tips',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Temperature 0.0-0.3: Focused, deterministic responses\n'
                  '• Temperature 0.4-0.7: Balanced creativity and consistency\n'
                  '• Temperature 0.8-2.0: Highly creative, varied responses\n'
                  '• Higher token limits allow longer, more detailed responses\n'
                  '• Beta features may be unstable but offer cutting-edge capabilities',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build MCP settings tab
  ///
  /// ARCHITECTURAL: MCP server and tool configuration with granular control
  Widget _buildAdvancedSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MCP Configuration Header
          Row(
            children: [
              const Icon(Icons.extension, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Model Context Protocol Configuration',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Configure which MCP servers and tools are available to this agent',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),

          const SizedBox(height: 24),

          // Bulk Controls - Enhanced with sophisticated styling
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, color: Colors.blue[600], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Bulk Operations',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.isViewOnly
                            ? null
                            : () => _setAllMCPServers(true),
                        icon: Icon(Icons.check_circle_outline,
                            size: 16, color: Colors.green[600]),
                        label: Text(
                          'Enable All Servers & Tools',
                          style:
                              TextStyle(fontSize: 13, color: Colors.green[700]),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.green.withValues(alpha: 0.3)),
                          backgroundColor: Colors.green.withValues(alpha: 0.05),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.isViewOnly
                            ? null
                            : () => _setAllMCPServers(false),
                        icon: Icon(Icons.cancel_outlined,
                            size: 16, color: Colors.red[600]),
                        label: Text(
                          'Disable All Servers & Tools',
                          style:
                              TextStyle(fontSize: 13, color: Colors.red[700]),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.red.withValues(alpha: 0.3)),
                          backgroundColor: Colors.red.withValues(alpha: 0.05),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure all servers and their tools at once. Individual servers can be fine-tuned below.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // MCP Servers List
          Text(
            'Available MCP Servers & Tools:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          // Server Cards - Dynamic server data from MCP configuration
          ..._buildMCPServerCards(),

          const SizedBox(height: 24),

          // Configuration Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'MCP Configuration Guide',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Enable/disable entire servers or individual tools\n'
                  '• Disabled servers/tools will not be available to the agent\n'
                  '• Each tool can be independently controlled\n'
                  '• Use "Enable All" for maximum AI capabilities\n'
                  '• Use selective enabling for specialized or restricted agents\n'
                  '• Changes take effect immediately upon saving the agent',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build info tab
  ///
  /// ARCHITECTURAL: Agent metadata and status information
  Widget _buildInfoTab() {
    final agent = widget.agent;

    if (widget.isCreationMode) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Agent Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Information will be available after the agent is created.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...(() {
            final agentValue = agent;
            if (agentValue != null) {
              return [
                _buildInfoCard('Agent ID', agentValue.id),
                _buildInfoCard('Created', agentValue.createdAt.toString()),
                _buildInfoCard(
                    'Last Active', agentValue.lastActiveAt.toString()),
                _buildInfoCard(
                    'Message Count', agentValue.messageCount.toString()),
                _buildInfoCard(
                    'Status', agentValue.isActive ? 'Active' : 'Inactive'),
                if (agentValue.supervisorId != null) ...[
                  (() {
                    final supervisorId = agentValue.supervisorId;
                    if (supervisorId != null) {
                      return _buildInfoCard('Supervisor ID', supervisorId);
                    }
                    return const SizedBox.shrink();
                  })(),
                ],
                if (agentValue.contextFiles.isNotEmpty)
                  _buildInfoCard(
                      'Context Files', agentValue.contextFiles.join(', ')),
                // NOTE: To-Do items are now managed by MCP task server
              ];
            }
            return [const SizedBox.shrink()];
          })(),
        ],
      ),
    );
  }

  /// Build info card widget
  ///
  /// ARCHITECTURAL: Consistent information display component
  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
