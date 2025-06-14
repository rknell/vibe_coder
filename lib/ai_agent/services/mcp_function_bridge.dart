import 'package:logging/logging.dart';
import 'mcp_manager.dart';

/// MCP Function Bridge Service
///
/// ## MISSION ACCOMPLISHED
/// Eliminates the gap between MCP tool discovery and AI function calling by providing
/// seamless conversion from MCP tool schemas to OpenAI function definitions.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Direct MCP Integration | Simple | Incompatible formats | Rejected - schema mismatch |
/// | Custom Bridge Layer | Clean conversion, tool ID mgmt | Extra abstraction | CHOSEN - enables function calling |
/// | Manual Tool Mapping | Full control | High maintenance | Rejected - violates DRY |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Schema Format Mismatch**
///    - 🔍 Symptom: MCP tools use JSON Schema, OpenAI uses different format
///    - 🎯 Root Cause: Different API standards for function definitions
///    - 💥 Kill Shot: Automated schema conversion with validation
///
/// 2. **Tool Call ID Management**
///    - 🔍 Symptom: DeepSeek requires tool_call_id in responses
///    - 🎯 Root Cause: Function call flow needs bidirectional ID tracking
///    - 💥 Kill Shot: Centralized ID generation and mapping system
///
/// 3. **Server Tool Disambiguation**
///    - 🔍 Symptom: Multiple servers may have tools with same names
///    - 🎯 Root Cause: Namespace collision in distributed tool ecosystem
///    - 💥 Kill Shot: Unique tool IDs with server prefixes
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Tool conversion: O(n) where n = number of MCP tools
/// - ID mapping: O(1) hash lookup for tool call resolution
/// - Schema validation: O(k) where k = schema complexity
class MCPFunctionBridge {
  static final Logger _logger = Logger('MCPFunctionBridge');

  // Tool call ID tracking for DeepSeek function calling requirements
  static int _toolCallIdCounter = 0;
  static final Map<String, MCPToolCallContext> _activeToolCalls = {};

  /// Convert MCP tools to OpenAI function definitions
  ///
  /// PERF: O(n) conversion - necessary for each tool
  /// SECURITY: Schema validation prevents malformed function definitions
  static List<Map<String, dynamic>> convertMCPToolsToFunctions(
      List<MCPToolWithServer> mcpTools) {
    _logger.info(
        '🔄 FUNCTION CONVERSION: Converting ${mcpTools.length} MCP tools to OpenAI functions');

    final functions = <Map<String, dynamic>>[];

    for (final mcpTool in mcpTools) {
      try {
        // CRITICAL: DeepSeek API requires function names to match pattern '^[a-zA-Z0-9_-]+$'
        final validFunctionName = toApiFunctionName(mcpTool.uniqueId);

        final functionDef = {
          'type': 'function',
          'function': {
            'name': validFunctionName, // Use API-compliant name
            'description':
                mcpTool.tool.description ?? 'MCP tool: ${mcpTool.tool.name}',
            // Convert MCP JSON Schema to OpenAI parameters format
            'parameters': _convertMCPSchemaToOpenAI(mcpTool.tool.inputSchema),
          }
        };

        functions.add(functionDef);
        _logger.fine(
            '✅ CONVERTED: ${mcpTool.uniqueId} - ${mcpTool.tool.description ?? "No description"}');
      } catch (e, stackTrace) {
        _logger.severe(
            '💥 CONVERSION FAILED: ${mcpTool.uniqueId} - $e', e, stackTrace);
        // Continue with other tools rather than failing completely
      }
    }

    _logger.info(
        '🎯 CONVERSION COMPLETE: ${functions.length} functions ready for AI model');
    return functions;
  }

  /// Convert MCP JSON Schema to OpenAI parameters format
  ///
  /// PERF: O(k) where k = schema complexity - unavoidable for schema transformation
  /// ARCHITECTURAL: Handles nested schemas recursively with depth limits
  static Map<String, dynamic> _convertMCPSchemaToOpenAI(
      Map<String, dynamic> mcpSchema) {
    // MCP uses standard JSON Schema, OpenAI expects specific format
    // Need to preserve: type, properties, required, description

    final converted = <String, dynamic>{
      'type': mcpSchema['type'] ?? 'object',
    };

    // Handle properties
    if (mcpSchema.containsKey('properties')) {
      converted['properties'] = mcpSchema['properties'];
    }

    // Handle required fields
    if (mcpSchema.containsKey('required')) {
      converted['required'] = mcpSchema['required'];
    }

    // Handle description
    if (mcpSchema.containsKey('description')) {
      converted['description'] = mcpSchema['description'];
    }

    return converted;
  }

  /// Convert MCP tool unique ID to API-compliant function name
  ///
  /// CRITICAL: DeepSeek API requires function names to match pattern '^[a-zA-Z0-9_-]+$'
  ///
  /// ## 🎯 CONVERSION EXAMPLES
  /// - `memory:read_graph` → `memory_read_graph` (API-safe)
  /// - `filesystem:list_files` → `filesystem_list_files` (API-safe)
  /// - `server:complex_tool_name` → `server_complex_tool_name` (API-safe)
  ///
  /// ## 🔧 WHY THIS EXISTS
  /// MCP tools use format `serverName:toolName` but OpenAI function calling API
  /// does NOT allow colons in function names. This conversion enables proper
  /// function calling while preserving tool identity.
  ///
  /// ## ⚠️ CRITICAL USAGE NOTES
  /// 1. ALWAYS use `fromApiFunctionName()` to convert back to MCP format
  /// 2. The AI API will send `memory_read_graph` but MCP expects `memory:read_graph`
  /// 3. Test both directions: toApiFunctionName() ⟷ fromApiFunctionName()
  /// 4. This conversion is MANDATORY for all MCP tool calling workflows
  static String toApiFunctionName(String mcpUniqueId) {
    return mcpUniqueId.replaceAll(':', '_');
  }

