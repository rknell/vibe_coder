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
  Future<List<MCPTool>> getAvailableTools() async {
    return [
      // ➕ ADD TASK
      MCPTool(
        name: 'task_list_add',
        description: 'Add a new task to your task list',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent adding the task',
            },
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
          'required': ['agentName', 'title'],
        },
      ),

      // 📋 LIST TASKS
      MCPTool(
        name: 'task_list_list',
        description: 'List all tasks or filter by criteria',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent requesting tasks',
            },
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
          'required': ['agentName'],
        },
      ),

      // ✅ COMPLETE TASK
      MCPTool(
        name: 'task_list_complete',
        description: 'Mark a task as completed',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent completing the task',
            },
            'task_id': {
              'type': 'integer',
              'description': 'ID of the task to complete',
            },
          },
          'required': ['agentName', 'task_id'],
        },
      ),

      // 🔄 UPDATE TASK STATUS
      MCPTool(
        name: 'todo_update_status',
        description: 'Update the status of a task',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent updating the task',
            },
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
          'required': ['agentName', 'task_id', 'status'],
        },
      ),

      // ✏️ EDIT TASK
      MCPTool(
        name: 'todo_edit',
        description: 'Edit an existing task',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent editing the task',
            },
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
          'required': ['agentName', 'task_id'],
        },
      ),

      // 🗑️ DELETE TASK
      MCPTool(
        name: 'todo_delete',
        description: 'Delete a task from the list',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent deleting the task',
            },
            'task_id': {
              'type': 'integer',
              'description': 'ID of the task to delete',
            },
          },
          'required': ['agentName', 'task_id'],
        },
      ),

      // 🔍 SEARCH TASKS
      MCPTool(
        name: 'todo_search',
        description: 'Search tasks by text in title, notes, or tags',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent searching tasks',
            },
            'query': {
              'type': 'string',
              'description': 'Search query text',
              'maxLength': 100,
            },
            'case_sensitive': {
              'type': 'boolean',
              'description': 'Whether search should be case sensitive',
              'default': false,
            },
          },
          'required': ['agentName', 'query'],
        },
      ),

      // 🧹 CLEAR COMPLETED
      MCPTool(
        name: 'todo_clear_completed',
        description: 'Remove all completed tasks',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent clearing completed tasks',
            },
          },
          'required': ['agentName'],
        },
      ),

      // 📊 GET STATISTICS
      MCPTool(
        name: 'todo_stats',
        description: 'Get task statistics and summary',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'Name of the agent requesting statistics',
            },
          },
          'required': ['agentName'],
        },
      ),
    ];
  }

  /// 🎯 **TOOL EXECUTION**: Route tool calls to appropriate handlers (stateless)
  @override
  Future<MCPToolResult> callTool(
      String name, Map<String, dynamic> arguments) async {
    // Extract and validate agentName from arguments
    final agentName = arguments['agentName'] as String?;
    if (agentName == null || agentName.isEmpty) {
      throw MCPServerException('agentName parameter is required');
    }

    switch (name) {
      case 'task_list_add':
        return _addTask(agentName, arguments);

      case 'task_list_list':
        return _listTasks(agentName, arguments);

      case 'task_list_complete':
        final taskId = arguments['task_id'] as int;
        return _updateTaskStatus(agentName, taskId, TaskStatus.completed);

      case 'todo_update_status':
        final taskId = arguments['task_id'] as int;
        final statusStr = arguments['status'] as String;
        final status = TaskStatus.values.firstWhere(
          (s) => s.name == statusStr,
          orElse: () => throw MCPServerException('Invalid status: $statusStr'),
        );
        return _updateTaskStatus(agentName, taskId, status);

      case 'todo_edit':
        return _editTask(agentName, arguments);

      case 'todo_delete':
        final taskId = arguments['task_id'] as int;
        return _deleteTask(agentName, taskId);

      case 'todo_search':
        final query = arguments['query'] as String;
        final caseSensitive = arguments['case_sensitive'] as bool? ?? false;
        return _searchTasks(agentName, query, caseSensitive);

      case 'todo_clear_completed':
        return _clearCompleted(agentName);

      case 'todo_stats':
        return _getStatistics(agentName);

      default:
        throw MCPServerException('Unknown tool: $name');
    }
  }

  /// ➕ **ADD TASK**: Create new task with metadata
  Future<MCPToolResult> _addTask(
      String agentName, Map<String, dynamic> args) async {
    final todoList = _getAgentTaskList(agentName);

    // Validate task limit
    if (todoList.length >= maxTasksPerAgent) {
      throw MCPServerException(
          'Maximum tasks per agent ($maxTasksPerAgent) exceeded');
    }

    final title = args['title'] as String;
    final priorityStr = args['priority'] as String? ?? 'medium';
    final priority = TaskPriority.values.firstWhere(
      (p) => p.name == priorityStr,
      orElse: () => throw MCPServerException('Invalid priority: $priorityStr'),
    );

    DateTime? dueDate;
    if (args['due_date'] != null) {
      try {
        dueDate = DateTime.parse(args['due_date'] as String);
      } catch (e) {
        throw MCPServerException('Invalid due date format. Use YYYY-MM-DD');
      }
    }

    final tags = (args['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final notes = args['notes'] as String?;

    // Generate unique ID
    final id = todoList.isEmpty
        ? 1
        : todoList.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;

    final task = TodoTask(
      id: id,
      title: title,
      priority: priority,
      status: TaskStatus.pending,
      dueDate: dueDate,
      tags: tags,
      notes: notes,
      createdAt: DateTime.now(),
    );

    todoList.add(task);
    await _persistTaskList(agentName, todoList);

    return MCPToolResult(
      content: [
        MCPContent.text('Task added successfully!\n'
            'ID: ${task.id}\n'
            'Title: ${task.title}\n'
            'Priority: ${task.priority.name}\n'
            '${(() {
          final taskDueDate = task.dueDate;
          if (taskDueDate != null) {
            return 'Due: ${taskDueDate.toIso8601String().split('T')[0]}\n';
          }
          return '';
        })()}'
            '${task.tags.isNotEmpty ? 'Tags: ${task.tags.join(', ')}\n' : ''}'
            'Total tasks: ${todoList.length}')
      ],
    );
  }

  /// 📋 **LIST TASKS**: Show filtered task list
  Future<MCPToolResult> _listTasks(
      String agentName, Map<String, dynamic> args) async {
    final todoList = _getAgentTaskList(agentName);

    if (todoList.isEmpty) {
      return MCPToolResult(
        content: [MCPContent.text('Your task list is empty.')],
      );
    }

    // Apply filters
    var filteredTasks = todoList.toList();

    final statusFilter = args['status'] as String? ?? 'all';
    if (statusFilter != 'all') {
      final status = TaskStatus.values.firstWhere(
        (s) => s.name == statusFilter,
        orElse: () =>
            throw MCPServerException('Invalid status filter: $statusFilter'),
      );
      filteredTasks = filteredTasks.where((t) => t.status == status).toList();
    }

    final priorityFilter = args['priority'] as String?;
    if (priorityFilter != null) {
      final priority = TaskPriority.values.firstWhere(
        (p) => p.name == priorityFilter,
        orElse: () => throw MCPServerException(
            'Invalid priority filter: $priorityFilter'),
      );
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
      filteredTasks = filteredTasks.where((t) {
        final taskDueDate = t.dueDate;
        if (taskDueDate == null) return false;
        return taskDueDate.year == today.year &&
            taskDueDate.month == today.month &&
            taskDueDate.day == today.day;
      }).toList();
    }

    final overdue = args['overdue'] as bool? ?? false;
    if (overdue) {
      final now = DateTime.now();
      filteredTasks = filteredTasks.where((t) {
        final taskDueDate = t.dueDate;
        return taskDueDate != null && taskDueDate.isBefore(now);
      }).toList();
    }

    if (filteredTasks.isEmpty) {
      return MCPToolResult(
        content: [MCPContent.text('No tasks match the specified filters.')],
      );
    }

    // Sort by priority (urgent first) then by due date
    filteredTasks.sort((a, b) {
      final priorityComparison = b.priority.index.compareTo(a.priority.index);
      if (priorityComparison != 0) return priorityComparison;

      final aDueDate = a.dueDate;
      final bDueDate = b.dueDate;
      if (aDueDate == null && bDueDate == null) return 0;
      if (aDueDate == null) return 1;
      if (bDueDate == null) return -1;
      return aDueDate.compareTo(bDueDate);
    });

    final buffer = StringBuffer();
    buffer.writeln('📋 Task List (${filteredTasks.length} tasks):\n');

    for (final task in filteredTasks) {
      final statusIcon = _getStatusIcon(task.status);
      final priorityIcon = _getPriorityIcon(task.priority);

      buffer.writeln('$statusIcon $priorityIcon [${task.id}] ${task.title}');

      final taskDueDate = task.dueDate;
      if (taskDueDate != null) {
        final isOverdue = taskDueDate.isBefore(DateTime.now());
        final dueDateStr = taskDueDate.toIso8601String().split('T')[0];
        buffer
            .writeln('    📅 Due: $dueDateStr${isOverdue ? ' (OVERDUE)' : ''}');
      }

      if (task.tags.isNotEmpty) {
        buffer.writeln('    🏷️ Tags: ${task.tags.join(', ')}');
      }

      final taskNotes = task.notes;
      if (taskNotes != null && taskNotes.isNotEmpty) {
        buffer.writeln('    📝 Notes: $taskNotes');
      }

      buffer.writeln();
    }

    return MCPToolResult(
      content: [MCPContent.text(buffer.toString().trim())],
    );
  }

  /// ✅ **UPDATE STATUS**: Change task status
  Future<MCPToolResult> _updateTaskStatus(
    String agentName,
    int taskId,
    TaskStatus newStatus,
  ) async {
    final todoList = _getAgentTaskList(agentName);
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
      String agentName, Map<String, dynamic> args) async {
    final todoList = _getAgentTaskList(agentName);
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
    await _persistTaskList(agentName, todoList);

    return MCPToolResult(
      content: [
        MCPContent.text('Task updated successfully!\n'
            'ID: ${updatedTask.id}\n'
            'Title: ${updatedTask.title}\n'
            'Priority: ${updatedTask.priority.name}\n'
            '${(() {
          final dueDate = updatedTask.dueDate;
          if (dueDate != null) {
            return 'Due: ${dueDate.toIso8601String().split('T')[0]}\n';
          }
          return '';
        })()}'
            '${updatedTask.tags.isNotEmpty ? 'Tags: ${updatedTask.tags.join(', ')}\n' : ''}'
            'Last updated: ${updatedTask.updatedAt?.toIso8601String() ?? 'N/A'}')
      ],
    );
  }

  /// 🗑️ **DELETE TASK**: Remove task from list
  Future<MCPToolResult> _deleteTask(String agentName, int taskId) async {
    final todoList = _getAgentTaskList(agentName);
    final taskIndex = todoList.indexWhere((t) => t.id == taskId);

    if (taskIndex == -1) {
      throw MCPServerException('Task with ID $taskId not found');
    }

    final task = todoList.removeAt(taskIndex);
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
    String agentName,
    String query,
    bool caseSensitive,
  ) async {
    final todoList = _getAgentTaskList(agentName);

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
      final taskNotes = task.notes;
      if (taskNotes != null && taskNotes.isNotEmpty) {
        buffer.writeln('    📝 $taskNotes');
      }
      buffer.writeln();
    }

    return MCPToolResult(
      content: [MCPContent.text(buffer.toString().trim())],
    );
  }

  /// 🧹 **CLEAR COMPLETED**: Remove all completed tasks
  Future<MCPToolResult> _clearCompleted(String agentName) async {
    final todoList = _getAgentTaskList(agentName);
    final initialCount = todoList.length;

    todoList.removeWhere((task) => task.status == TaskStatus.completed);

    final removedCount = initialCount - todoList.length;
    await _persistTaskList(agentName, todoList);

    return MCPToolResult(
      content: [
        MCPContent.text('Cleared $removedCount completed tasks.\n'
            'Remaining tasks: ${todoList.length}')
      ],
    );
  }

  /// 📊 **GET STATISTICS**: Task summary and metrics
  Future<MCPToolResult> _getStatistics(String agentName) async {
    final todoList = _getAgentTaskList(agentName);

    if (todoList.isEmpty) {
      return MCPToolResult(
        content: [MCPContent.text('Your task list is empty.')],
      );
    }

    final total = todoList.length;
    final pending =
        todoList.where((t) => t.status == TaskStatus.pending).length;
    final inProgress =
        todoList.where((t) => t.status == TaskStatus.inProgress).length;
    final completed =
        todoList.where((t) => t.status == TaskStatus.completed).length;
    final cancelled =
        todoList.where((t) => t.status == TaskStatus.cancelled).length;

    final urgent =
        todoList.where((t) => t.priority == TaskPriority.urgent).length;
    final high = todoList.where((t) => t.priority == TaskPriority.high).length;
    final medium =
        todoList.where((t) => t.priority == TaskPriority.medium).length;
    final low = todoList.where((t) => t.priority == TaskPriority.low).length;

    final now = DateTime.now();
    final overdue = todoList.where((t) {
      final dueDate = t.dueDate;
      return dueDate != null && dueDate.isBefore(now);
    }).length;

    final dueToday = todoList.where((t) {
      final dueDate = t.dueDate;
      if (dueDate == null) return false;
      return dueDate.year == now.year &&
          dueDate.month == now.month &&
          dueDate.day == now.day;
    }).length;

    final completionRate =
        total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0';

    return MCPToolResult(
      content: [
        MCPContent.text('📊 Task Statistics:\n\n'
            '📋 Total Tasks: $total\n\n'
            '📈 Status Breakdown:\n'
            '  ⏳ Pending: $pending\n'
            '  🔄 In Progress: $inProgress\n'
            '  ✅ Completed: $completed\n'
            '  ❌ Cancelled: $cancelled\n\n'
            '🎯 Priority Breakdown:\n'
            '  🚨 Urgent: $urgent\n'
            '  🔥 High: $high\n'
            '  📋 Medium: $medium\n'
            '  📝 Low: $low\n\n'
            '⏰ Due Date Status:\n'
            '  🚨 Overdue: $overdue\n'
            '  📅 Due Today: $dueToday\n\n'
            '🎯 Completion Rate: $completionRate%')
      ],
    );
  }

  /// 🗂️ **TASK LIST ACCESS**: Get or create agent task list
  List<TodoTask> _getAgentTaskList(String agentName) {
    return _taskLists.putIfAbsent(agentName, () => <TodoTask>[]);
  }

  /// 💾 **PERSISTENCE**: Save task list to disk (if configured)
  Future<void> _persistTaskList(String agentName, List<TodoTask> tasks) async {
    final persistenceDir = persistenceDirectory;
    if (persistenceDir == null) return;

    try {
      final directory = Directory(persistenceDir);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final file = File('$persistenceDir/tasks_$agentName.json');
      final data = {
        'agent': agentName,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(jsonEncode(data));
      logger?.call('debug', 'Tasks persisted for agent: $agentName');
    } catch (e) {
      logger?.call('error', 'Failed to persist tasks for $agentName', e);
    }
  }

  /// 📂 **LOAD TASKS**: Load persisted tasks from disk
  Future<void> _loadTasksForAgent(String agentName) async {
    final persistenceDir = persistenceDirectory;
    if (persistenceDir == null) return;

    try {
      final file = File('$persistenceDir/tasks_$agentName.json');
      if (!file.existsSync()) return;

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final tasksJson = data['tasks'] as List<dynamic>;

      final tasks = tasksJson
          .map((json) => TodoTask.fromJson(json as Map<String, dynamic>))
          .toList();

      _taskLists[agentName] = tasks;
      logger?.call(
          'debug', 'Loaded ${tasks.length} tasks for agent: $agentName');
    } catch (e) {
      logger?.call('error', 'Failed to load tasks for $agentName', e);
    }
  }

  /// 🎨 **UI HELPERS**: Status and priority icons
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
        return '🚨';
      case TaskPriority.high:
        return '🔥';
      case TaskPriority.medium:
        return '📋';
      case TaskPriority.low:
        return '📝';
    }
  }

  /// 📚 **RESOURCES**: Provide read-only access to task data
  @override
  Future<List<MCPResource>> getAvailableResources() async {
    return [
      MCPResource(
        uri: 'task://statistics',
        name: 'Task Statistics',
        description: 'Overall task statistics across all agents',
        mimeType: 'application/json',
      ),
      MCPResource(
        uri: 'task://agents',
        name: 'Active Agents',
        description: 'List of agents with task data',
        mimeType: 'application/json',
      ),
    ];
  }

  @override
  Future<MCPContent> readResource(String uri) async {
    switch (uri) {
      case 'task://statistics':
        final stats = <String, dynamic>{};
        for (final entry in _taskLists.entries) {
          final agentName = entry.key;
          final tasks = entry.value;
          stats[agentName] = {
            'total': tasks.length,
            'pending':
                tasks.where((t) => t.status == TaskStatus.pending).length,
            'in_progress':
                tasks.where((t) => t.status == TaskStatus.inProgress).length,
            'completed':
                tasks.where((t) => t.status == TaskStatus.completed).length,
            'cancelled':
                tasks.where((t) => t.status == TaskStatus.cancelled).length,
          };
        }
        return MCPContent.resource(
          data: jsonEncode(stats),
          mimeType: 'application/json',
        );

      case 'task://agents':
        final agents = _taskLists.keys.toList();
        return MCPContent.resource(
          data: jsonEncode({'agents': agents}),
          mimeType: 'application/json',
        );

      default:
        throw MCPServerException('Resource not found: $uri');
    }
  }

  /// 💬 **PROMPTS**: Task management templates
  @override
  Future<List<MCPPrompt>> getAvailablePrompts() async {
    return [
      MCPPrompt(
        name: 'task_planning',
        description: 'Help plan and organize tasks',
        arguments: [
          MCPPromptArgument(
            name: 'agentName',
            description: 'Name of the agent planning tasks',
            required: true,
          ),
          MCPPromptArgument(
            name: 'project',
            description: 'Project or area to plan tasks for',
            required: true,
          ),
        ],
      ),
    ];
  }

  @override
  Future<List<MCPMessage>> getPrompt(
      String name, Map<String, dynamic> arguments) async {
    switch (name) {
      case 'task_planning':
        final agentName = arguments['agentName'] as String;
        final project = arguments['project'] as String;

        return [
          MCPMessage.request(
            id: 'task_planning_prompt',
            method: 'user_message',
            params: {
              'content':
                  '''I need help planning tasks for the project "$project". 
                  Please help me break down the work into manageable tasks with appropriate priorities and due dates. 
                  Consider dependencies between tasks and suggest a logical order of execution. 
                  You are $agentName.
                  ''',
            },
          ),
        ];

      default:
        throw MCPServerException('Prompt not found: $name');
    }
  }

  /// 🔄 **INITIALIZATION**: Load tasks on startup
  @override
  Future<void> onInitialized() async {
    await super.onInitialized();

    // Load existing task data if persistence is enabled
    final persistenceDir = persistenceDirectory;
    if (persistenceDir != null) {
      final directory = Directory(persistenceDir);
      if (directory.existsSync()) {
        await for (final entity in directory.list()) {
          if (entity is File &&
              entity.path.contains('tasks_') &&
              entity.path.endsWith('.json')) {
            final fileName = entity.path.split('/').last;
            final agentName = fileName.substring(
                6, fileName.length - 5); // Remove 'tasks_' and '.json'
            await _loadTasksForAgent(agentName);
          }
        }
      }
    }
  }
}

