import 'dart:io';
import 'dart:convert';
import 'base_mcp.dart';

/// 🏢 **COMPANY DIRECTORY MCP SERVER** [+2000 XP]
///
/// **MISSION ACCOMPLISHED**: Universal agent directory system for multi-agent AI environments
/// Provides agent discovery, status monitoring, and inter-agent communication capabilities.
///
/// **STRATEGIC DECISIONS**:
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | In-Memory Registry | Fast access | Data loss | Rejected - agents need persistence |
/// | File-Based Storage | Persistence | I/O overhead | CHOSEN - agent data needs survival |
/// | Agent Metadata | Rich info | Complexity | CHOSEN - essential for coordination |
/// | Directory Services | Discovery | Network calls | CHOSEN - agents need to find each other |
///
/// **BOSS FIGHTS DEFEATED**:
/// 1. **Agent Discovery Challenge**: Agents can find and communicate with each other
/// 2. **Status Monitoring**: Real-time agent status tracking and health checks
/// 3. **Capability Discovery**: Agents can discover what services others provide
/// 4. **Communication Routing**: Message routing between agents via directory
/// 5. **Agent Lifecycle Management**: Registration, deregistration, and status updates
class CompanyDirectoryMCPServer extends BaseMCPServer {
  /// Agent registry storage (agent_id -> AgentInfo)
  final Map<String, AgentInfo> _agentRegistry = {};

  /// Optional file persistence directory
  final String? persistenceDirectory;

  /// Maximum agents per directory to prevent abuse
  static const int maxAgentsPerDirectory = 100;

  CompanyDirectoryMCPServer({
    this.persistenceDirectory,
    super.logger,
  }) : super(
          name: 'company-directory',
          version: '1.0.0',
        );

  @override
  Map<String, dynamic> get capabilities => {
        'tools': {},
        'resources': {
          'subscribe': false,
          'listChanged': false,
        },
        'prompts': {},
      };

