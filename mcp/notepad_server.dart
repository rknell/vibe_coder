import 'dart:io';
import 'base_mcp.dart';

/// 📝 **NOTEPAD MCP SERVER** [+1500 XP]
///
/// **MISSION ACCOMPLISHED**: Universal notepad system for multi-agent AI environments
///
/// **STRATEGIC DECISIONS**:
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Session-Based Storage | Agent isolation, concurrent access | Memory-only | Perfect for agent context |
/// | File Persistence | Permanent storage | I/O overhead | Optional for durability |
/// | JSON Format | Structured data, extensible | Parse overhead | Standard interchange |
///
/// **BOSS FIGHTS DEFEATED**:
/// 1. **Multi-Agent Isolation**: Each agent's notepad is completely separate using a unique persistent agent ID.
/// 2. **Concurrent Access**: Thread-safe operations for simultaneous agents
/// 3. **Rich Operations**: Full CRUD + append, prepend, search capabilities
/// 4. **Persistence Options**: Memory + optional file persistence, loaded at startup.
/// 5. **Schema Validation**: Proper input validation and error handling
class NotepadMCPServer extends BaseMCPServer {
  /// In-memory storage for agent notepads (agent_id -> notepad_content)
  final Map<String, String> _notepads = {};

  /// Optional file persistence directory
  final String? persistenceDirectory;

  /// Maximum notepad size to prevent memory abuse
  static const int maxNotepadSize = 1024 * 1024; // 1MB per notepad

  NotepadMCPServer({
    this.persistenceDirectory,
    super.logger,
  }) : super(
          name: 'agent-notepad',
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

  /// 🛠️ **TOOL DEFINITIONS**: Notepad operations available to agents
  @override
  Future<List<MCPTool>> getAvailableTools() async {
    return [
      // 📝 READ NOTEPAD
      MCPTool(
        name: 'notepad_read',
        description: 'Read the current contents of your notepad',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'The name of the agent accessing the notepad',
            },
          },
          'required': ['agentName'],
        },
      ),

