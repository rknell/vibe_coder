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
/// 1. **Multi-Agent Isolation**: Each agent's notepad is completely separate
/// 2. **Concurrent Access**: Thread-safe operations for simultaneous agents
/// 3. **Rich Operations**: Full CRUD + append, prepend, search capabilities
/// 4. **Persistence Options**: Memory + optional file persistence
/// 5. **Schema Validation**: Proper input validation and error handling
class NotepadMCPServer extends BaseMCPServer {
  /// In-memory storage for agent notepads (agent_name -> notepad_content)
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
  Future<List<MCPTool>> getAvailableTools(MCPSession session) async {
    return [
      // 📝 READ NOTEPAD
      MCPTool(
        name: 'notepad_read',
        description: 'Read the current contents of your notepad',
        inputSchema: {
          'type': 'object',
          'properties': {},
          'required': [],
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
            'content': {
              'type': 'string',
              'description': 'The content to write to the notepad',
              'maxLength': maxNotepadSize,
            },
          },
          'required': ['content'],
        },
      ),

      // ➕ APPEND TO NOTEPAD
      MCPTool(
        name: 'notepad_append',
        description: 'Append content to the end of your notepad',
        inputSchema: {
          'type': 'object',
          'properties': {
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
          'required': ['content'],
        },
      ),

      // ⬆️ PREPEND TO NOTEPAD
      MCPTool(
        name: 'notepad_prepend',
        description: 'Prepend content to the beginning of your notepad',
        inputSchema: {
          'type': 'object',
          'properties': {
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
          'required': ['content'],
        },
      ),

      // 🗑️ CLEAR NOTEPAD
      MCPTool(
        name: 'notepad_clear',
        description: 'Clear all content from your notepad',
        inputSchema: {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      ),

      // 🔍 SEARCH NOTEPAD
      MCPTool(
        name: 'notepad_search',
        description: 'Search for text within your notepad',
        inputSchema: {
          'type': 'object',
          'properties': {
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
          'required': ['query'],
        },
      ),

      // 📊 NOTEPAD INFO
      MCPTool(
        name: 'notepad_info',
        description:
            'Get information about your notepad (size, line count, etc.)',
        inputSchema: {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      ),
    ];
  }

  /// ⚔️ **TOOL EXECUTION**: Handle notepad operations with bulletproof error handling
  @override
  Future<MCPToolResult> callTool(
    MCPSession session,
    String name,
    Map<String, dynamic> arguments,
  ) async {
    try {
      switch (name) {
        case 'notepad_read':
          return await _readNotepad(session);

        case 'notepad_write':
          final content = arguments['content'] as String;
          return await _writeNotepad(session, content);

        case 'notepad_append':
          final content = arguments['content'] as String;
          final separator = arguments['separator'] as String? ?? '\n';
          return await _appendNotepad(session, content, separator);

        case 'notepad_prepend':
          final content = arguments['content'] as String;
          final separator = arguments['separator'] as String? ?? '\n';
          return await _prependNotepad(session, content, separator);

        case 'notepad_clear':
          return await _clearNotepad(session);

        case 'notepad_search':
          final query = arguments['query'] as String;
          final caseSensitive = arguments['case_sensitive'] as bool? ?? false;
          return await _searchNotepad(session, query, caseSensitive);

        case 'notepad_info':
          return await _getNotepadInfo(session);

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
  Future<MCPToolResult> _readNotepad(MCPSession session) async {
    final agentName = getAgentNameFromSession(session);
    final content = _getAgentNotepad(agentName);

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
  Future<MCPToolResult> _writeNotepad(
      MCPSession session, String content) async {
    _validateContentSize(content);

    final agentName = getAgentNameFromSession(session);
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
    MCPSession session,
    String content,
    String separator,
  ) async {
    final agentName = getAgentNameFromSession(session);
    final existing = _getAgentNotepad(agentName);
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
    MCPSession session,
    String content,
    String separator,
  ) async {
    final agentName = getAgentNameFromSession(session);
    final existing = _getAgentNotepad(agentName);
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
  Future<MCPToolResult> _clearNotepad(MCPSession session) async {
    final agentName = getAgentNameFromSession(session);
    final previousSize = _getAgentNotepad(agentName).length;

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
    MCPSession session,
    String query,
    bool caseSensitive,
  ) async {
    final agentName = getAgentNameFromSession(session);
    final content = _getAgentNotepad(agentName);

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
  Future<MCPToolResult> _getNotepadInfo(MCPSession session) async {
    final agentName = getAgentNameFromSession(session);
    final content = _getAgentNotepad(agentName);

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
        '- Agent: $agentName\n'
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

  /// 🎯 **AGENT ISOLATION**: Get notepad for specific agent
  String _getAgentNotepad(String agentName) {
    return _notepads[agentName] ?? '';
  }

  /// 💾 **PERSISTENCE**: Save notepad to file (agent-based)
  Future<void> _persistNotepad(String agentName, String content) async {
    if (persistenceDirectory == null) return;

    try {
      final dir = Directory(persistenceDirectory!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('${persistenceDirectory!}/notepad_$agentName.txt');
      await file.writeAsString(content);
    } catch (e) {
      // Log error but don't fail the operation
      stderr.writeln(
          'Warning: Failed to persist notepad for agent $agentName: $e');
    }
  }

  /// 🔄 **RESTORE**: Load notepad from file for agent
  Future<void> _loadPersistedNotepad(String agentName) async {
    if (persistenceDirectory == null) return;

    try {
      final file = File('${persistenceDirectory!}/notepad_$agentName.txt');
      if (await file.exists()) {
        final content = await file.readAsString();
        _notepads[agentName] = content;
      }
    } catch (e) {
      stderr.writeln(
          'Warning: Failed to load persisted notepad for agent $agentName: $e');
    }
  }

  /// 🔄 **AGENT DATA LOADING**: Override base class method
  @override
  Future<void> loadAgentData(String agentName) async {
    await super.loadAgentData(agentName);
    await _loadPersistedNotepad(agentName);
  }

  /// 📚 **RESOURCES**: Expose notepad as a resource for reading
  @override
  Future<List<MCPResource>> getAvailableResources(MCPSession session) async {
    final agentName = getAgentNameFromSession(session);
    return [
      MCPResource(
        uri: 'notepad://$agentName',
        name: 'Agent Notepad',
        description: 'Your personal notepad content',
        mimeType: 'text/plain',
      ),
    ];
  }

  @override
  Future<MCPContent> readResource(MCPSession session, String uri) async {
    final agentName = getAgentNameFromSession(session);
    if (uri == 'notepad://$agentName') {
      final content = _getAgentNotepad(agentName);
      return MCPContent.text(content.isEmpty ? 'Empty notepad' : content);
    }

    throw MCPServerException('Resource not found: $uri', code: -32602);
  }

  /// 💬 **PROMPTS**: Provide notepad-related prompt templates
  @override
  Future<List<MCPPrompt>> getAvailablePrompts(MCPSession session) async {
    return [
      MCPPrompt(
        name: 'organize_notepad',
        description: 'Help organize and structure notepad content',
        arguments: [
          MCPPromptArgument(
            name: 'style',
            description:
                'Organization style (bullet_points, numbered_list, categories)',
            required: false,
          ),
        ],
      ),
      MCPPrompt(
        name: 'summarize_notepad',
        description: 'Create a summary of notepad content',
        arguments: [
          MCPPromptArgument(
            name: 'max_length',
            description: 'Maximum length of summary in words',
            required: false,
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
    final agentName = getAgentNameFromSession(session);
    final content = _getAgentNotepad(agentName);

    switch (name) {
      case 'organize_notepad':
        final style = arguments['style'] as String? ?? 'bullet_points';
        return [
          MCPMessage(
            method: 'user',
            params: {
              'content':
                  'Please organize the following notepad content using $style format:\n\n$content'
            },
          ),
        ];

      case 'summarize_notepad':
        final maxLength = arguments['max_length'] as int? ?? 100;
        return [
          MCPMessage(
            method: 'user',
            params: {
              'content':
                  'Please create a summary of the following notepad content in $maxLength words or less:\n\n$content'
            },
          ),
        ];

      default:
        throw MCPServerException('Unknown prompt: $name', code: -32601);
    }
  }

  /// 🚀 **LIFECYCLE**: Load persisted data on startup
  @override
  Future<void> onInitialized() async {
    await super.onInitialized();

    // Load any persisted notepads for existing agents
    for (final agentName in _notepads.keys) {
      await _loadPersistedNotepad(agentName);
    }
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