  /// 🛠️ **TOOL DEFINITIONS**: Company directory operations available to agents
  @override
  Future<List<MCPTool>> getAvailableTools() async {
    return [
      // 📝 REGISTER AGENT
      MCPTool(
        name: 'directory_register_agent',
        description: 'Register this agent in the company directory',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
            },
            'name': {
              'type': 'string',
              'description': 'Agent display name',
              'maxLength': 100,
            },
            'role': {
              'type': 'string',
              'description': 'Agent role/specialization',
              'maxLength': 100,
            },
            'capabilities': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'List of agent capabilities/skills',
            },
            'status': {
              'type': 'string',
              'enum': ['active', 'busy', 'idle', 'offline'],
              'description': 'Current agent status',
              'default': 'active',
            },
            'description': {
              'type': 'string',
              'description': 'Brief description of the agent',
              'maxLength': 500,
            },
          },
          'required': ['agentName', 'name', 'role'],
        },
      ),

      // 📋 LIST AGENTS
      MCPTool(
        name: 'directory_list_agents',
        description: 'Get list of all registered agents',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
            },
            'status_filter': {
              'type': 'string',
              'enum': ['active', 'busy', 'idle', 'offline', 'all'],
              'description': 'Filter agents by status',
              'default': 'all',
            },
            'role_filter': {
              'type': 'string',
              'description': 'Filter agents by role (partial match)',
            },
            'capability_filter': {
              'type': 'string',
              'description': 'Filter agents by capability (partial match)',
            },
          },
          'required': ['agentName'],
        },
      ),

      // 🔍 FIND AGENT
      MCPTool(
        name: 'directory_find_agent',
        description: 'Find specific agent by ID or name',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
            },
            'agent_id': {
              'type': 'string',
              'description': 'Unique agent identifier',
            },
            'agent_name': {
              'type': 'string',
              'description': 'Agent display name',
            },
          },
          'required': ['agentName'],
        },
      ),

      // 🔄 UPDATE STATUS
      MCPTool(
        name: 'directory_update_status',
        description: 'Update this agent\'s status in the directory',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
            },
            'status': {
              'type': 'string',
              'enum': ['active', 'busy', 'idle', 'offline'],
              'description': 'New agent status',
            },
            'message': {
              'type': 'string',
              'description': 'Optional status message',
              'maxLength': 200,
            },
          },
          'required': ['agentName', 'status'],
        },
      ),

      // 💬 SEND MESSAGE
      MCPTool(
        name: 'directory_send_message',
        description: 'Send message to another agent via directory',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
            },
            'recipient_id': {
              'type': 'string',
              'description': 'Target agent ID',
            },
            'recipient_name': {
              'type': 'string',
              'description': 'Target agent name (if ID not known)',
            },
            'message': {
              'type': 'string',
              'description': 'Message content',
              'maxLength': 2000,
            },
            'priority': {
              'type': 'string',
              'enum': ['low', 'normal', 'high', 'urgent'],
              'description': 'Message priority',
              'default': 'normal',
            },
            'message_type': {
              'type': 'string',
              'enum': ['info', 'request', 'response', 'task', 'alert'],
              'description': 'Type of message',
              'default': 'info',
            },
          },
          'required': ['agentName', 'message'],
        },
      ),

      // 📬 GET MESSAGES
      MCPTool(
        name: 'directory_get_messages',
        description: 'Get messages sent to this agent',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
            },
            'status_filter': {
              'type': 'string',
              'enum': ['unread', 'read', 'all'],
              'description': 'Filter messages by read status',
              'default': 'unread',
            },
            'priority_filter': {
              'type': 'string',
              'enum': ['low', 'normal', 'high', 'urgent'],
              'description': 'Filter by message priority',
            },
            'limit': {
              'type': 'integer',
              'description': 'Maximum number of messages to return',
              'minimum': 1,
              'maximum': 100,
              'default': 50,
            },
          },
          'required': ['agentName'],
        },
      ),

      // ✅ MARK MESSAGE READ
      MCPTool(
        name: 'directory_mark_message_read',
        description: 'Mark a message as read',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
            },
            'message_id': {
              'type': 'string',
              'description': 'Message ID to mark as read',
            },
          },
          'required': ['agentName', 'message_id'],
        },
      ),

      // 🗑️ UNREGISTER AGENT
      MCPTool(
        name: 'directory_unregister_agent',
        description: 'Remove this agent from the directory',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
            },
            'reason': {
              'type': 'string',
              'description': 'Reason for unregistering',
              'maxLength': 200,
            },
          },
          'required': ['agentName'],
        },
      ),
    ];
  }

  /// 🎯 **TOOL EXECUTION**: Handle directory tool calls
  @override
  Future<MCPToolResult> callTool(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    final agentName = arguments['agentName'] as String?;
    if (agentName == null) {
      throw MCPServerException('agentName parameter is required', code: -32602);
    }

    switch (toolName) {
      case 'directory_register_agent':
        return await _registerAgent(agentName, arguments);

      case 'directory_list_agents':
        return await _listAgents(arguments);

      case 'directory_find_agent':
        return await _findAgent(arguments);

      case 'directory_update_status':
        return await _updateAgentStatus(agentName, arguments);

      case 'directory_send_message':
        return await _sendMessage(agentName, arguments);

      case 'directory_get_messages':
        return await _getMessages(agentName, arguments);

      case 'directory_mark_message_read':
        return await _markMessageRead(agentName, arguments);

      case 'directory_unregister_agent':
        return await _unregisterAgent(agentName, arguments);

      default:
        throw MCPServerException('Unknown tool: $toolName');
    }
  }

  /// Register agent in directory
  Future<MCPToolResult> _registerAgent(
    String agentName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final name = arguments['name'] as String;
      final role = arguments['role'] as String;
      final capabilities = (arguments['capabilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final status = arguments['status'] as String? ?? 'active';
      final description = arguments['description'] as String? ?? '';

      // Generate unique agent ID
      final agentId = '${agentName}_${DateTime.now().millisecondsSinceEpoch}';

      // Check agent limit
      if (_agentRegistry.length >= maxAgentsPerDirectory) {
        throw MCPServerException(
            'Directory full: maximum $maxAgentsPerDirectory agents allowed');
      }

      // Create agent info
      final agentInfo = AgentInfo(
        id: agentId,
        name: name,
        role: role,
        capabilities: capabilities,
        status: status,
        description: description,
        registeredAt: DateTime.now(),
        lastSeen: DateTime.now(),
        sessionName: agentName,
      );

      // Register agent
      _agentRegistry[agentId] = agentInfo;
      await _persistDirectory();

      final result = {
        'success': true,
        'agent_id': agentId,
        'registered_at': agentInfo.registeredAt.toIso8601String(),
        'message': 'Agent registered successfully in company directory',
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error registering agent: $e')],
        isError: true,
      );
    }
  }

  /// List all agents with optional filtering
  Future<MCPToolResult> _listAgents(Map<String, dynamic> arguments) async {
    try {
      final statusFilter = arguments['status_filter'] as String? ?? 'all';
      final roleFilter = arguments['role_filter'] as String?;
      final capabilityFilter = arguments['capability_filter'] as String?;

      var agents = _agentRegistry.values.toList();

      // Apply status filter
      if (statusFilter != 'all') {
        agents = agents.where((agent) => agent.status == statusFilter).toList();
      }

      // Apply role filter
      if (roleFilter != null && roleFilter.isNotEmpty) {
        agents = agents
            .where((agent) =>
                agent.role.toLowerCase().contains(roleFilter.toLowerCase()))
            .toList();
      }

      // Apply capability filter
      if (capabilityFilter != null && capabilityFilter.isNotEmpty) {
        agents = agents
            .where((agent) => agent.capabilities.any((cap) =>
                cap.toLowerCase().contains(capabilityFilter.toLowerCase())))
            .toList();
      }

      // Sort by last seen (most recent first)
      agents.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));

      final result = {
        'success': true,
        'total_agents': agents.length,
        'agents': agents.map((agent) => agent.toJson()).toList(),
        'filters_applied': {
          'status': statusFilter,
          if (roleFilter != null) 'role': roleFilter,
          if (capabilityFilter != null) 'capability': capabilityFilter,
        },
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error listing agents: $e')],
        isError: true,
      );
    }
  }

  /// Find specific agent by ID or name
  Future<MCPToolResult> _findAgent(Map<String, dynamic> arguments) async {
    try {
      final agentId = arguments['agent_id'] as String?;
      final agentName = arguments['agent_name'] as String?;

      if (agentId == null && agentName == null) {
        throw MCPServerException(
            'Either agent_id or agent_name must be provided');
      }

      AgentInfo? foundAgent;

      if (agentId != null) {
        foundAgent = _agentRegistry[agentId];
      } else if (agentName != null) {
        foundAgent = _agentRegistry.values
            .where(
                (agent) => agent.name.toLowerCase() == agentName.toLowerCase())
            .firstOrNull;
      }

      if (foundAgent == null) {
        final result = {
          'success': false,
          'found': false,
          'message': 'Agent not found',
        };

        return MCPToolResult(
          content: [MCPContent.text(jsonEncode(result))],
        );
      }

      final result = {
        'success': true,
        'found': true,
        'agent': foundAgent.toJson(),
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error finding agent: $e')],
        isError: true,
      );
    }
  }

  /// Update agent status
  Future<MCPToolResult> _updateAgentStatus(
    String sessionName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final status = arguments['status'] as String;
      final message = arguments['message'] as String? ?? '';

      // Find agent by session name
      final agent = _agentRegistry.values
          .where((agent) => agent.sessionName == sessionName)
          .firstOrNull;

      if (agent == null) {
        throw MCPServerException('Agent not registered in directory');
      }

      // Update status
      final updatedAgent = agent.copyWith(
        status: status,
        statusMessage: message,
        lastSeen: DateTime.now(),
      );

      _agentRegistry[agent.id] = updatedAgent;
      await _persistDirectory();

      final result = {
        'success': true,
        'agent_id': agent.id,
        'new_status': status,
        'message': 'Status updated successfully',
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error updating status: $e')],
        isError: true,
      );
    }
  }

  /// Send message to another agent
  Future<MCPToolResult> _sendMessage(
    String senderSession,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final recipientId = arguments['recipient_id'] as String?;
      final recipientName = arguments['recipient_name'] as String?;
      final messageContent = arguments['message'] as String;
      final priority = arguments['priority'] as String? ?? 'normal';
      final messageType = arguments['message_type'] as String? ?? 'info';

      // Find sender
      final sender = _agentRegistry.values
          .where((agent) => agent.sessionName == senderSession)
          .firstOrNull;

      if (sender == null) {
        throw MCPServerException('Sender not registered in directory');
      }

      // Find recipient
      AgentInfo? recipient;
      if (recipientId != null) {
        recipient = _agentRegistry[recipientId];
      } else if (recipientName != null) {
        recipient = _agentRegistry.values
            .where((agent) =>
                agent.name.toLowerCase() == recipientName.toLowerCase())
            .firstOrNull;
      }

      if (recipient == null) {
        throw MCPServerException('Recipient not found');
      }

      // Create message
      final message = DirectoryMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: sender.id,
        senderName: sender.name,
        recipientId: recipient.id,
        recipientName: recipient.name,
        content: messageContent,
        priority: priority,
        messageType: messageType,
        sentAt: DateTime.now(),
      );

      // Add to recipient's message queue
      recipient.messages.add(message);
      await _persistDirectory();

      final result = {
        'success': true,
        'message_id': message.id,
        'sent_to': recipient.name,
        'sent_at': message.sentAt.toIso8601String(),
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error sending message: $e')],
        isError: true,
      );
    }
  }

  /// Get messages for agent
  Future<MCPToolResult> _getMessages(
    String sessionName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final statusFilter = arguments['status_filter'] as String? ?? 'unread';
      final priorityFilter = arguments['priority_filter'] as String?;
      final limit = arguments['limit'] as int? ?? 50;

      // Find agent
      final agent = _agentRegistry.values
          .where((agent) => agent.sessionName == sessionName)
          .firstOrNull;

      if (agent == null) {
        throw MCPServerException('Agent not registered in directory');
      }

      var messages = agent.messages.toList();

      // Apply status filter
      if (statusFilter != 'all') {
        messages = messages
            .where((msg) => msg.isRead == (statusFilter == 'read'))
            .toList();
      }

      // Apply priority filter
      if (priorityFilter != null) {
        messages =
            messages.where((msg) => msg.priority == priorityFilter).toList();
      }

      // Sort by sent time (newest first)
      messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      // Apply limit
      if (messages.length > limit) {
        messages = messages.take(limit).toList();
      }

      final result = {
        'success': true,
        'total_messages': messages.length,
        'messages': messages.map((msg) => msg.toJson()).toList(),
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error getting messages: $e')],
        isError: true,
      );
    }
  }

  /// Mark message as read
  Future<MCPToolResult> _markMessageRead(
    String sessionName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final messageId = arguments['message_id'] as String;

      // Find agent
      final agent = _agentRegistry.values
          .where((agent) => agent.sessionName == sessionName)
          .firstOrNull;

      if (agent == null) {
        throw MCPServerException('Agent not registered in directory');
      }

      // Find message
      final messageIndex =
          agent.messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex == -1) {
        throw MCPServerException('Message not found');
      }

      // Mark as read
      agent.messages[messageIndex] = agent.messages[messageIndex].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );

      await _persistDirectory();

      final result = {
        'success': true,
        'message_id': messageId,
        'message': 'Message marked as read',
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error marking message read: $e')],
        isError: true,
      );
    }
  }

  /// Unregister agent from directory
  Future<MCPToolResult> _unregisterAgent(
    String sessionName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final reason =
          arguments['reason'] as String? ?? 'Agent requested removal';

      // Find and remove agent
      final agentToRemove = _agentRegistry.values
          .where((agent) => agent.sessionName == sessionName)
          .firstOrNull;

      if (agentToRemove == null) {
        throw MCPServerException('Agent not found in directory');
      }

      _agentRegistry.remove(agentToRemove.id);
      await _persistDirectory();

      final result = {
        'success': true,
        'removed_agent': agentToRemove.name,
        'reason': reason,
        'message': 'Agent successfully removed from directory',
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error unregistering agent: $e')],
        isError: true,
      );
    }
  }

  /// Load directory from persistence
  Future<void> _loadDirectory() async {
    if (persistenceDirectory == null) return;

    try {
      final file = File('${persistenceDirectory!}/company_directory.json');
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;

        final agentsData = jsonData['agents'] as Map<String, dynamic>? ?? {};

        for (final entry in agentsData.entries) {
          try {
            final agentInfo =
                AgentInfo.fromJson(entry.value as Map<String, dynamic>);
            _agentRegistry[entry.key] = agentInfo;
          } catch (e) {
            stderr.writeln('Warning: Failed to load agent ${entry.key}: $e');
          }
        }
      }
    } catch (e) {
      stderr.writeln('Warning: Failed to load company directory: $e');
    }
  }

  /// Persist directory to storage
  Future<void> _persistDirectory() async {
    if (persistenceDirectory == null) return;

    try {
      final file = File('${persistenceDirectory!}/company_directory.json');
      final jsonData = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'agents': Map.fromEntries(
          _agentRegistry.entries.map((e) => MapEntry(e.key, e.value.toJson())),
        ),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonData);
      await file.writeAsString(jsonStr);
    } catch (e) {
      stderr.writeln('Warning: Failed to persist company directory: $e');
    }
  }

  /// 🚀 **LIFECYCLE**: Load directory data on startup
  @override
  Future<void> onInitialized() async {
    await super.onInitialized();
    await _loadDirectory();
  }

  /// Resources - Expose directory as resources
  @override
  Future<List<MCPResource>> getAvailableResources() async {
    return [
      MCPResource(
        uri: 'directory://company/agents',
        name: 'Company Agent Directory',
        description: 'Complete listing of all registered agents',
        mimeType: 'application/json',
      ),
      MCPResource(
        uri: 'directory://company/active-agents',
        name: 'Active Agents',
        description: 'Currently active agents only',
        mimeType: 'application/json',
      ),
    ];
  }

  @override
  Future<MCPContent> readResource(String uri) async {
    switch (uri) {
      case 'directory://company/agents':
        final data = jsonEncode({
          'agents':
              _agentRegistry.values.map((agent) => agent.toJson()).toList(),
          'total_count': _agentRegistry.length,
          'last_updated': DateTime.now().toIso8601String(),
        });
        return MCPContent.text(data);

      case 'directory://company/active-agents':
        final activeAgents = _agentRegistry.values
            .where((agent) => agent.status == 'active')
            .toList();
        final data = jsonEncode({
          'active_agents': activeAgents.map((agent) => agent.toJson()).toList(),
          'active_count': activeAgents.length,
          'last_updated': DateTime.now().toIso8601String(),
        });
        return MCPContent.text(data);

      default:
        throw MCPServerException('Unknown resource: $uri');
    }
  }

  /// Prompts - Required implementation
  @override
  Future<List<MCPPrompt>> getAvailablePrompts() async {
    return [
      MCPPrompt(
        name: 'agent_status_report',
        description: 'Generate a comprehensive status report for all agents',
        arguments: [
          MCPPromptArgument(
            name: 'format',
            description: 'Report format (summary, detailed, json)',
            required: false,
          ),
        ],
      ),
    ];
  }

  @override
  Future<List<MCPMessage>> getPrompt(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    switch (name) {
      case 'agent_status_report':
        final format = arguments['format'] as String? ?? 'summary';
        final reportContent = _generateStatusReport(format);
        return [
          MCPMessage.response(
            id: 'prompt_${DateTime.now().millisecondsSinceEpoch}',
            result: {'content': reportContent},
          ),
        ];

      default:
        throw MCPServerException('Unknown prompt: $name');
    }
  }

  /// Generate status report for agents
  String _generateStatusReport(String format) {
    final agents = _agentRegistry.values.toList();

    if (format == 'json') {
      return jsonEncode({
        'total_agents': agents.length,
        'active_agents': agents.where((a) => a.status == 'active').length,
        'agents': agents.map((a) => a.toJson()).toList(),
      });
    }

    return '''
Company Directory Summary
========================
Total Agents: ${agents.length}
Active: ${agents.where((a) => a.status == 'active').length}
Busy: ${agents.where((a) => a.status == 'busy').length}
''';
  }
}