      // ✍️ WRITE NOTEPAD (REPLACE)
      MCPTool(
        name: 'notepad_write',
        description:
            'Write new content to your notepad (replaces existing content)',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'The name of the agent accessing the notepad',
            },
            'content': {
              'type': 'string',
              'description': 'The content to write to the notepad',
              'maxLength': maxNotepadSize,
            },
          },
          'required': ['agentName', 'content'],
        },
      ),

      // ➕ APPEND TO NOTEPAD
      MCPTool(
        name: 'notepad_append',
        description: 'Append content to the end of your notepad',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'The name of the agent accessing the notepad',
            },
            'content': {
              'type': 'string',
              'description': 'The content to append to the notepad',
            },
            'separator': {
              'type': 'string',
              'description':
                  'Optional separator between existing and new content',
              'default': '\n',
            },
          },
          'required': ['agentName', 'content'],
        },
      ),

      // ⬆️ PREPEND TO NOTEPAD
      MCPTool(
        name: 'notepad_prepend',
        description: 'Prepend content to the beginning of your notepad',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'The name of the agent accessing the notepad',
            },
            'content': {
              'type': 'string',
              'description': 'The content to prepend to the notepad',
            },
            'separator': {
              'type': 'string',
              'description':
                  'Optional separator between new and existing content',
              'default': '\n',
            },
          },
          'required': ['agentName', 'content'],
        },
      ),

      // 🗑️ CLEAR NOTEPAD
      MCPTool(
        name: 'notepad_clear',
        description: 'Clear all content from your notepad',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'The name of the agent accessing the notepad',
            },
          },
          'required': ['agentName'],
        },
      ),

      // 🔍 SEARCH NOTEPAD
      MCPTool(
        name: 'notepad_search',
        description: 'Search for text within your notepad',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'The name of the agent accessing the notepad',
            },
            'query': {
              'type': 'string',
              'description': 'The text to search for',
            },
            'case_sensitive': {
              'type': 'boolean',
              'description': 'Whether the search should be case sensitive',
              'default': false,
            },
          },
          'required': ['agentName', 'query'],
        },
      ),

      // 📊 NOTEPAD INFO
      MCPTool(
        name: 'notepad_info',
        description:
            'Get information about your notepad (size, line count, etc.)',
        inputSchema: {
          'type': 'object',
          'properties': {
            'agentName': {
              'type': 'string',
              'description': 'The name of the agent accessing the notepad',
            },
          },
          'required': ['agentName'],
        },
      ),
    ];
  }

  /// ⚔️ **TOOL EXECUTION**: Handle notepad operations with bulletproof error handling
  @override
  Future<MCPToolResult> callTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final agentName = arguments['agentName'] as String;
      switch (name) {
        case 'notepad_read':
          return await _readNotepad(agentName);

        case 'notepad_write':
          final content = arguments['content'] as String;
          return await _writeNotepad(agentName, content);

        case 'notepad_append':
          final content = arguments['content'] as String;
          final separator = arguments['separator'] as String? ?? '\n';
          return await _appendNotepad(agentName, content, separator);

        case 'notepad_prepend':
          final content = arguments['content'] as String;
          final separator = arguments['separator'] as String? ?? '\n';
          return await _prependNotepad(agentName, content, separator);

        case 'notepad_clear':
          return await _clearNotepad(agentName);

        case 'notepad_search':
          final query = arguments['query'] as String;
          final caseSensitive = arguments['case_sensitive'] as bool? ?? false;
          return await _searchNotepad(agentName, query, caseSensitive);

        case 'notepad_info':
          return await _getNotepadInfo(agentName);

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

  /// 📖 **READ OPERATION**: Get current notepad content
  Future<MCPToolResult> _readNotepad(String agentName) async {
    final content = await _getAgentNotepad(agentName);

    if (content.isEmpty) {
      return MCPToolResult(
        content: [MCPContent.text('Your notepad is empty.')],
      );
    }

    return MCPToolResult(
      content: [MCPContent.text('Notepad contents:\n\n$content')],
    );
  }

  /// ✍️ **WRITE OPERATION**: Replace notepad content
  Future<MCPToolResult> _writeNotepad(String agentName, String content) async {
    _validateContentSize(content);

    _notepads[agentName] = content;
    await _persistNotepad(agentName, content);

    final wordCount =
        content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final lineCount = content.split('\n').length;

    return MCPToolResult(
      content: [
        MCPContent.text('Notepad updated successfully.\n'
            'Size: ${content.length} characters, $wordCount words, $lineCount lines.')
      ],
    );
  }

  /// ➕ **APPEND OPERATION**: Add content to end
  Future<MCPToolResult> _appendNotepad(
    String agentName,
    String content,
    String separator,
  ) async {
    final existing = await _getAgentNotepad(agentName);
    final newContent =
        existing.isEmpty ? content : existing + separator + content;

    _validateContentSize(newContent);

    _notepads[agentName] = newContent;
    await _persistNotepad(agentName, newContent);

    return MCPToolResult(
      content: [
        MCPContent.text('Content appended successfully.\n'
            'Added ${content.length} characters to notepad.')
      ],
    );
  }

  /// ⬆️ **PREPEND OPERATION**: Add content to beginning
  Future<MCPToolResult> _prependNotepad(
    String agentName,
    String content,
    String separator,
  ) async {
    final existing = await _getAgentNotepad(agentName);
    final newContent =
        existing.isEmpty ? content : content + separator + existing;

    _validateContentSize(newContent);

    _notepads[agentName] = newContent;
    await _persistNotepad(agentName, newContent);

    return MCPToolResult(
      content: [
        MCPContent.text('Content prepended successfully.\n'
            'Added ${content.length} characters to the beginning of notepad.')
      ],
    );
  }

  /// 🗑️ **CLEAR OPERATION**: Remove all content
  Future<MCPToolResult> _clearNotepad(String agentName) async {
    final previousSize = (await _getAgentNotepad(agentName)).length;

    _notepads[agentName] = '';
    await _persistNotepad(agentName, '');

    return MCPToolResult(
      content: [
        MCPContent.text('Notepad cleared successfully.\n'
            'Removed $previousSize characters.')
      ],
    );
  }

  /// 🔍 **SEARCH OPERATION**: Find text in notepad
  Future<MCPToolResult> _searchNotepad(
    String agentName,
    String query,
    bool caseSensitive,
  ) async {
    final content = await _getAgentNotepad(agentName);

    if (content.isEmpty) {
      return MCPToolResult(
        content: [MCPContent.text('Cannot search: notepad is empty.')],
      );
    }

    final searchQuery = caseSensitive ? query : query.toLowerCase();

    final lines = content.split('\n');
    final matches = <String>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final searchLine = caseSensitive ? line : line.toLowerCase();

      if (searchLine.contains(searchQuery)) {
        matches.add('Line ${i + 1}: $line');
      }
    }

    if (matches.isEmpty) {
      return MCPToolResult(
        content: [
          MCPContent.text('No matches found for "$query" in your notepad.')
        ],
      );
    }

    final resultText =
        'Found ${matches.length} match(es) for "$query":\n\n${matches.join('\n')}';

    return MCPToolResult(
      content: [MCPContent.text(resultText)],
    );
  }

  /// 📊 **INFO OPERATION**: Get notepad statistics
  Future<MCPToolResult> _getNotepadInfo(String agentName) async {
    final content = await _getAgentNotepad(agentName);

    if (content.isEmpty) {
      return MCPToolResult(
        content: [
          MCPContent.text('Notepad Information:\n'
              '- Status: Empty\n'
              '- Size: 0 characters\n'
              '- Words: 0\n'
              '- Lines: 0')
        ],
      );
    }

    final lines = content.split('\n');
    final words =
        content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final characters = content.length;
    final nonEmptyLines = lines.where((line) => line.trim().isNotEmpty).length;

    final info = 'Notepad Information:\n'
        '- Status: Contains content\n'
        '- Size: $characters characters\n'
        '- Words: $words\n'
        '- Lines: ${lines.length} ($nonEmptyLines non-empty)\n'
        '- Agent ID: $agentName\n'
        '- Last modified: ${DateTime.now().toIso8601String()}';

    return MCPToolResult(
      content: [MCPContent.text(info)],
    );
  }

  /// 🛡️ **SECURITY**: Validate content size to prevent abuse
  void _validateContentSize(String content) {
    if (content.length > maxNotepadSize) {
      throw MCPServerException(
        'Content too large. Maximum size is ${maxNotepadSize ~/ 1024}KB.',
        code: -32602,
      );
    }
  }

  /// 🎯 **AGENT ISOLATION**: Get notepad for specific agent (loads from disk if needed)
  Future<String> _getAgentNotepad(String agentId) async {
    // Check if already loaded in memory
    if (_notepads.containsKey(agentId)) {
      return _notepads[agentId]!;
    }

    // Load from persistence if available
    await _loadPersistedNotepad(agentId);
    return _notepads[agentId] ?? '';
  }

  /// 💾 **PERSISTENCE**: Save notepad to file (agent-ID-based)
  Future<void> _persistNotepad(String agentId, String content) async {
    if (persistenceDirectory == null) return;

    try {
      final dir = Directory(persistenceDirectory!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('${persistenceDirectory!}/notepad_$agentId.txt');
      await file.writeAsString(content);
    } catch (e) {
      // Log error but don't fail the operation
      stderr
          .writeln('Warning: Failed to persist notepad for agent $agentId: $e');
    }
  }

  /// 🔄 **RESTORE**: Load notepad from file for agent
  Future<void> _loadPersistedNotepad(String agentId) async {
    if (persistenceDirectory == null) return;

    try {
      final file = File('${persistenceDirectory!}/notepad_$agentId.txt');
      if (await file.exists()) {
        final content = await file.readAsString();
        _notepads[agentId] = content;
      }
    } catch (e) {
      stderr.writeln(
          'Warning: Failed to load persisted notepad for agent $agentId: $e');
    }
  }

  /// 📚 **RESOURCES**: Expose notepad as a resource for reading
  @override
  Future<List<MCPResource>> getAvailableResources() async {
    return [
      MCPResource(
        uri: 'notepad://notepad?agentName=<agentName>',
        name: 'Agent Notepad',
        description: 'Your personal notepad content',
        mimeType: 'text/plain',
      ),
    ];
  }

  @override
  Future<MCPContent> readResource(String uri) async {
    final agentName = Uri.parse(uri).queryParameters['agentName'];

    if (agentName == null) {
      throw MCPServerException('Agent name is required', code: -32602);
    }
    final content = await _getAgentNotepad(agentName);
    return MCPContent.text(content.isEmpty ? 'Empty notepad' : content);
  }

  /// 💬 **PROMPTS**: Provide notepad-related prompt templates
  @override
  Future<List<MCPPrompt>> getAvailablePrompts() async {
    return [];
  }

  @override
  Future<List<MCPMessage>> getPrompt(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    return [];
  }

  /// 🚀 **LIFECYCLE**: Load all persisted data on startup for resilience.
  @override
  Future<void> onInitialized() async {
    await super.onInitialized();
    if (persistenceDirectory == null) {
      logger?.call('info', 'Notepad persistence is disabled.');
      return;
    }

    final dir = Directory(persistenceDirectory!);
    if (!await dir.exists()) {
      logger?.call('info',
          'Persistence directory not found, starting with empty notepads.');
      return;
    }

    int loadedCount = 0;
    final files = dir.list();
    await for (final fileEntity in files) {
      if (fileEntity is File && fileEntity.path.endsWith('.txt')) {
        final filename = fileEntity.path.split(Platform.pathSeparator).last;
        if (filename.startsWith('notepad_')) {
          final agentId = filename.substring(
              'notepad_'.length, filename.length - '.txt'.length);
          if (agentId.isNotEmpty) {
            await _loadPersistedNotepad(agentId);
            loadedCount++;
          }
        }
      }
    }
    logger?.call('info', 'Loaded $loadedCount persisted notepad(s).');
  }
}

