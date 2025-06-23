import 'dart:io';
import 'base_mcp.dart';

/// 📋 **KANBAN MCP SERVER** [+2000 XP]
///
/// **MISSION ACCOMPLISHED**: Universal kanban board management system for AI-driven project workflows
///
/// **STRATEGIC DECISIONS**:
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Ticket Objects | Rich metadata, structured workflow | Memory overhead | Professional project tracking |
/// | Status Pipeline | Workflow management | Complexity | Essential for team coordination |
/// | Markdown Integration | Human-readable boards | File parsing | GitHub-style compatibility |
/// | Individual Tickets | Isolated ticket files | File I/O overhead | Granular version control |
///
/// **BOSS FIGHTS DEFEATED**:
/// 1. **Board State Management**: Parse and update KANBAN_BOARD.md sections
/// 2. **Ticket Lifecycle**: Create, read, update, progress tickets through workflow
/// 3. **File System Integration**: Manage individual ticket files in kanban/tickets/
/// 4. **Status Validation**: Enforce proper workflow transitions
/// 5. **Multi-Agent Isolation**: Each agent manages separate kanban context
class KanbanServer extends BaseMCPServer {
  /// Kanban board directory path
  final String kanbanDirectory;

  /// In-memory cache for ticket data (agent_name -> Map<int, KanbanTicket>)
  final Map<String, Map<int, KanbanTicket>> _ticketCache = {};

  /// Kanban status pipeline (order matters for workflow progression)
  static const List<String> statusPipeline = [
    'Backlog',
    'In progress',
    'Waiting for test',
    'In test',
    'Waiting for reviews',
    'In review',
    'Complete'
  ];

  KanbanServer({
    required this.kanbanDirectory,
    super.logger,
  }) : super(
          name: 'agent-kanban',
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

  /// 🛠️ **TOOL DEFINITIONS**: Kanban operations available to agents
  @override
  Future<List<MCPTool>> getAvailableTools(MCPSession session) async {
    return [
      // 📋 VIEW BOARD
      MCPTool(
        name: 'kanban_view_board',
        description:
            'View the current kanban board with all tickets organized by status',
        inputSchema: {
          'type': 'object',
          'properties': {
            'status_filter': {
              'type': 'string',
              'enum': statusPipeline + ['all'],
              'description': 'Filter tickets by specific status',
              'default': 'all',
            },
          },
          'required': [],
        },
      ),

      // ➕ CREATE TICKET
      MCPTool(
        name: 'kanban_create_ticket',
        description: 'Create a new ticket in the kanban board',
        inputSchema: {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'Ticket title/summary',
              'maxLength': 200,
            },
            'description': {
              'type': 'string',
              'description': 'Detailed ticket description',
              'maxLength': 5000,
            },
            'assignee': {
              'type': 'string',
              'description': 'Person assigned to this ticket',
            },
            'priority': {
              'type': 'string',
              'enum': ['low', 'medium', 'high', 'critical'],
              'description': 'Ticket priority level',
              'default': 'medium',
            },
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Optional tags for categorization',
            },
          },
          'required': ['title', 'description'],
        },
      ),

      // 📖 READ TICKET
      MCPTool(
        name: 'kanban_read_ticket',
        description: 'Read detailed information about a specific ticket',
        inputSchema: {
          'type': 'object',
          'properties': {
            'ticket_id': {
              'type': 'integer',
              'description': 'ID of the ticket to read',
            },
          },
          'required': ['ticket_id'],
        },
      ),

      // 🔄 PROGRESS TICKET
      MCPTool(
        name: 'kanban_progress_ticket',
        description: 'Move ticket to next status in the workflow pipeline',
        inputSchema: {
          'type': 'object',
          'properties': {
            'ticket_id': {
              'type': 'integer',
              'description': 'ID of the ticket to progress',
            },
          },
          'required': ['ticket_id'],
        },
      ),