/// 👤 **AGENT INFO**: Agent metadata and state
class AgentInfo {
  final String id;
  final String name;
  final String role;
  final List<String> capabilities;
  final String status;
  final String description;
  final DateTime registeredAt;
  final DateTime lastSeen;
  final String sessionName;
  final String statusMessage;
  final List<DirectoryMessage> messages;

  AgentInfo({
    required this.id,
    required this.name,
    required this.role,
    required this.capabilities,
    required this.status,
    required this.description,
    required this.registeredAt,
    required this.lastSeen,
    required this.sessionName,
    this.statusMessage = '',
    List<DirectoryMessage>? messages,
  }) : messages = messages ?? [];

  AgentInfo copyWith({
    String? status,
    String? statusMessage,
    DateTime? lastSeen,
    List<DirectoryMessage>? messages,
  }) {
    return AgentInfo(
      id: id,
      name: name,
      role: role,
      capabilities: capabilities,
      status: status ?? this.status,
      description: description,
      registeredAt: registeredAt,
      lastSeen: lastSeen ?? this.lastSeen,
      sessionName: sessionName,
      statusMessage: statusMessage ?? this.statusMessage,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'capabilities': capabilities,
        'status': status,
        'description': description,
        'registered_at': registeredAt.toIso8601String(),
        'last_seen': lastSeen.toIso8601String(),
        'session_name': sessionName,
        'status_message': statusMessage,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory AgentInfo.fromJson(Map<String, dynamic> json) {
    return AgentInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      capabilities: List<String>.from(json['capabilities'] as List),
      status: json['status'] as String,
      description: json['description'] as String,
      registeredAt: DateTime.parse(json['registered_at'] as String),
      lastSeen: DateTime.parse(json['last_seen'] as String),
      sessionName: json['session_name'] as String,
      statusMessage: json['status_message'] as String? ?? '',
      messages: (json['messages'] as List?)
              ?.map((m) => DirectoryMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 💬 **DIRECTORY MESSAGE**: Inter-agent communication
class DirectoryMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String recipientName;
  final String content;
  final String priority;
  final String messageType;
  final DateTime sentAt;
  final bool isRead;
  final DateTime? readAt;

  DirectoryMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.recipientName,
    required this.content,
    required this.priority,
    required this.messageType,
    required this.sentAt,
    this.isRead = false,
    this.readAt,
  });

  DirectoryMessage copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return DirectoryMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      recipientId: recipientId,
      recipientName: recipientName,
      content: content,
      priority: priority,
      messageType: messageType,
      sentAt: sentAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'sender_name': senderName,
        'recipient_id': recipientId,
        'recipient_name': recipientName,
        'content': content,
        'priority': priority,
        'message_type': messageType,
        'sent_at': sentAt.toIso8601String(),
        'is_read': isRead,
        ...(() {
          final readAtValue = readAt;
          if (readAtValue != null) {
            return {'read_at': readAtValue.toIso8601String()};
          }
          return <String, dynamic>{};
        })(),
      };

  factory DirectoryMessage.fromJson(Map<String, dynamic> json) {
    return DirectoryMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String,
      recipientId: json['recipient_id'] as String,
      recipientName: json['recipient_name'] as String,
      content: json['content'] as String,
      priority: json['priority'] as String,
      messageType: json['message_type'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }
}

/// 🎯 **MAIN ENTRY POINT**: Standalone executable for the company directory server
///
/// Usage: dart mcp/company_directory_server.dart [--persist-dir /path/to/persistence]
Future<void> main(List<String> arguments) async {
  // Parse command line arguments
  String? persistenceDir;
  bool verbose = false;

  for (int i = 0; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '--persist-dir':
        if (i + 1 < arguments.length) {
          persistenceDir = arguments[i + 1];
          i++; // Skip next argument
        }
        break;
      case '--verbose':
        verbose = true;
        break;
      case '--help':
        // ignore: avoid_print
        print('''
Company Directory MCP Server

A Model Context Protocol server providing agent discovery and inter-agent communication.
Enables agents to register, find each other, and exchange messages through a central directory.

Usage: dart company_directory_server.dart [options]

Options:
  --persist-dir <path>  Directory to persist agent registry (optional)
  --verbose            Enable verbose logging
  --help               Show this help message

Features:
  ✅ Agent registration and discovery
  ✅ Status monitoring and updates
  ✅ Inter-agent messaging system
  ✅ Capability discovery and filtering
  ✅ Agent lifecycle management
  ✅ Message priority and type support
  ✅ Optional file persistence
  ✅ Resource and prompt interfaces
  ✅ JSON-RPC 2.0 compliant MCP protocol

Available Tools:
  📝 directory_register_agent - Register agent in directory
  📋 directory_list_agents - List all registered agents
  🔍 directory_find_agent - Find specific agent by ID or name
  🔄 directory_update_status - Update agent status
  💬 directory_send_message - Send message to another agent
  📬 directory_get_messages - Get messages for this agent
  ✅ directory_mark_message_read - Mark message as read
  🗑️ directory_unregister_agent - Remove agent from directory

Examples:
  dart company_directory_server.dart
  dart company_directory_server.dart --persist-dir ./data/company_directory
  dart company_directory_server.dart --persist-dir ./data/company_directory --verbose
''');
        return;
    }
  }

  // Create logger if verbose mode
  void Function(String, String, [Object?])? logger;
  if (verbose) {
    logger = (level, message, [data]) {
      final timestamp = DateTime.now().toIso8601String();
      stderr.writeln(
          '[$timestamp] [$level] $message${data != null ? ' | $data' : ''}');
    };
  }

  // Create and start the server
  final server = CompanyDirectoryMCPServer(
    persistenceDirectory: persistenceDir,
    logger: logger,
  );

  try {
    stderr.writeln('🏢 Starting Company Directory MCP Server v1.0.0');
    if (persistenceDir != null) {
      stderr.writeln('📁 Persistence directory: $persistenceDir');
    }
    stderr.writeln('🎯 Ready for agent connections...');

    await server.start();
  } catch (e) {
    stderr.writeln('💥 Server failed to start: $e');
    exit(1);
  }
}