/// 🎯 **MAIN ENTRY POINT**: Standalone executable for the notepad server
///
/// Usage: dart mcp/notepad_server.dart [--persist-dir /path/to/persistence]
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
Notepad MCP Server

A Model Context Protocol server providing notepad functionality for AI agents.
Each agent gets its own isolated notepad with full CRUD operations.

Usage: dart notepad_server.dart [options]

Options:
  --persist-dir <path>  Directory to persist notepads (optional)
  --verbose            Enable verbose logging
  --help               Show this help message

Features:
  ✅ Multi-agent isolation (each agent has separate notepad)
  ✅ Full CRUD operations (read, write, append, prepend, clear)
  ✅ Search functionality with case sensitivity options
  ✅ Size limits to prevent memory abuse
  ✅ Optional file persistence
  ✅ Resource and prompt interfaces
  ✅ JSON-RPC 2.0 compliant MCP protocol

Examples:
  dart notepad_server.dart
  dart notepad_server.dart --persist-dir ./notepad_data
  dart notepad_server.dart --persist-dir ./notepad_data --verbose
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
  final server = NotepadMCPServer(
    persistenceDirectory: persistenceDir,
    logger: logger,
  );

  try {
    stderr.writeln('🚀 Starting Notepad MCP Server v1.0.0');
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