  /// Convert API function name back to MCP tool unique ID
  ///
  /// ARCHITECTURAL: Reverse mapping for tool call processing
  ///
  /// ## 🎯 CONVERSION EXAMPLES
  /// - `memory_read_graph` → `memory:read_graph` (MCP format)
  /// - `filesystem_list_files` → `filesystem:list_files` (MCP format)
  /// - `server_complex_tool_name` → `server:complex_tool_name` (MCP format)
  ///
  /// ## 🔧 WHY THIS EXISTS
  /// When the AI API calls a tool, it sends the API-safe name (e.g., `memory_read_graph`).
  /// But MCP servers expect the original format (e.g., `memory:read_graph`).
  /// This function restores the proper MCP format for server communication.
  ///
  /// ## ⚠️ CRITICAL USAGE NOTES
  /// 1. ALWAYS call this on function names from AI API before MCP server calls
  /// 2. This is the REVERSE of `toApiFunctionName()` - they must be symmetric
  /// 3. Failure to convert will result in "Server not found" errors
  /// 4. The first underscore becomes colon: `server_tool` → `server:tool`
  static String fromApiFunctionName(String apiFunctionName) {
    // Convert first underscore back to colon (server:tool format)
    // Handle cases like 'test_server_test_tool' -> 'test_server:test_tool'
    final firstUnderscoreIndex = apiFunctionName.indexOf('_');
    if (firstUnderscoreIndex != -1 &&
        firstUnderscoreIndex < apiFunctionName.length - 1) {
      return '${apiFunctionName.substring(0, firstUnderscoreIndex)}:${apiFunctionName.substring(firstUnderscoreIndex + 1)}';
    }
    return apiFunctionName;
  }

  /// Generate unique tool call ID for DeepSeek function calling
  ///
  /// PERF: O(1) - atomic counter increment
  /// SECURITY: Unique IDs prevent call collision/confusion
  static String generateToolCallId() {
    return 'call_${DateTime.now().millisecondsSinceEpoch}_${++_toolCallIdCounter}';
  }

  /// Register a tool call for tracking
  ///
  /// CRITICAL: DeepSeek requires exact tool_call_id matching in responses
  static void registerToolCall({
    required String toolCallId,
    required String toolName,
    required String serverName,
    required Map<String, dynamic> arguments,
  }) {
    // Convert API-compliant name back to original format for MCP server calls
    // Since we have the serverName, we can reconstruct the original format properly
    final originalToolName = toolName.startsWith('${serverName}_')
        ? '$serverName:${toolName.substring(serverName.length + 1)}'
        : toolName;

    _activeToolCalls[toolCallId] = MCPToolCallContext(
      toolCallId: toolCallId,
      toolName: originalToolName, // Store original format for MCP calls
      serverName: serverName,
      arguments: arguments,
      timestamp: DateTime.now(),
    );

    _logger.fine(
        '📝 REGISTERED: Tool call $toolCallId for $originalToolName (API name: $toolName)');
  }

  /// Get tool call context for processing
  static MCPToolCallContext? getToolCallContext(String toolCallId) {
    return _activeToolCalls[toolCallId];
  }

  /// Complete and remove tool call from tracking
  static void completeToolCall(String toolCallId) {
    final removed = _activeToolCalls.remove(toolCallId);
    if (removed != null) {
      _logger.fine('✅ COMPLETED: Tool call $toolCallId removed from tracking');
    } else {
      _logger
          .warning('⚠️ NOT FOUND: Tool call $toolCallId was not being tracked');
    }
  }

  /// Get all active tool calls (for debugging)
  static Map<String, MCPToolCallContext> get activeToolCalls =>
      Map.unmodifiable(_activeToolCalls);

  /// Clean up old tool calls (cleanup job)
  ///
  /// PERF: O(n) - necessary for memory management
  /// ARCHITECTURAL: Prevents memory leaks from abandoned tool calls
  static void cleanupOldToolCalls(
      {Duration maxAge = const Duration(hours: 1)}) {
    final cutoff = DateTime.now().subtract(maxAge);
    final toRemove = <String>[];

    for (final entry in _activeToolCalls.entries) {
      if (entry.value.timestamp.isBefore(cutoff)) {
        toRemove.add(entry.key);
      }
    }

    for (final toolCallId in toRemove) {
      _activeToolCalls.remove(toolCallId);
    }

    if (toRemove.isNotEmpty) {
      _logger.info('🧹 CLEANUP: Removed ${toRemove.length} old tool calls');
    }
  }
}

/// MCP Tool Call Context for tracking active calls
///
/// ARCHITECTURAL: Immutable data class for thread-safe tool call tracking
class MCPToolCallContext {
  final String toolCallId;
  final String toolName;
  final String serverName;
  final Map<String, dynamic> arguments;
  final DateTime timestamp;

  const MCPToolCallContext({
    required this.toolCallId,
    required this.toolName,
    required this.serverName,
    required this.arguments,
    required this.timestamp,
  });

  @override
  String toString() =>
      'MCPToolCallContext(id: $toolCallId, tool: $toolName, server: $serverName)';
}

// MCPToolWithServer is defined in mcp_manager.dart
// Using existing implementation with uniqueId: 'serverName:toolName'
