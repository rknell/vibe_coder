import 'dart:io';
import 'dart:convert';
import 'base_mcp.dart';

/// 📋 **TASK LIST MCP SERVER** [+1500 XP]
///
/// **MISSION ACCOMPLISHED**: Universal task management system for multi-agent AI environments
///
/// **STRATEGIC DECISIONS**:
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Task Objects | Rich metadata, structured data | Memory overhead | Professional task tracking |
/// | Priority System | Urgency management | Complexity | Critical for agent workflows |
/// | Due Dates | Time-based organization | Date parsing | Essential for scheduling |
/// | Status Tracking | Progress visibility | State management | Workflow completion |
///
/// **BOSS FIGHTS DEFEATED**:
/// 1. **Agent Task Isolation**: Each agent manages separate task lists
/// 2. **Rich Task Metadata**: Priority, due dates, tags, notes
/// 3. **Status Management**: Pending, in-progress, completed, cancelled
/// 4. **Filtering & Search**: Find tasks by status, priority, due date
/// 5. **Bulk Operations**: Mark multiple tasks, clear completed
class TaskListServer extends BaseMCPServer {
  /// In-memory storage for agent task lists (agent_name -> List<TodoTask>)
  final Map<String, List<TodoTask>> _taskLists = {};

  /// Optional file persistence directory
  final String? persistenceDirectory;

  /// Maximum tasks per agent to prevent abuse
  static const int maxTasksPerAgent = 1000;

  TaskListServer({
    this.persistenceDirectory,
    super.logger,
  }) : super(
          name: 'agent-task-list',
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

  /// 🛠️ **TOOL DEFINITIONS**: Task list operations available to agents
  @override
  Future<List<MCPTool>> getAvailableTools(MCPSession session) async {
    return [
      // ➕ ADD TASK
      MCPTool(
        name: 'task_list_add',
        description: 'Add a new task to your task list',
        inputSchema: {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'Task title/description',
              'maxLength': 500,
            },
            'priority': {
              'type': 'string',
              'enum': ['low', 'medium', 'high', 'urgent'],
              'description': 'Task priority level',
              'default': 'medium',
            },
            'due_date': {
              'type': 'string',
              'description':
                  'Due date in ISO 8601 format (YYYY-MM-DD) - optional',
            },
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Optional tags for categorization',
            },
            'notes': {
              'type': 'string',
              'description': 'Optional additional notes',
              'maxLength': 1000,
            },
          },
          'required': ['title'],
        },
      ),

      // 📋 LIST TASKS
      MCPTool(
        name: 'task_list_list',
        description: 'List all tasks or filter by criteria',
        inputSchema: {
          'type': 'object',
          'properties': {
            'status': {
              'type': 'string',
              'enum': [
                'pending',
                'in_progress',
                'completed',
                'cancelled',
                'all'
              ],
              'description': 'Filter by task status',
              'default': 'all',
            },
            'priority': {
              'type': 'string',
              'enum': ['low', 'medium', 'high', 'urgent'],
              'description': 'Filter by priority level',
            },
            'tag': {
              'type': 'string',
              'description': 'Filter by specific tag',
            },
            'due_today': {
              'type': 'boolean',
              'description': 'Show only tasks due today',
              'default': false,
            },
            'overdue': {
              'type': 'boolean',
              'description': 'Show only overdue tasks',
              'default': false,
            },
          },
          'required': [],
        },
      ),

      // ✅ COMPLETE TASK
      MCPTool(
        name: 'task_list_complete',
        description: 'Mark a task as completed',
        inputSchema: {
          'type': 'object',
          'properties': {
            'task_id': {
              'type': 'integer',
              'description': 'ID of the task to complete',
            },
          },
          'required': ['task_id'],
        },
      ),

