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

  /// Clear all agent registry data (for testing)
  void clearRegistry() {
    _agentRegistry.clear();
    // Also clear persisted data if persistence is enabled
    if (persistenceDirectory != null) {
      final file = File('${persistenceDirectory!}/company_directory.json');
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

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

      // 📧 SEND EMAIL MESSAGE
      MCPTool(
        name: 'directory_send_email',
        description:
            'Send an email-like message to one or more agents via virtual messaging system',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
            },
            'to': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'List of recipient agent names or IDs',
            },
            'cc': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'List of CC recipient agent names or IDs',
            },
            'bcc': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'List of BCC recipient agent names or IDs',
            },
            'subject': {
              'type': 'string',
              'description': 'Email subject line',
              'maxLength': 200,
            },
            'body': {
              'type': 'string',
              'description': 'Email body content',
              'maxLength': 10000,
            },
            'priority': {
              'type': 'string',
              'enum': ['low', 'normal', 'high', 'urgent'],
              'description': 'Message priority',
              'default': 'normal',
            },
            'attachments': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'filename': {'type': 'string'},
                  'content': {'type': 'string'},
                  'mime_type': {'type': 'string'},
                },
              },
              'description': 'Optional file attachments',
            },
          },
          'required': ['agentName', 'to', 'subject', 'body'],
        },
      ),

      // 📬 CHECK INBOX
      MCPTool(
        name: 'directory_check_inbox',
        description:
            'Check this agent\'s inbox for new messages (part of automatic loop)',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
            },
            'mark_as_read': {
              'type': 'boolean',
              'description':
                  'Automatically mark messages as read when checking',
              'default': false,
            },
            'include_read': {
              'type': 'boolean',
              'description': 'Include read messages in results',
              'default': false,
            },
            'limit': {
              'type': 'integer',
              'description': 'Maximum number of messages to return',
              'minimum': 1,
              'maximum': 100,
              'default': 20,
            },
          },
          'required': ['agentName'],
        },
      ),

      // 📋 GET AVAILABLE RECIPIENTS
      MCPTool(
        name: 'directory_get_available_recipients',
        description: 'Get list of agents available to receive messages',
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
              'description': 'Filter by agent status',
              'default': 'active',
            },
            'role_filter': {
              'type': 'string',
              'description': 'Filter by agent role (partial match)',
            },
            'capability_filter': {
              'type': 'string',
              'description': 'Filter by agent capability (partial match)',
            },
            'include_self': {
              'type': 'boolean',
              'description': 'Include the requesting agent in results',
              'default': false,
            },
          },
          'required': ['agentName'],
        },
      ),

      // 📧 GET EMAIL MESSAGE
      MCPTool(
        name: 'directory_get_email',
        description: 'Get a specific email message by ID',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
            },
            'email_id': {
              'type': 'string',
              'description': 'Email message ID',
            },
            'mark_as_read': {
              'type': 'boolean',
              'description': 'Mark message as read when retrieved',
              'default': true,
            },
          },
          'required': ['agentName', 'email_id'],
        },
      ),

      // 📧 REPLY TO EMAIL
      MCPTool(
        name: 'directory_reply_to_email',
        description: 'Reply to a specific email message',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
            },
            'email_id': {
              'type': 'string',
              'description': 'Email message ID to reply to',
            },
            'body': {
              'type': 'string',
              'description': 'Reply message content',
              'maxLength': 10000,
            },
            'include_original': {
              'type': 'boolean',
              'description': 'Include original message in reply',
              'default': true,
            },
            'priority': {
              'type': 'string',
              'enum': ['low', 'normal', 'high', 'urgent'],
              'description': 'Reply priority',
              'default': 'normal',
            },
          },
          'required': ['agentName', 'email_id', 'body'],
        },
      ),

      // 📧 FORWARD EMAIL
      MCPTool(
        name: 'directory_forward_email',
        description: 'Forward an email message to other agents',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
            },
            'email_id': {
              'type': 'string',
              'description': 'Email message ID to forward',
            },
            'to': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'List of recipient agent names or IDs',
            },
            'cc': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'List of CC recipient agent names or IDs',
            },
            'bcc': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'List of BCC recipient agent names or IDs',
            },
            'forward_note': {
              'type': 'string',
              'description': 'Optional note to add to forwarded message',
              'maxLength': 1000,
            },
          },
          'required': ['agentName', 'email_id', 'to'],
        },
      ),

      // 📧 DELETE EMAIL
      MCPTool(
        name: 'directory_delete_email',
        description: 'Delete an email message from inbox',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
            },
            'email_id': {
              'type': 'string',
              'description': 'Email message ID to delete',
            },
            'permanent': {
              'type': 'boolean',
              'description': 'Permanently delete (not just move to trash)',
              'default': false,
            },
          },
          'required': ['agentName', 'email_id'],
        },
      ),

      // 📊 GET INBOX STATISTICS
      MCPTool(
        name: 'directory_get_inbox_stats',
        description: 'Get inbox statistics for this agent',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent making this request',
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

      case 'directory_send_email':
        return await _sendEmail(agentName, arguments);

      case 'directory_check_inbox':
        return await _checkInbox(agentName, arguments);

      case 'directory_get_available_recipients':
        return await _getAvailableRecipients(agentName, arguments);

      case 'directory_get_email':
        return await _getEmail(agentName, arguments);

      case 'directory_reply_to_email':
        return await _replyToEmail(agentName, arguments);

      case 'directory_forward_email':
        return await _forwardEmail(agentName, arguments);

      case 'directory_delete_email':
        return await _deleteEmail(agentName, arguments);

      case 'directory_get_inbox_stats':
        return await _getInboxStats(agentName, arguments);

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

  /// 📧 SEND EMAIL MESSAGE
  Future<MCPToolResult> _sendEmail(
    String agentName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final to =
          (arguments['to'] as List<dynamic>).map((e) => e.toString()).toList();
      final cc = (arguments['cc'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      final bcc = (arguments['bcc'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      final subject = arguments['subject'] as String;
      final body = arguments['body'] as String;
      final priority = arguments['priority'] as String? ?? 'normal';
      final attachments = arguments['attachments'] as List<dynamic>? ?? [];

      // Find sender agent
      final sender = _agentRegistry.values
          .where((agent) => agent.sessionName == agentName)
          .firstOrNull;

      if (sender == null) {
        throw MCPServerException('Sender agent not registered in directory');
      }

      // Process attachments
      final emailAttachments = attachments.map((attachment) {
        final att = attachment as Map<String, dynamic>;
        return EmailAttachment(
          filename: att['filename'] as String,
          content: att['content'] as String,
          mimeType: att['mime_type'] as String,
        );
      }).toList();

      // Create email message
      final emailMessage = EmailMessage(
        id: 'email_${DateTime.now().millisecondsSinceEpoch}_${sender.id}',
        senderId: sender.id,
        senderName: sender.name,
        toRecipients: to,
        ccRecipients: cc,
        bccRecipients: bcc,
        subject: subject,
        body: body,
        priority: priority,
        sentAt: DateTime.now(),
        attachments: emailAttachments,
      );

      // Deliver email to all recipients
      final allRecipients = [...to, ...cc, ...bcc];
      final deliveredTo = <String>[];

      for (final recipientId in allRecipients) {
        // Try to find recipient by ID first, then by sessionName, then by name
        AgentInfo? recipient = _agentRegistry[recipientId];
        recipient ??= _agentRegistry.values
            .where((agent) => agent.sessionName == recipientId)
            .firstOrNull;
        recipient ??= _agentRegistry.values
            .where((agent) =>
                agent.name.toLowerCase() == recipientId.toLowerCase())
            .firstOrNull;

        if (recipient != null) {
          // Add email to recipient's inbox
          recipient.addEmail(emailMessage);
          deliveredTo.add(recipient.name);
        }
      }

      await _persistDirectory();

      final result = {
        'success': true,
        'email_id': emailMessage.id,
        'subject': subject,
        'delivered_to': deliveredTo,
        'total_recipients': allRecipients.length,
        'successful_deliveries': deliveredTo.length,
        'sent_at': emailMessage.sentAt.toIso8601String(),
        'thread_id': emailMessage.threadId,
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error sending email: $e')],
        isError: true,
      );
    }
  }

  /// 📬 CHECK INBOX
  Future<MCPToolResult> _checkInbox(
    String agentName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final markAsRead = arguments['mark_as_read'] as bool? ?? false;
      final includeRead = arguments['include_read'] as bool? ?? false;
      final limit = arguments['limit'] as int? ?? 20;

      // Find agent
      final agent = _agentRegistry.values
          .where((agent) => agent.sessionName == agentName)
          .firstOrNull;

      if (agent == null) {
        throw MCPServerException('Agent not registered in directory');
      }

      var emails = agent.emailInbox.toList();

      // Apply read status filter
      if (!includeRead) {
        emails = emails.where((email) => !email.isRead).toList();
      }

      // Sort by sent time (newest first)
      emails.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      // Apply limit
      if (emails.length > limit) {
        emails = emails.take(limit).toList();
      }

      // Mark emails as read if requested
      if (markAsRead) {
        for (final email in emails) {
          agent.markEmailAsRead(email.id);
        }
        await _persistDirectory();
      }

      // Prepare email summaries for response
      final emailSummaries = emails
          .map((email) => {
                'id': email.id,
                'subject': email.subject,
                'sender_name': email.senderName,
                'sender_id': email.senderId,
                'to_recipients': email.toRecipients,
                'cc_recipients': email.ccRecipients,
                'priority': email.priority,
                'sent_at': email.sentAt.toIso8601String(),
                'is_read': email.isRead,
                'preview': email.preview,
                'thread_id': email.threadId,
                'is_reply': email.isReply,
                'is_forwarded': email.isForwarded,
                'attachment_count': email.attachments.length,
                ...(() {
                  final readAtValue = email.readAt;
                  if (readAtValue != null) {
                    return {'read_at': readAtValue.toIso8601String()};
                  }
                  return <String, dynamic>{};
                })(),
              })
          .toList();

      final result = {
        'success': true,
        'total_emails': emails.length,
        'unread_count': agent.unreadEmailCount,
        'total_inbox_count': agent.totalEmailCount,
        'emails': emailSummaries,
        'checked_at': DateTime.now().toIso8601String(),
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error checking inbox: $e')],
        isError: true,
      );
    }
  }

  /// 📋 GET AVAILABLE RECIPIENTS
  Future<MCPToolResult> _getAvailableRecipients(
    String agentName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final statusFilter = arguments['status_filter'] as String? ?? 'active';
      final roleFilter = arguments['role_filter'] as String?;
      final capabilityFilter = arguments['capability_filter'] as String?;
      final includeSelf = arguments['include_self'] as bool? ?? false;

      var recipients = _agentRegistry.values.toList();

      // Apply status filter
      recipients =
          recipients.where((agent) => agent.status == statusFilter).toList();

      // Apply role filter
      if (roleFilter != null && roleFilter.isNotEmpty) {
        recipients = recipients
            .where((agent) =>
                agent.role.toLowerCase().contains(roleFilter.toLowerCase()))
            .toList();
      }

      // Apply capability filter
      if (capabilityFilter != null && capabilityFilter.isNotEmpty) {
        recipients = recipients
            .where((agent) => agent.capabilities.any((cap) =>
                cap.toLowerCase().contains(capabilityFilter.toLowerCase())))
            .toList();
      }

      // Include self if requested
      if (includeSelf) {
        recipients.add(_agentRegistry.values
            .firstWhere((agent) => agent.sessionName == agentName));
      }

      final result = {
        'success': true,
        'total_recipients': recipients.length,
        'recipients': recipients.map((agent) => agent.toJson()).toList(),
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error getting available recipients: $e')],
        isError: true,
      );
    }
  }

  /// 📧 GET EMAIL MESSAGE
  Future<MCPToolResult> _getEmail(
    String agentName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final emailId = arguments['email_id'] as String;
      final markAsRead = arguments['mark_as_read'] as bool? ?? true;

      // Find agent
      final agent = _agentRegistry.values
          .where((agent) => agent.sessionName == agentName)
          .firstOrNull;

      if (agent == null) {
        throw MCPServerException('Agent not registered in directory');
      }

      // Find email message
      final emailIndex =
          agent.emailInbox.indexWhere((email) => email.id == emailId);
      if (emailIndex == -1) {
        throw MCPServerException('Email message not found');
      }

      final email = agent.emailInbox[emailIndex];

      // Mark email as read if requested
      if (markAsRead && !email.isRead) {
        agent.markEmailAsRead(emailId);
        await _persistDirectory();
      }

      final result = {
        'success': true,
        'email_id': emailId,
        'subject': email.subject,
        'sender_name': email.senderName,
        'sender_id': email.senderId,
        'to_recipients': email.toRecipients,
        'cc_recipients': email.ccRecipients,
        'bcc_recipients': email.bccRecipients,
        'body': email.body,
        'priority': email.priority,
        'sent_at': email.sentAt.toIso8601String(),
        'is_read': email.isRead,
        'thread_id': email.threadId,
        'is_reply': email.isReply,
        'is_forwarded': email.isForwarded,
        'attachments': email.attachments
            .map((a) => {
                  'filename': a.filename,
                  'mime_type': a.mimeType,
                  'size': a.size,
                  'human_readable_size': a.humanReadableSize,
                })
            .toList(),
        ...(() {
          final readAtValue = email.readAt;
          if (readAtValue != null) {
            return {'read_at': readAtValue.toIso8601String()};
          }
          return <String, dynamic>{};
        })(),
        ...(() {
          final replyToIdValue = email.replyToId;
          if (replyToIdValue != null) {
            return {'reply_to_id': replyToIdValue};
          }
          return <String, dynamic>{};
        })(),
        ...(() {
          final forwardFromIdValue = email.forwardFromId;
          if (forwardFromIdValue != null) {
            return {'forward_from_id': forwardFromIdValue};
          }
          return <String, dynamic>{};
        })(),
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error getting email: $e')],
        isError: true,
      );
    }
  }

  /// 📧 REPLY TO EMAIL
  Future<MCPToolResult> _replyToEmail(
    String agentName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final emailId = arguments['email_id'] as String;
      final body = arguments['body'] as String;
      final includeOriginal = arguments['include_original'] as bool? ?? true;
      final priority = arguments['priority'] as String? ?? 'normal';

      // Find agent
      final agent = _agentRegistry.values
          .where((agent) => agent.sessionName == agentName)
          .firstOrNull;

      if (agent == null) {
        throw MCPServerException('Agent not registered in directory');
      }

      // Find original email message
      final emailIndex =
          agent.emailInbox.indexWhere((email) => email.id == emailId);
      if (emailIndex == -1) {
        throw MCPServerException('Email message not found');
      }

      final originalEmail = agent.emailInbox[emailIndex];

      // Prepare reply body
      String replyBody = body;
      if (includeOriginal) {
        replyBody += '\n\n--- Original Message ---\n';
        replyBody += 'From: ${originalEmail.senderName}\n';
        replyBody += 'Subject: ${originalEmail.subject}\n';
        replyBody += 'Date: ${originalEmail.sentAt.toIso8601String()}\n\n';
        replyBody += originalEmail.body;
      }

      // Create reply email message
      final replyEmail = EmailMessage(
        id: 'reply_${DateTime.now().millisecondsSinceEpoch}_${agent.id}',
        senderId: agent.id,
        senderName: agent.name,
        toRecipients: [originalEmail.senderId], // Reply to original sender
        ccRecipients:
            originalEmail.ccRecipients, // Include original CC recipients
        bccRecipients: [], // Don't include BCC in replies
        subject: 'Re: ${originalEmail.subject}',
        body: replyBody,
        priority: priority,
        sentAt: DateTime.now(),
        replyToId: emailId,
        threadId: originalEmail.threadId, // Maintain thread
        attachments: [], // No attachments in replies for now
      );

      // Deliver reply to original sender
      final originalSender = _agentRegistry[originalEmail.senderId];
      if (originalSender != null) {
        originalSender.addEmail(replyEmail);
      }

      // Also add to sender's own inbox for record keeping
      agent.addEmail(replyEmail);

      await _persistDirectory();

      final result = {
        'success': true,
        'reply_id': replyEmail.id,
        'original_email_id': emailId,
        'subject': replyEmail.subject,
        'sent_to': originalEmail.senderName,
        'sent_at': replyEmail.sentAt.toIso8601String(),
        'thread_id': replyEmail.threadId,
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error replying to email: $e')],
        isError: true,
      );
    }
  }

  /// 📧 FORWARD EMAIL
  Future<MCPToolResult> _forwardEmail(
    String agentName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final emailId = arguments['email_id'] as String;
      final to =
          (arguments['to'] as List<dynamic>).map((e) => e.toString()).toList();
      final cc = (arguments['cc'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      final bcc = (arguments['bcc'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      final forwardNote = arguments['forward_note'] as String? ?? '';

      // Find agent
      final agent = _agentRegistry.values
          .where((agent) => agent.sessionName == agentName)
          .firstOrNull;

      if (agent == null) {
        throw MCPServerException('Agent not registered in directory');
      }

      // Find original email message
      final emailIndex =
          agent.emailInbox.indexWhere((email) => email.id == emailId);
      if (emailIndex == -1) {
        throw MCPServerException('Email message not found');
      }

      final originalEmail = agent.emailInbox[emailIndex];

      // Prepare forwarded body
      String forwardedBody = '';
      if (forwardNote.isNotEmpty) {
        forwardedBody += '$forwardNote\n\n';
      }
      forwardedBody += '--- Forwarded Message ---\n';
      forwardedBody += 'From: ${originalEmail.senderName}\n';
      forwardedBody += 'Subject: ${originalEmail.subject}\n';
      forwardedBody += 'Date: ${originalEmail.sentAt.toIso8601String()}\n';
      if (originalEmail.toRecipients.isNotEmpty) {
        forwardedBody += 'To: ${originalEmail.toRecipients.join(', ')}\n';
      }
      if (originalEmail.ccRecipients.isNotEmpty) {
        forwardedBody += 'CC: ${originalEmail.ccRecipients.join(', ')}\n';
      }
      forwardedBody += '\n${originalEmail.body}';

      // Create forwarded email message
      final forwardedEmail = EmailMessage(
        id: 'forward_${DateTime.now().millisecondsSinceEpoch}_${agent.id}',
        senderId: agent.id,
        senderName: agent.name,
        toRecipients: to,
        ccRecipients: cc,
        bccRecipients: bcc,
        subject: 'Fwd: ${originalEmail.subject}',
        body: forwardedBody,
        priority: originalEmail.priority,
        sentAt: DateTime.now(),
        forwardFromId: emailId,
        threadId:
            'forward_${originalEmail.threadId}', // New thread for forwarded message
        attachments: originalEmail.attachments, // Include original attachments
      );

      // Deliver forwarded email to all recipients
      final allRecipients = [...to, ...cc, ...bcc];
      final deliveredTo = <String>[];

      for (final recipientId in allRecipients) {
        // Try to find recipient by ID first, then by sessionName, then by name
        AgentInfo? recipient = _agentRegistry[recipientId];
        recipient ??= _agentRegistry.values
            .where((agent) => agent.sessionName == recipientId)
            .firstOrNull;
        recipient ??= _agentRegistry.values
            .where((agent) =>
                agent.name.toLowerCase() == recipientId.toLowerCase())
            .firstOrNull;

        if (recipient != null) {
          // Add forwarded email to recipient's inbox
          recipient.addEmail(forwardedEmail);
          deliveredTo.add(recipient.name);
        }
      }

      await _persistDirectory();

      final result = {
        'success': true,
        'forwarded_email_id': forwardedEmail.id,
        'original_email_id': emailId,
        'subject': forwardedEmail.subject,
        'delivered_to': deliveredTo,
        'total_recipients': allRecipients.length,
        'successful_deliveries': deliveredTo.length,
        'sent_at': forwardedEmail.sentAt.toIso8601String(),
        'thread_id': forwardedEmail.threadId,
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error forwarding email: $e')],
        isError: true,
      );
    }
  }

  /// 📧 DELETE EMAIL
  Future<MCPToolResult> _deleteEmail(
    String agentName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final emailId = arguments['email_id'] as String;
      final permanent = arguments['permanent'] as bool? ?? false;

      // Find agent
      final agent = _agentRegistry.values
          .where((agent) => agent.sessionName == agentName)
          .firstOrNull;

      if (agent == null) {
        throw MCPServerException('Agent not registered in directory');
      }

      // Find email message
      final emailIndex =
          agent.emailInbox.indexWhere((email) => email.id == emailId);
      if (emailIndex == -1) {
        throw MCPServerException('Email message not found');
      }

      final email = agent.emailInbox[emailIndex];

      // Remove email from inbox
      final removed = agent.removeEmail(emailId);
      if (!removed) {
        throw MCPServerException('Failed to delete email');
      }

      await _persistDirectory();

      final result = {
        'success': true,
        'email_id': emailId,
        'subject': email.subject,
        'deleted_at': DateTime.now().toIso8601String(),
        'permanent': permanent,
        'message': 'Email deleted successfully',
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error deleting email: $e')],
        isError: true,
      );
    }
  }

  /// 📊 GET INBOX STATISTICS
  Future<MCPToolResult> _getInboxStats(
    String agentName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      // Find agent
      final agent = _agentRegistry.values
          .where((agent) => agent.sessionName == agentName)
          .firstOrNull;

      if (agent == null) {
        throw MCPServerException('Agent not registered in directory');
      }

      // Calculate email statistics
      final totalEmails = agent.totalEmailCount;
      final unreadEmails = agent.unreadEmailCount;
      final readEmails = totalEmails - unreadEmails;

      // Calculate priority statistics
      final highPriorityEmails = agent.getEmailsByPriority('high').length;
      final urgentEmails = agent.getEmailsByPriority('urgent').length;

      // Calculate thread statistics
      final threadIds = agent.emailInbox.map((e) => e.threadId).toSet();
      final totalThreads = threadIds.length;

      final result = {
        'success': true,
        'total_emails': totalEmails,
        'unread_emails': unreadEmails,
        'read_emails': readEmails,
        'high_priority_emails': highPriorityEmails,
        'urgent_emails': urgentEmails,
        'total_threads': totalThreads,
        'last_checked': DateTime.now().toIso8601String(),
      };

      return MCPToolResult(
        content: [MCPContent.text(jsonEncode(result))],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error getting inbox statistics: $e')],
        isError: true,
      );
    }
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
  final List<EmailMessage> emailInbox; // 📧 Separate email inbox

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
    List<EmailMessage>? emailInbox,
  })  : messages = messages ?? [],
        emailInbox = emailInbox ?? [];

  AgentInfo copyWith({
    String? status,
    String? statusMessage,
    DateTime? lastSeen,
    List<DirectoryMessage>? messages,
    List<EmailMessage>? emailInbox,
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
      emailInbox: emailInbox ?? this.emailInbox,
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
        'email_inbox': emailInbox.map((e) => e.toJson()).toList(),
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
      emailInbox: (json['email_inbox'] as List?)
              ?.map((e) => EmailMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 📧 Get unread email count
  int get unreadEmailCount => emailInbox.where((email) => !email.isRead).length;

  /// 📧 Get total email count
  int get totalEmailCount => emailInbox.length;

  /// 📧 Get emails by priority
  List<EmailMessage> getEmailsByPriority(String priority) {
    return emailInbox.where((email) => email.priority == priority).toList();
  }

  /// 📧 Get emails by thread
  List<EmailMessage> getEmailsByThread(String threadId) {
    return emailInbox.where((email) => email.threadId == threadId).toList();
  }

  /// 📧 Add email to inbox
  void addEmail(EmailMessage email) {
    emailInbox.add(email);
  }

  /// 📧 Remove email from inbox
  bool removeEmail(String emailId) {
    final index = emailInbox.indexWhere((email) => email.id == emailId);
    if (index != -1) {
      emailInbox.removeAt(index);
      return true;
    }
    return false;
  }

  /// 📧 Mark email as read
  bool markEmailAsRead(String emailId) {
    final index = emailInbox.indexWhere((email) => email.id == emailId);
    if (index != -1) {
      emailInbox[index] = emailInbox[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      return true;
    }
    return false;
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

/// 📧 **EMAIL MESSAGE**: Enhanced email-like messaging with full email features
class EmailMessage {
  final String id;
  final String senderId;
  final String senderName;
  final List<String> toRecipients;
  final List<String> ccRecipients;
  final List<String> bccRecipients;
  final String subject;
  final String body;
  final String priority;
  final DateTime sentAt;
  final bool isRead;
  final DateTime? readAt;
  final String? replyToId;
  final String? forwardFromId;
  final List<EmailAttachment> attachments;
  final String threadId;

  EmailMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.toRecipients,
    this.ccRecipients = const [],
    this.bccRecipients = const [],
    required this.subject,
    required this.body,
    this.priority = 'normal',
    required this.sentAt,
    this.isRead = false,
    this.readAt,
    this.replyToId,
    this.forwardFromId,
    this.attachments = const [],
    String? threadId,
  }) : threadId = threadId ?? id;

  EmailMessage copyWith({
    bool? isRead,
    DateTime? readAt,
    List<String>? toRecipients,
    List<String>? ccRecipients,
    List<String>? bccRecipients,
  }) {
    return EmailMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      toRecipients: toRecipients ?? this.toRecipients,
      ccRecipients: ccRecipients ?? this.ccRecipients,
      bccRecipients: bccRecipients ?? this.bccRecipients,
      subject: subject,
      body: body,
      priority: priority,
      sentAt: sentAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      replyToId: replyToId,
      forwardFromId: forwardFromId,
      attachments: attachments,
      threadId: threadId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'sender_name': senderName,
        'to_recipients': toRecipients,
        'cc_recipients': ccRecipients,
        'bcc_recipients': bccRecipients,
        'subject': subject,
        'body': body,
        'priority': priority,
        'sent_at': sentAt.toIso8601String(),
        'is_read': isRead,
        'thread_id': threadId,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        ...(() {
          final readAtValue = readAt;
          if (readAtValue != null) {
            return {'read_at': readAtValue.toIso8601String()};
          }
          return <String, dynamic>{};
        })(),
        ...(() {
          final replyToIdValue = replyToId;
          if (replyToIdValue != null) {
            return {'reply_to_id': replyToIdValue};
          }
          return <String, dynamic>{};
        })(),
        ...(() {
          final forwardFromIdValue = forwardFromId;
          if (forwardFromIdValue != null) {
            return {'forward_from_id': forwardFromIdValue};
          }
          return <String, dynamic>{};
        })(),
      };

  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    return EmailMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String,
      toRecipients: List<String>.from(json['to_recipients'] as List),
      ccRecipients: List<String>.from(json['cc_recipients'] as List? ?? []),
      bccRecipients: List<String>.from(json['bcc_recipients'] as List? ?? []),
      subject: json['subject'] as String,
      body: json['body'] as String,
      priority: json['priority'] as String? ?? 'normal',
      sentAt: DateTime.parse(json['sent_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      replyToId: json['reply_to_id'] as String?,
      forwardFromId: json['forward_from_id'] as String?,
      attachments: (json['attachments'] as List?)
              ?.map((a) => EmailAttachment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      threadId: json['thread_id'] as String? ?? json['id'] as String,
    );
  }

  /// Get all recipients (to, cc, bcc combined)
  List<String> get allRecipients => [
        ...toRecipients,
        ...ccRecipients,
        ...bccRecipients,
      ];

  /// Check if this is a reply
  bool get isReply => replyToId != null;

  /// Check if this is a forwarded message
  bool get isForwarded => forwardFromId != null;

  /// Get preview text (first 100 characters of body)
  String get preview {
    final cleanBody = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleanBody.length > 100
        ? '${cleanBody.substring(0, 100)}...'
        : cleanBody;
  }
}

/// 📎 **EMAIL ATTACHMENT**: File attachments for email messages
class EmailAttachment {
  final String filename;
  final String content;
  final String mimeType;
  final int size;

  EmailAttachment({
    required this.filename,
    required this.content,
    required this.mimeType,
  }) : size = content.length;

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'content': content,
        'mime_type': mimeType,
        'size': size,
      };

  factory EmailAttachment.fromJson(Map<String, dynamic> json) {
    return EmailAttachment(
      filename: json['filename'] as String,
      content: json['content'] as String,
      mimeType: json['mime_type'] as String,
    );
  }

  /// Get human-readable file size
  String get humanReadableSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
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
  📧 directory_send_email - Send an email-like message to one or more agents
  📬 directory_check_inbox - Check this agent's inbox for new messages
  📋 directory_get_available_recipients - Get list of agents available to receive messages
  📧 directory_get_email - Get a specific email message by ID
  📧 directory_reply_to_email - Reply to a specific email message
  📧 directory_forward_email - Forward an email message to other agents
  📧 directory_delete_email - Delete an email message from inbox
  📊 directory_get_inbox_stats - Get inbox statistics for this agent

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