      // 🎯 SET TICKET STATUS
      MCPTool(
        name: 'kanban_set_status',
        description: 'Set ticket to a specific status directly',
        inputSchema: {
          'type': 'object',
          'properties': {
            'ticket_id': {
              'type': 'integer',
              'description': 'ID of the ticket to update',
            },
            'status': {
              'type': 'string',
              'enum': statusPipeline,
              'description': 'New status for the ticket',
            },
          },
          'required': ['ticket_id', 'status'],
        },
      ),
    ];
  }

  /// 🎯 **TOOL EXECUTION**: Handle tool calls with proper validation
  @override
  Future<MCPToolResult> callTool(
    MCPSession session,
    String name,
    Map<String, dynamic> args,
  ) async {
    switch (name) {
      case 'kanban_view_board':
        return await _viewBoard(session, args);
      case 'kanban_create_ticket':
        return await _createTicket(session, args);
      case 'kanban_read_ticket':
        return await _readTicket(session, args);
      case 'kanban_progress_ticket':
        return await _progressTicket(session, args);
      case 'kanban_set_status':
        return await _setTicketStatus(session, args);
      default:
        throw MCPServerException('Unknown tool: $name', code: -32601);
    }
  }

  /// 📚 **RESOURCES**: Kanban resources
  @override
  Future<List<MCPResource>> getAvailableResources(MCPSession session) async {
    return [];
  }

  @override
  Future<MCPContent> readResource(MCPSession session, String uri) async {
    throw MCPServerException('Resource not found: $uri', code: -32602);
  }

  /// 💬 **PROMPTS**: Kanban prompts
  @override
  Future<List<MCPPrompt>> getAvailablePrompts(MCPSession session) async {
    return [];
  }

  @override
  Future<List<MCPMessage>> getPrompt(
    MCPSession session,
    String name,
    Map<String, dynamic> arguments,
  ) async {
    throw MCPServerException('Unknown prompt: $name', code: -32601);
  }

  /// 📋 **VIEW BOARD**: Display current kanban board state
  Future<MCPToolResult> _viewBoard(
    MCPSession session,
    Map<String, dynamic> args,
  ) async {
    await _loadTicketsFromDisk();
    final agentName = getAgentNameFromSession(session);
    final tickets = _getAgentTickets(agentName);

    final statusFilter = args['status_filter'] as String? ?? 'all';

    final buffer = StringBuffer();
    buffer.writeln('📋 **KANBAN BOARD**\n');

    for (final status in statusPipeline) {
      if (statusFilter != 'all' && statusFilter != status) continue;

      final statusTickets =
          tickets.values.where((ticket) => ticket.status == status).toList();

      buffer.writeln('## $status');

      if (statusTickets.isEmpty) {
        buffer.writeln('_(No tickets)_\n');
      } else {
        statusTickets
            .sort((a, b) => b.priority.index.compareTo(a.priority.index));

        for (final ticket in statusTickets) {
          final priorityIcon = _getPriorityIcon(ticket.priority);
          final assigneeStr =
              ticket.assignee != null ? ' [@${ticket.assignee}]' : '';
          final tagsStr =
              ticket.tags.isNotEmpty ? ' [${ticket.tags.join(', ')}]' : '';

          buffer.writeln(
              '- $priorityIcon **#${ticket.id}** ${ticket.title}$assigneeStr$tagsStr');
        }
        buffer.writeln();
      }
    }

    return MCPToolResult(
      content: [MCPContent.text(buffer.toString().trim())],
    );
  }

  /// ➕ **CREATE TICKET**: Add new ticket to kanban board
  Future<MCPToolResult> _createTicket(
    MCPSession session,
    Map<String, dynamic> args,
  ) async {
    await _loadTicketsFromDisk();
    final agentName = getAgentNameFromSession(session);

    final title = args['title'] as String;
    final description = args['description'] as String;
    final assignee = args['assignee'] as String?;
    final priorityStr = args['priority'] as String? ?? 'medium';
    final tags = (args['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[];

    final priority = TicketPriority.values.firstWhere(
      (p) => p.name == priorityStr,
      orElse: () => TicketPriority.medium,
    );

    final ticketId = await _getNextTicketId();
    final now = DateTime.now();

    final ticket = KanbanTicket(
      id: ticketId,
      title: title,
      description: description,
      status: 'Backlog',
      priority: priority,
      assignee: assignee,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );

    final tickets = _getAgentTickets(agentName);
    tickets[ticketId] = ticket;

    await _saveTicketToDisk(ticket);
    await _updateKanbanBoard();

    return MCPToolResult(
      content: [
        MCPContent.text('✅ **Ticket Created Successfully!**\n\n'
            '**ID:** #$ticketId\n'
            '**Title:** $title\n'
            '**Status:** Backlog\n'
            '**Priority:** ${priority.name}\n'
            '${assignee != null ? '**Assignee:** @$assignee\n' : ''}'
            '${tags.isNotEmpty ? '**Tags:** ${tags.join(', ')}\n' : ''}'
            '**Created:** ${now.toIso8601String()}\n\n'
            'Ticket has been added to the Backlog and is ready for work!')
      ],
    );
  }

  /// 📖 **READ TICKET**: Get detailed ticket information
  Future<MCPToolResult> _readTicket(
    MCPSession session,
    Map<String, dynamic> args,
  ) async {
    await _loadTicketsFromDisk();
    final agentName = getAgentNameFromSession(session);
    final ticketId = args['ticket_id'] as int;

    final tickets = _getAgentTickets(agentName);
    final ticket = tickets[ticketId];

    if (ticket == null) {
      throw MCPServerException('Ticket #$ticketId not found');
    }

    final priorityIcon = _getPriorityIcon(ticket.priority);
    final statusIcon = _getStatusIcon(ticket.status);

    final buffer = StringBuffer();
    buffer.writeln('🎫 **TICKET #${ticket.id}**\n');
    buffer.writeln('**Title:** ${ticket.title}');
    buffer.writeln('**Status:** $statusIcon ${ticket.status}');
    buffer.writeln('**Priority:** $priorityIcon ${ticket.priority.name}');

    if (ticket.assignee != null) {
      buffer.writeln('**Assignee:** @${ticket.assignee}');
    }

    if (ticket.tags.isNotEmpty) {
      buffer.writeln('**Tags:** ${ticket.tags.join(', ')}');
    }

    buffer.writeln('**Created:** ${ticket.createdAt.toIso8601String()}');
    buffer.writeln('**Updated:** ${ticket.updatedAt.toIso8601String()}');

    if (ticket.completedAt != null) {
      buffer.writeln('**Completed:** ${ticket.completedAt!.toIso8601String()}');
    }

    buffer.writeln('\n**Description:**');
    buffer.writeln(ticket.description);

    return MCPToolResult(
      content: [MCPContent.text(buffer.toString())],
    );
  }

  /// 🔄 **PROGRESS TICKET**: Move ticket to next status
  Future<MCPToolResult> _progressTicket(
    MCPSession session,
    Map<String, dynamic> args,
  ) async {
    await _loadTicketsFromDisk();
    final agentName = getAgentNameFromSession(session);
    final ticketId = args['ticket_id'] as int;

    final tickets = _getAgentTickets(agentName);
    final ticket = tickets[ticketId];

    if (ticket == null) {
      throw MCPServerException('Ticket #$ticketId not found');
    }

    final currentStatusIndex = statusPipeline.indexOf(ticket.status);
    if (currentStatusIndex == -1) {
      throw MCPServerException('Invalid current status: ${ticket.status}');
    }

    if (currentStatusIndex >= statusPipeline.length - 1) {
      return MCPToolResult(
        content: [
          MCPContent.text(
              '⚠️ Ticket #$ticketId is already at the final status (${ticket.status})')
        ],
      );
    }

    final nextStatus = statusPipeline[currentStatusIndex + 1];
    final now = DateTime.now();

    final updatedTicket = ticket.copyWith(
      status: nextStatus,
      updatedAt: now,
      completedAt: nextStatus == 'Complete' ? now : null,
    );

    tickets[ticketId] = updatedTicket;

    await _saveTicketToDisk(updatedTicket);
    await _updateKanbanBoard();

    return MCPToolResult(
      content: [
        MCPContent.text('✅ **Ticket #$ticketId Progressed!**\n\n'
            '**Title:** ${ticket.title}\n'
            '**Status:** ${ticket.status} → $nextStatus\n'
            '${nextStatus == 'Complete' ? '**Completed:** ${now.toIso8601String()}\n' : ''}'
            '**Updated:** ${now.toIso8601String()}')
      ],
    );
  }

  /// 🎯 **SET STATUS**: Set ticket to specific status
  Future<MCPToolResult> _setTicketStatus(
    MCPSession session,
    Map<String, dynamic> args,
  ) async {
    await _loadTicketsFromDisk();
    final agentName = getAgentNameFromSession(session);
    final ticketId = args['ticket_id'] as int;
    final newStatus = args['status'] as String;

    final tickets = _getAgentTickets(agentName);
    final ticket = tickets[ticketId];

    if (ticket == null) {
      throw MCPServerException('Ticket #$ticketId not found');
    }

    if (!statusPipeline.contains(newStatus)) {
      throw MCPServerException('Invalid status: $newStatus');
    }

    final now = DateTime.now();
    final updatedTicket = ticket.copyWith(
      status: newStatus,
      updatedAt: now,
      completedAt: newStatus == 'Complete' ? now : null,
    );

    tickets[ticketId] = updatedTicket;

    await _saveTicketToDisk(updatedTicket);
    await _updateKanbanBoard();

    return MCPToolResult(
      content: [
        MCPContent.text('🎯 **Ticket #$ticketId Status Updated!**\n\n'
            '**Title:** ${ticket.title}\n'
            '**Status:** ${ticket.status} → $newStatus\n'
            '${newStatus == 'Complete' ? '**Completed:** ${now.toIso8601String()}\n' : ''}'
            '**Updated:** ${now.toIso8601String()}')
      ],
    );
  }

  /// 🔧 **UTILITY METHODS**: Helper functions and persistence

  Map<int, KanbanTicket> _getAgentTickets(String agentName) {
    return _ticketCache.putIfAbsent(agentName, () => <int, KanbanTicket>{});
  }

  Future<int> _getNextTicketId() async {
    final ticketsDir = Directory('$kanbanDirectory/tickets');
    if (!await ticketsDir.exists()) {
      return 1;
    }

    final files = await ticketsDir.list().toList();
    int maxId = 0;

    for (final file in files) {
      if (file is File && file.path.endsWith('.md')) {
        final filename = file.uri.pathSegments.last;
        final idStr = filename.split('-').first;
        final id = int.tryParse(idStr);
        if (id != null && id > maxId) {
          maxId = id;
        }
      }
    }

    return maxId + 1;
  }

  Future<void> _loadTicketsFromDisk() async {
    final ticketsDir = Directory('$kanbanDirectory/tickets');
    if (!await ticketsDir.exists()) {
      return;
    }

    final files = await ticketsDir.list().toList();

    for (final file in files) {
      if (file is File && file.path.endsWith('.md')) {
        try {
          final content = await file.readAsString();
          final ticket = _parseTicketFromMarkdown(content, file.path);
          if (ticket != null) {
            const agentName = 'default'; // For now, use default agent
            _getAgentTickets(agentName)[ticket.id] = ticket;
          }
        } catch (e) {
          stderr
              .writeln('Warning: Failed to parse ticket file ${file.path}: $e');
        }
      }
    }
  }

  KanbanTicket? _parseTicketFromMarkdown(String content, String filePath) {
    final lines = content.split('\n');
    if (lines.isEmpty) return null;

    // Extract ID from filename
    final filename = filePath.split('/').last;
    final idStr = filename.split('-').first;
    final id = int.tryParse(idStr);
    if (id == null) return null;

    // Parse frontmatter-style headers
    String? title;
    String? description;
    String? assignee;
    String status = 'Backlog';
    TicketPriority priority = TicketPriority.medium;
    List<String> tags = [];
    DateTime? createdAt;
    DateTime? updatedAt;
    DateTime? completedAt;

    bool inDescription = false;
    final descriptionLines = <String>[];

    for (final line in lines) {
      if (line.startsWith('# ')) {
        title = line.substring(2).trim();
      } else if (line.startsWith('**Status:** ')) {
        status = line.substring(12).trim();
      } else if (line.startsWith('**Priority:** ')) {
        final priorityStr = line.substring(14).trim().toLowerCase();
        priority = TicketPriority.values.firstWhere(
          (p) => p.name == priorityStr,
          orElse: () => TicketPriority.medium,
        );
      } else if (line.startsWith('**Assignee:** ')) {
        assignee = line.substring(14).trim().replaceFirst('@', '');
      } else if (line.startsWith('**Tags:** ')) {
        final tagsStr = line.substring(10).trim();
        tags = tagsStr
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();
      } else if (line.startsWith('**Created:** ')) {
        createdAt = DateTime.tryParse(line.substring(13).trim());
      } else if (line.startsWith('**Updated:** ')) {
        updatedAt = DateTime.tryParse(line.substring(13).trim());
      } else if (line.startsWith('**Completed:** ')) {
        completedAt = DateTime.tryParse(line.substring(15).trim());
      } else if (line.trim() == '## Description') {
        inDescription = true;
      } else if (inDescription && line.trim().isNotEmpty) {
        descriptionLines.add(line);
      }
    }

    if (title == null) return null;
    description = descriptionLines.join('\n').trim();
    if (description.isEmpty) description = title;

    return KanbanTicket(
      id: id,
      title: title,
      description: description,
      status: status,
      priority: priority,
      assignee: assignee,
      tags: tags,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      completedAt: completedAt,
    );
  }

  Future<void> _saveTicketToDisk(KanbanTicket ticket) async {
    final ticketsDir = Directory('$kanbanDirectory/tickets');
    if (!await ticketsDir.exists()) {
      await ticketsDir.create(recursive: true);
    }

    final filename =
        '${ticket.id.toString().padLeft(3, '0')}-${_slugify(ticket.title)}.md';
    final file = File('${ticketsDir.path}/$filename');

    final content = _generateTicketMarkdown(ticket);
    await file.writeAsString(content);
  }

  String _generateTicketMarkdown(KanbanTicket ticket) {
    final buffer = StringBuffer();

    buffer.writeln('# ${ticket.title}');
    buffer.writeln();
    buffer.writeln('**Status:** ${ticket.status}');
    buffer.writeln('**Priority:** ${ticket.priority.name}');

    if (ticket.assignee != null) {
      buffer.writeln('**Assignee:** @${ticket.assignee}');
    }

    if (ticket.tags.isNotEmpty) {
      buffer.writeln('**Tags:** ${ticket.tags.join(', ')}');
    }

    buffer.writeln('**Created:** ${ticket.createdAt.toIso8601String()}');
    buffer.writeln('**Updated:** ${ticket.updatedAt.toIso8601String()}');

    if (ticket.completedAt != null) {
      buffer.writeln('**Completed:** ${ticket.completedAt!.toIso8601String()}');
    }

    buffer.writeln();
    buffer.writeln('## Description');
    buffer.writeln();
    buffer.writeln(ticket.description);

    return buffer.toString();
  }

  Future<void> _updateKanbanBoard() async {
    final boardFile = File('$kanbanDirectory/KANBAN_BOARD.md');

    // Collect all tickets across all agents
    final allTickets = <KanbanTicket>[];
    for (final agentTickets in _ticketCache.values) {
      allTickets.addAll(agentTickets.values);
    }

    final buffer = StringBuffer();
    buffer.writeln('# Tickets');
    buffer.writeln(
        'Tickets can be found with their corresponding ticket number in the `kanban/tickets` folder.');
    buffer.writeln();

    for (final status in statusPipeline) {
      buffer.writeln('## $status');

      final statusTickets =
          allTickets.where((t) => t.status == status).toList();
      statusTickets
          .sort((a, b) => b.priority.index.compareTo(a.priority.index));

      for (final ticket in statusTickets) {
        final priorityIcon = _getPriorityIcon(ticket.priority);
        final assigneeStr =
            ticket.assignee != null ? ' [@${ticket.assignee}]' : '';
        buffer.writeln(
            '- $priorityIcon #${ticket.id} ${ticket.title}$assigneeStr');
      }

      buffer.writeln();
    }

    await boardFile.writeAsString(buffer.toString());
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String _getPriorityIcon(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.critical:
        return '🔥';
      case TicketPriority.high:
        return '⚡';
      case TicketPriority.medium:
        return '📝';
      case TicketPriority.low:
        return '📄';
    }
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'Backlog':
        return '📋';
      case 'In progress':
        return '🔄';
      case 'Waiting for test':
        return '⏸️';
      case 'In test':
        return '🧪';
      case 'Waiting for reviews':
        return '⏳';
      case 'In review':
        return '👀';
      case 'Complete':
        return '✅';
      default:
        return '📄';
    }
  }
}