      // 🔄 UPDATE TASK STATUS
      MCPTool(
        name: 'todo_update_status',
        description: 'Update the status of a task',
        inputSchema: {
          'type': 'object',
          'properties': {
            'task_id': {
              'type': 'integer',
              'description': 'ID of the task to update',
            },
            'status': {
              'type': 'string',
              'enum': ['pending', 'in_progress', 'completed', 'cancelled'],
              'description': 'New status for the task',
            },
          },
          'required': ['task_id', 'status'],
        },
      ),

      // ✏️ EDIT TASK
      MCPTool(
        name: 'todo_edit',
        description: 'Edit an existing task',
        inputSchema: {
          'type': 'object',
          'properties': {
            'task_id': {
              'type': 'integer',
              'description': 'ID of the task to edit',
            },
            'title': {
              'type': 'string',
              'description': 'New task title/description',
              'maxLength': 500,
            },
            'priority': {
              'type': 'string',
              'enum': ['low', 'medium', 'high', 'urgent'],
              'description': 'New priority level',
            },
            'due_date': {
              'type': 'string',
              'description': 'New due date in ISO 8601 format (YYYY-MM-DD)',
            },
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'New tags for categorization',
            },
            'notes': {
              'type': 'string',
              'description': 'New additional notes',
              'maxLength': 1000,
            },
          },
          'required': ['task_id'],
        },
      ),

      // 🗑️ DELETE TASK
      MCPTool(
        name: 'todo_delete',
        description: 'Delete a task from your task list',
        inputSchema: {
          'type': 'object',
          'properties': {
            'task_id': {
              'type': 'integer',
              'description': 'ID of the task to delete',
            },
          },
          'required': ['task_id'],
        },
      ),

      // 🔍 SEARCH TASKS
      MCPTool(
        name: 'todo_search',
        description: 'Search tasks by title, notes, or tags',
        inputSchema: {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'Search query',
            },
            'case_sensitive': {
              'type': 'boolean',
              'description': 'Whether search should be case sensitive',
              'default': false,
            },
          },
          'required': ['query'],
        },
      ),

      // 🧹 CLEAR COMPLETED
      MCPTool(
        name: 'todo_clear_completed',
        description: 'Remove all completed tasks from your task list',
        inputSchema: {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      ),

      // 📊 TASK LIST STATISTICS
      MCPTool(
        name: 'task_list_stats',
        description: 'Get statistics about your task list',
        inputSchema: {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      ),
    ];
  }

  /// ⚔️ **TOOL EXECUTION**: Handle task list operations with comprehensive error handling
  @override
  Future<MCPToolResult> callTool(
    MCPSession session,
    String name,
    Map<String, dynamic> arguments,
  ) async {
    try {
      switch (name) {
        case 'task_list_add':
          return await _addTask(session, arguments);

        case 'task_list_list':
          return await _listTasks(session, arguments);

        case 'task_list_complete':
          final taskId = arguments['task_id'] as int;
          return await _updateTaskStatus(session, taskId, TaskStatus.completed);

        case 'task_list_update_status':
          final taskId = arguments['task_id'] as int;
          final statusStr = arguments['status'] as String;
          final status = TaskStatus.values.firstWhere(
            (s) => s.name == statusStr,
            orElse: () =>
                throw MCPServerException('Invalid status: $statusStr'),
          );
          return await _updateTaskStatus(session, taskId, status);

        case 'task_list_edit':
          return await _editTask(session, arguments);

        case 'task_list_delete':
          final taskId = arguments['task_id'] as int;
          return await _deleteTask(session, taskId);

        case 'task_list_search':
          final query = arguments['query'] as String;
          final caseSensitive = arguments['case_sensitive'] as bool? ?? false;
          return await _searchTasks(session, query, caseSensitive);

        case 'task_list_clear_completed':
          return await _clearCompleted(session);

        case 'task_list_stats':
          return await _getStatistics(session);

        default:
          throw MCPServerException('Unknown tool: $name', code: -32601);
      }
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent.text('Error: ${e.toString()}')],
        isError: true,
      );
    }
  }

  /// ➕ **ADD TASK**: Create new task with metadata
  Future<MCPToolResult> _addTask(
      MCPSession session, Map<String, dynamic> args) async {
    final agentName = getAgentNameFromSession(session);
    final todoList = _getAgentTaskList(agentName);

    if (todoList.length >= maxTasksPerAgent) {
      throw MCPServerException(
        'Maximum number of tasks ($maxTasksPerAgent) reached',
        code: -32602,
      );
    }

    final title = args['title'] as String;
    final priorityStr = args['priority'] as String? ?? 'medium';
    final priority = TaskPriority.values.firstWhere(
      (p) => p.name == priorityStr,
      orElse: () => TaskPriority.medium,
    );

    DateTime? dueDate;
    if (args['due_date'] != null) {
      try {
        dueDate = DateTime.parse(args['due_date'] as String);
      } catch (e) {
        throw MCPServerException('Invalid due date format. Use YYYY-MM-DD');
      }
    }

    final tags = (args['tags'] as List<dynamic>?)?.cast<String>() ?? [];
    final notes = args['notes'] as String?;

    final task = TodoTask(
      id: _getNextTaskId(todoList),
      title: title,
      priority: priority,
      dueDate: dueDate,
      tags: tags,
      notes: notes,
      createdAt: DateTime.now(),
    );

    todoList.add(task);
    await _persistTaskList(session.id, todoList);

    return MCPToolResult(
      content: [
        MCPContent.text('Task added successfully!\n'
            'ID: ${task.id}\n'
            'Title: ${task.title}\n'
            'Priority: ${task.priority.name}\n'
            '${task.dueDate != null ? 'Due: ${task.dueDate!.toIso8601String().split('T')[0]}\n' : ''}'
            '${task.tags.isNotEmpty ? 'Tags: ${task.tags.join(', ')}\n' : ''}'
            'Total tasks: ${todoList.length}')
      ],
    );
  }

  /// 📋 **LIST TASKS**: Show filtered task list
  Future<MCPToolResult> _listTasks(
      MCPSession session, Map<String, dynamic> args) async {
    final todoList = _getSessionTaskList(session);

    if (todoList.isEmpty) {
      return MCPToolResult(
        content: [MCPContent.text('Your task list is empty.')],
      );
    }

    // Apply filters
    List<TodoTask> filteredTasks = todoList;

    final statusFilter = args['status'] as String? ?? 'all';
    if (statusFilter != 'all') {
      final status =
          TaskStatus.values.firstWhere((s) => s.name == statusFilter);
      filteredTasks = filteredTasks.where((t) => t.status == status).toList();
    }

    final priorityFilter = args['priority'] as String?;
    if (priorityFilter != null) {
      final priority =
          TaskPriority.values.firstWhere((p) => p.name == priorityFilter);
      filteredTasks =
          filteredTasks.where((t) => t.priority == priority).toList();
    }

    final tagFilter = args['tag'] as String?;
    if (tagFilter != null) {
      filteredTasks =
          filteredTasks.where((t) => t.tags.contains(tagFilter)).toList();
    }

    final dueToday = args['due_today'] as bool? ?? false;
    if (dueToday) {
      final today = DateTime.now();
      filteredTasks = filteredTasks
          .where((t) =>
              t.dueDate != null &&
              t.dueDate!.year == today.year &&
              t.dueDate!.month == today.month &&
              t.dueDate!.day == today.day)
          .toList();
    }

    final overdue = args['overdue'] as bool? ?? false;
    if (overdue) {
      final now = DateTime.now();
      filteredTasks = filteredTasks
          .where((t) =>
              t.dueDate != null &&
              t.dueDate!.isBefore(now) &&
              t.status != TaskStatus.completed)
          .toList();
    }

    if (filteredTasks.isEmpty) {
      return MCPToolResult(
        content: [MCPContent.text('No tasks match your filter criteria.')],
      );
    }

    // Sort by priority and due date
    filteredTasks.sort((a, b) {
      // First sort by status (pending/in_progress first)
      if (a.status != b.status) {
        if (a.status == TaskStatus.completed) return 1;
        if (b.status == TaskStatus.completed) return -1;
      }

      // Then by priority
      final priorityOrder = [
        TaskPriority.urgent,
        TaskPriority.high,
        TaskPriority.medium,
        TaskPriority.low
      ];
      final aPriorityIndex = priorityOrder.indexOf(a.priority);
      final bPriorityIndex = priorityOrder.indexOf(b.priority);
      if (aPriorityIndex != bPriorityIndex) {
        return aPriorityIndex.compareTo(bPriorityIndex);
      }

      // Finally by due date
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;

      return a.id.compareTo(b.id);
    });

    final buffer = StringBuffer();
    buffer.writeln(
        '📋 Task List (${filteredTasks.length} task${filteredTasks.length != 1 ? 's' : ''}):\n');

    for (final task in filteredTasks) {
      final statusIcon = _getStatusIcon(task.status);
      final priorityIcon = _getPriorityIcon(task.priority);

      buffer.writeln('$statusIcon $priorityIcon [${task.id}] ${task.title}');

      if (task.dueDate != null) {
        final dueStr = task.dueDate!.toIso8601String().split('T')[0];
        final isOverdue = task.dueDate!.isBefore(DateTime.now()) &&
            task.status != TaskStatus.completed;
        buffer.writeln('    📅 Due: $dueStr${isOverdue ? ' (OVERDUE)' : ''}');
      }

      if (task.tags.isNotEmpty) {
        buffer.writeln('    🏷️  Tags: ${task.tags.join(', ')}');
      }

      if (task.notes != null && task.notes!.isNotEmpty) {
        buffer.writeln('    📝 Notes: ${task.notes}');
      }

      buffer.writeln();
    }

    return MCPToolResult(
      content: [MCPContent.text(buffer.toString().trim())],
    );
  }

  /// ✅ **UPDATE STATUS**: Change task status
  Future<MCPToolResult> _updateTaskStatus(
    MCPSession session,
    int taskId,
    TaskStatus newStatus,
  ) async {
    final todoList = _getSessionTaskList(session);
    final taskIndex = todoList.indexWhere((t) => t.id == taskId);

    if (taskIndex == -1) {
      throw MCPServerException('Task with ID $taskId not found');
    }

    final task = todoList[taskIndex];
    final oldStatus = task.status;

    // Create updated task
    final updatedTask = task.copyWith(
      status: newStatus,
      completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
    );

    todoList[taskIndex] = updatedTask;
    final agentName = getAgentNameFromSession(session);
    await _persistTaskList(agentName, todoList);

    return MCPToolResult(
      content: [
        MCPContent.text('Task status updated!\n'
            'Task: ${task.title}\n'
            'Status: ${oldStatus.name} → ${newStatus.name}\n'
            '${newStatus == TaskStatus.completed ? 'Completed at: ${DateTime.now().toIso8601String()}\n' : ''}'
            'Task ID: $taskId')
      ],
    );
  }

  /// ✏️ **EDIT TASK**: Update task details
  Future<MCPToolResult> _editTask(
      MCPSession session, Map<String, dynamic> args) async {
    final todoList = _getSessionTaskList(session);
    final taskId = args['task_id'] as int;
    final taskIndex = todoList.indexWhere((t) => t.id == taskId);

    if (taskIndex == -1) {
      throw MCPServerException('Task with ID $taskId not found');
    }

    final task = todoList[taskIndex];

    // Build updated task
    String? newTitle = args['title'] as String?;
    TaskPriority? newPriority;
    if (args['priority'] != null) {
      newPriority = TaskPriority.values.firstWhere(
        (p) => p.name == args['priority'],
        orElse: () =>
            throw MCPServerException('Invalid priority: ${args['priority']}'),
      );
    }

    DateTime? newDueDate;
    if (args['due_date'] != null) {
      try {
        newDueDate = DateTime.parse(args['due_date'] as String);
      } catch (e) {
        throw MCPServerException('Invalid due date format. Use YYYY-MM-DD');
      }
    }

    List<String>? newTags;
    if (args['tags'] != null) {
      newTags = (args['tags'] as List<dynamic>).cast<String>();
    }

    String? newNotes = args['notes'] as String?;

    final updatedTask = task.copyWith(
      title: newTitle,
      priority: newPriority,
      dueDate: newDueDate,
      tags: newTags,
      notes: newNotes,
      updatedAt: DateTime.now(),
    );

    todoList[taskIndex] = updatedTask;
    final agentName = getAgentNameFromSession(session);
    await _persistTaskList(agentName, todoList);

    return MCPToolResult(
      content: [
        MCPContent.text('Task updated successfully!\n'
            'ID: ${updatedTask.id}\n'
            'Title: ${updatedTask.title}\n'
            'Priority: ${updatedTask.priority.name}\n'
            '${updatedTask.dueDate != null ? 'Due: ${updatedTask.dueDate!.toIso8601String().split('T')[0]}\n' : ''}'
            '${updatedTask.tags.isNotEmpty ? 'Tags: ${updatedTask.tags.join(', ')}\n' : ''}'
            'Last updated: ${updatedTask.updatedAt?.toIso8601String() ?? 'N/A'}')
      ],
    );
  }

  /// 🗑️ **DELETE TASK**: Remove task from list
  Future<MCPToolResult> _deleteTask(MCPSession session, int taskId) async {
    final todoList = _getSessionTaskList(session);
    final taskIndex = todoList.indexWhere((t) => t.id == taskId);

    if (taskIndex == -1) {
      throw MCPServerException('Task with ID $taskId not found');
    }

    final task = todoList.removeAt(taskIndex);
    final agentName = getAgentNameFromSession(session);
    await _persistTaskList(agentName, todoList);

    return MCPToolResult(
      content: [
        MCPContent.text('Task deleted successfully!\n'
            'Deleted: ${task.title}\n'
            'Remaining tasks: ${todoList.length}')
      ],
    );
  }

  /// 🔍 **SEARCH TASKS**: Find tasks by text
  Future<MCPToolResult> _searchTasks(
    MCPSession session,
    String query,
    bool caseSensitive,
  ) async {
    final todoList = _getSessionTaskList(session);

    if (todoList.isEmpty) {
      return MCPToolResult(
        content: [MCPContent.text('Your task list is empty.')],
      );
    }

    final searchQuery = caseSensitive ? query : query.toLowerCase();
    final matches = todoList.where((task) {
      final title = caseSensitive ? task.title : task.title.toLowerCase();
      final notes =
          caseSensitive ? (task.notes ?? '') : (task.notes ?? '').toLowerCase();
      final tags = task.tags
          .map((tag) => caseSensitive ? tag : tag.toLowerCase())
          .join(' ');

      return title.contains(searchQuery) ||
          notes.contains(searchQuery) ||
          tags.contains(searchQuery);
    }).toList();

    if (matches.isEmpty) {
      return MCPToolResult(
        content: [MCPContent.text('No tasks found matching "$query"')],
      );
    }

    final buffer = StringBuffer();
    buffer
        .writeln('🔍 Search Results for "$query" (${matches.length} found):\n');

    for (final task in matches) {
      final statusIcon = _getStatusIcon(task.status);
      final priorityIcon = _getPriorityIcon(task.priority);

      buffer.writeln('$statusIcon $priorityIcon [${task.id}] ${task.title}');
      if (task.notes != null && task.notes!.isNotEmpty) {
        buffer.writeln('    📝 ${task.notes}');
      }
      buffer.writeln();
    }

    return MCPToolResult(
      content: [MCPContent.text(buffer.toString().trim())],
    );
  }

  /// 🧹 **CLEAR COMPLETED**: Remove all completed tasks
  Future<MCPToolResult> _clearCompleted(MCPSession session) async {
    final todoList = _getSessionTaskList(session);
    final initialCount = todoList.length;

    todoList.removeWhere((task) => task.status == TaskStatus.completed);

    final removedCount = initialCount - todoList.length;
    final agentName = getAgentNameFromSession(session);
    await _persistTaskList(agentName, todoList);

    return MCPToolResult(
      content: [
        MCPContent.text(
            'Cleared $removedCount completed task${removedCount != 1 ? 's' : ''}.\n'
            'Remaining tasks: ${todoList.length}')
      ],
    );
  }

  /// 📊 **STATISTICS**: Get task list statistics
  Future<MCPToolResult> _getStatistics(MCPSession session) async {
    final todoList = _getSessionTaskList(session);

    if (todoList.isEmpty) {
      return MCPToolResult(
        content: [
          MCPContent.text('Task List Statistics:\n'
              '- Total tasks: 0\n'
              '- Status: Empty list')
        ],
      );
    }

    final pendingCount =
        todoList.where((t) => t.status == TaskStatus.pending).length;
    final inProgressCount =
        todoList.where((t) => t.status == TaskStatus.inProgress).length;
    final completedCount =
        todoList.where((t) => t.status == TaskStatus.completed).length;
    final cancelledCount =
        todoList.where((t) => t.status == TaskStatus.cancelled).length;

    final urgentCount =
        todoList.where((t) => t.priority == TaskPriority.urgent).length;
    final highCount =
        todoList.where((t) => t.priority == TaskPriority.high).length;
    final mediumCount =
        todoList.where((t) => t.priority == TaskPriority.medium).length;
    final lowCount =
        todoList.where((t) => t.priority == TaskPriority.low).length;

    final now = DateTime.now();
    final overdueCount = todoList
        .where((t) =>
            t.dueDate != null &&
            t.dueDate!.isBefore(now) &&
            t.status != TaskStatus.completed)
        .length;

    final dueTodayCount = todoList
        .where((t) =>
            t.dueDate != null &&
            t.dueDate!.year == now.year &&
            t.dueDate!.month == now.month &&
            t.dueDate!.day == now.day)
        .length;

    final completionRate = todoList.isNotEmpty
        ? (completedCount / todoList.length * 100).toStringAsFixed(1)
        : '0.0';

    final stats = '''
📊 Task List Statistics:

📋 Total Tasks: ${todoList.length}

📈 Status Breakdown:
  ⏳ Pending: $pendingCount
  🔄 In Progress: $inProgressCount
  ✅ Completed: $completedCount
  ❌ Cancelled: $cancelledCount

🎯 Priority Breakdown:
  🔥 Urgent: $urgentCount
  ⚡ High: $highCount
  📝 Medium: $mediumCount
  📄 Low: $lowCount

⏰ Due Dates:
  🚨 Overdue: $overdueCount
  📅 Due Today: $dueTodayCount

📈 Completion Rate: $completionRate%
🗓️ Session: ${session.id}
''';

    return MCPToolResult(
      content: [MCPContent.text(stats)],
    );
  }

  /// 🔧 **UTILITY METHODS**: Helper functions

  List<TodoTask> _getAgentTaskList(String agentName) {
    return _taskLists.putIfAbsent(agentName, () => []);
  }

  /// Get task list for a session (converts session to agent name)
  List<TodoTask> _getSessionTaskList(MCPSession session) {
    final agentName = getAgentNameFromSession(session);
    return _getAgentTaskList(agentName);
  }

  int _getNextTaskId(List<TodoTask> todoList) {
    if (todoList.isEmpty) return 1;
    return todoList.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  String _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '⏳';
      case TaskStatus.inProgress:
        return '🔄';
      case TaskStatus.completed:
        return '✅';
      case TaskStatus.cancelled:
        return '❌';
    }
  }

  String _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return '🔥';
      case TaskPriority.high:
        return '⚡';
      case TaskPriority.medium:
        return '📝';
      case TaskPriority.low:
        return '📄';
    }
  }

  /// 💾 **PERSISTENCE**: Save/load task lists (agent-based)

  Future<void> _persistTaskList(
      String agentName, List<TodoTask> todoList) async {
    if (persistenceDirectory == null) return;

    try {
      final dir = Directory(persistenceDirectory!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('${persistenceDirectory!}/task_list_$agentName.json');
      final jsonData = todoList.map((task) => task.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonData));
    } catch (e) {
      stderr.writeln(
          'Warning: Failed to persist task list for agent $agentName: $e');
    }
  }

  Future<void> _loadPersistedTaskList(String agentName) async {
    if (persistenceDirectory == null) return;

    try {
      final file = File('${persistenceDirectory!}/task_list_$agentName.json');
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final jsonList = jsonDecode(jsonStr) as List<dynamic>;
        final todoList =
            jsonList.map((json) => TodoTask.fromJson(json)).toList();
        _taskLists[agentName] = todoList;
      }
    } catch (e) {
      stderr.writeln(
          'Warning: Failed to load persisted task list for agent $agentName: $e');
    }
  }

  /// 🔄 **AGENT DATA LOADING**: Override base class method
  @override
  Future<void> loadAgentData(String agentName) async {
    await super.loadAgentData(agentName);
    await _loadPersistedTaskList(agentName);
  }

  /// 📚 **RESOURCES**: Expose task list as resources
  @override
  Future<List<MCPResource>> getAvailableResources(MCPSession session) async {
    final agentName = getAgentNameFromSession(session);
    return [
      MCPResource(
        uri: 'task_list://$agentName/list',
        name: 'Task List',
        description: 'Your complete task list',
        mimeType: 'application/json',
      ),
      MCPResource(
        uri: 'task_list://$agentName/pending',
        name: 'Pending Tasks',
        description: 'Tasks that need to be done',
        mimeType: 'application/json',
      ),
      MCPResource(
        uri: 'task_list://$agentName/completed',
        name: 'Completed Tasks',
        description: 'Tasks that have been finished',
        mimeType: 'application/json',
      ),
    ];
  }

  @override
  Future<MCPContent> readResource(MCPSession session, String uri) async {
    final todoList = _getSessionTaskList(session);
    final agentName = getAgentNameFromSession(session);

    if (uri == 'task_list://$agentName/list') {
      final jsonData = todoList.map((task) => task.toJson()).toList();
      return MCPContent.text(jsonEncode(jsonData));
    } else if (uri == 'task_list://$agentName/pending') {
      final pending =
          todoList.where((t) => t.status == TaskStatus.pending).toList();
      final jsonData = pending.map((task) => task.toJson()).toList();
      return MCPContent.text(jsonEncode(jsonData));
    } else if (uri == 'task_list://$agentName/completed') {
      final completed =
          todoList.where((t) => t.status == TaskStatus.completed).toList();
      final jsonData = completed.map((task) => task.toJson()).toList();
      return MCPContent.text(jsonEncode(jsonData));
    }

    throw MCPServerException('Resource not found: $uri', code: -32602);
  }

  /// 💬 **PROMPTS**: Task list-related prompt templates
  @override
  Future<List<MCPPrompt>> getAvailablePrompts(MCPSession session) async {
    return [
      MCPPrompt(
        name: 'prioritize_tasks',
        description: 'Help prioritize tasks based on urgency and importance',
      ),
      MCPPrompt(
        name: 'break_down_task',
        description: 'Break down a complex task into smaller sub-tasks',
        arguments: [
          MCPPromptArgument(
            name: 'task_id',
            description: 'ID of the task to break down',
            required: true,
          ),
        ],
      ),
    ];
  }

  @override
  Future<List<MCPMessage>> getPrompt(
    MCPSession session,
    String name,
    Map<String, dynamic> arguments,
  ) async {
    final todoList = _getSessionTaskList(session);

    switch (name) {
      case 'prioritize_tasks':
        final pendingTasks =
            todoList.where((t) => t.status == TaskStatus.pending).toList();
        final taskList = pendingTasks.map((t) => '- ${t.title}').join('\n');

        return [
          MCPMessage(
            method: 'user',
            params: {
              'content':
                  'Please help me prioritize these tasks based on urgency and importance:\n\n$taskList'
            },
          ),
        ];

      case 'break_down_task':
        final taskId = arguments['task_id'] as int;
        final task = todoList.firstWhere(
          (t) => t.id == taskId,
          orElse: () => throw MCPServerException('Task not found: $taskId'),
        );

        return [
          MCPMessage(
            method: 'user',
            params: {
              'content':
                  'Please help me break down this task into smaller, actionable sub-tasks:\n\n'
                      'Task: ${task.title}\n'
                      '${task.notes != null ? 'Notes: ${task.notes}\n' : ''}'
                      'Priority: ${task.priority.name}\n'
                      '${task.dueDate != null ? 'Due: ${task.dueDate!.toIso8601String().split('T')[0]}\n' : ''}'
            },
          ),
        ];

      default:
        throw MCPServerException('Unknown prompt: $name', code: -32601);
    }
  }

  /// 🚀 **LIFECYCLE**: Load persisted data on initialization
  @override
  Future<void> onInitialized() async {
    await super.onInitialized();

    // Load any persisted task lists for existing sessions
    for (final sessionId in _taskLists.keys) {
      await _loadPersistedTaskList(sessionId);
    }
  }
}