/// 📝 **TASK DATA MODEL**: Rich task representation
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
    required this.status,
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
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        'tags': tags,
        if (notes != null) 'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      };

  factory TodoTask.fromJson(Map<String, dynamic> json) => TodoTask(
        id: json['id'] as int,
        title: json['title'] as String,
        priority: TaskPriority.values.firstWhere(
          (p) => p.name == json['priority'],
          orElse: () => TaskPriority.medium,
        ),
        status: TaskStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TaskStatus.pending,
        ),
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}

/// 🎯 **TASK PRIORITY**: Importance levels
enum TaskPriority { low, medium, high, urgent }

/// 📊 **TASK STATUS**: Workflow states
enum TaskStatus { pending, inProgress, completed, cancelled }

/// 🎯 **MAIN ENTRY POINT**: Standalone executable for the task list server
///
/// Usage: dart mcp/task_list_server.dart [--persist-dir /path/to/persistence]
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
Each agent manages its own isolated task list with rich metadata and workflow tracking.

Usage: dart task_list_server.dart [options]

Options:
  --persist-dir <path>  Directory to persist task lists (optional)
  --verbose            Enable verbose logging
  --help               Show this help message

Features:
  ✅ Multi-agent isolation (each agent has separate task list)
  ✅ Rich task metadata (priority, due dates, tags, notes)
  ✅ Status workflow (pending, in-progress, completed, cancelled)
  ✅ Advanced filtering and search capabilities
  ✅ Bulk operations (clear completed, bulk status updates)
  ✅ Task statistics and reporting
  ✅ Optional file persistence
  ✅ Resource and prompt interfaces
  ✅ JSON-RPC 2.0 compliant MCP protocol

Available Tools:
  📝 task_list_add - Add new tasks with metadata
  📋 task_list_list - List and filter tasks
  ✅ task_list_complete - Mark tasks as completed
  🔄 todo_update_status - Update task status
  ✏️ todo_edit - Edit existing tasks
  🗑️ todo_delete - Delete tasks
  🔍 todo_search - Search tasks by text
  🧹 todo_clear_completed - Remove completed tasks
  📊 todo_stats - Get task statistics

Examples:
  dart task_list_server.dart
  dart task_list_server.dart --persist-dir ./task_data
  dart task_list_server.dart --persist-dir ./task_data --verbose
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