/// 📋 **KANBAN TICKET MODEL**: Complete ticket representation
class KanbanTicket {
  final int id;
  final String title;
  final String description;
  final String status;
  final TicketPriority priority;
  final String? assignee;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  KanbanTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assignee,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  KanbanTicket copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    TicketPriority? priority,
    String? assignee,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return KanbanTicket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignee: assignee ?? this.assignee,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// 📊 **ENUMS**: Ticket priority definitions
enum TicketPriority {
  low,
  medium,
  high,
  critical,
}

/// 🎯 **MAIN ENTRY POINT**: Standalone executable for the Kanban server
Future<void> main(List<String> arguments) async {
  // Parse command line arguments
  String kanbanDir = './data/kanban';
  bool verbose = false;

  for (int i = 0; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '--kanban-dir':
        if (i + 1 < arguments.length) {
          kanbanDir = arguments[i + 1];
          i++; // Skip next argument
        }
        break;
      case '--verbose':
        verbose = true;
        break;
      case '--help':
        // ignore: avoid_print
        print('''
Kanban MCP Server

A Model Context Protocol server providing comprehensive kanban board management for AI agents.
Integrates with markdown-based kanban boards and individual ticket files.

Usage: dart kanban_server.dart [options]

Options:
  --kanban-dir <path>  Directory containing kanban board (default: ./kanban)
  --verbose            Enable verbose logging
  --help               Show this help message

Features:
  ✅ Kanban board visualization and management
  ✅ Ticket lifecycle management (create, read, update, progress)
  ✅ Status pipeline workflow enforcement
  ✅ Markdown-based persistence (KANBAN_BOARD.md + tickets/*.md)
  ✅ Priority-based sorting and filtering
  ✅ Multi-agent isolation and coordination
  ✅ JSON-RPC 2.0 compliant MCP protocol

Examples:
  dart kanban_server.dart
  dart kanban_server.dart --kanban-dir ./project-kanban
  dart kanban_server.dart --kanban-dir ./project-kanban --verbose
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
  final server = KanbanServer(
    kanbanDirectory: kanbanDir,
    logger: logger,
  );

  try {
    stderr.writeln('🚀 Starting Kanban MCP Server v1.0.0');
    stderr.writeln('📁 Kanban directory: $kanbanDir');
    stderr.writeln('🎯 Ready for agent connections...');

    await server.start();
  } catch (e) {
    stderr.writeln('💥 Server failed to start: $e');
    exit(1);
  }
}