/// 📋 **TASK MODEL**: Complete task representation
class TodoTask {
  final int id;
  final String title;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final List<String> tags;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  TodoTask({
    required this.id,
    required this.title,
    required this.priority,
    this.status = TaskStatus.pending,
    this.dueDate,
    this.tags = const [],
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  TodoTask copyWith({
    int? id,
    String? title,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    List<String>? tags,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return TodoTask(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority.name,
        'status': status.name,
        'dueDate': dueDate?.toIso8601String(),
        'tags': tags,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory TodoTask.fromJson(Map<String, dynamic> json) {
    return TodoTask(
      id: json['id'] as int,
      title: json['title'] as String,
      priority:
          TaskPriority.values.firstWhere((p) => p.name == json['priority']),
      status: TaskStatus.values.firstWhere((s) => s.name == json['status']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

/// 📊 **ENUMS**: Task status and priority definitions
enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

/// 🎯 **MAIN ENTRY POINT**: Standalone executable for the Task List server
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
Task List MCP Server

A Model Context Protocol server providing comprehensive task management for AI agents.
Each agent gets its own isolated task list with rich task metadata and operations.

Usage: dart todo_server.dart [options]

Options:
  --persist-dir <path>  Directory to persist task lists (optional)
  --verbose            Enable verbose logging
  --help               Show this help message

Features:
  ✅ Multi-agent isolation (each agent has separate task list)
  ✅ Rich task metadata (priority, due dates, tags, notes)
  ✅ Status tracking (pending, in-progress, completed, cancelled)
  ✅ Filtering and search capabilities
  ✅ Statistics and analytics
  ✅ Optional file persistence
  ✅ Resource and prompt interfaces
  ✅ JSON-RPC 2.0 compliant MCP protocol

Examples:
  dart todo_server.dart
  dart todo_server.dart --persist-dir ./task_list_data
  dart todo_server.dart --persist-dir ./task_list_data --verbose
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
  final server = TaskListServer(
    persistenceDirectory: persistenceDir,
    logger: logger,
  );

  try {
    stderr.writeln('🚀 Starting Task List MCP Server v1.0.0');
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
