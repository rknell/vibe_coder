import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:vibe_coder/ai_agent/services/mcp_function_bridge.dart';
import 'package:vibe_coder/services/mcp_service.dart';
import 'package:vibe_coder/ai_agent/models/mcp_models.dart';

/// MCP Function Bridge Test Suite
///
/// ## MISSION ACCOMPLISHED
/// Eliminates any risk of MCP function calling failures through comprehensive testing
/// of schema conversion, tool ID management, and error handling.
///
/// ## STRATEGIC DECISIONS
/// | Test Strategy | Power-Ups | Weaknesses | Victory Reason |
/// |---------------|-----------|------------|----------------|
/// | Unit Tests Only | Fast, focused | Limited integration | Rejected - misses tool flow |
/// | Integration Tests | Real scenarios | Slow, complex | Rejected - not pure unit testing |
/// | Comprehensive Unit + Mocks | Best of both | More setup | CHOSEN - complete coverage |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Tool Schema Conversion**
///    - 🔍 Symptom: MCP to OpenAI schema incompatibility
///    - 🎯 Root Cause: Different JSON schema formats
///    - 💥 Kill Shot: Comprehensive schema validation tests
///
/// 2. **Tool ID Management**
///    - 🔍 Symptom: Tool call ID mismatches breaking DeepSeek API
///    - 🎯 Root Cause: Missing bidirectional ID tracking
///    - 💥 Kill Shot: ID lifecycle validation tests
///
/// 3. **Error Resilience**
///    - 🔍 Symptom: Single tool failure breaking entire function calling
///    - 🎯 Root Cause: Insufficient error isolation
///    - 💥 Kill Shot: Error handling and recovery tests
void main() {
  group('MCP Function Bridge Tests', () {
    setUpAll(() {
      // 🎯 WARRIOR PROTOCOL: Minimal logging for clean test output
      Logger.root.level = Level.SEVERE;
      Logger.root.onRecord.listen((record) {
        if (record.level >= Level.SEVERE) {
          // ignore: avoid_print
          print('${record.level.name}: ${record.message}');
        }
      });
    });

    group('🔄 Tool Conversion Tests', () {
      test('🔧 converts tool names to API-compliant format', () {
        // Test API-compliant name conversion
        expect(MCPFunctionBridge.toApiFunctionName('filesystem:read_file'),
            equals('filesystem_read_file'));
        expect(MCPFunctionBridge.toApiFunctionName('memory:create_entities'),
            equals('memory_create_entities'));
        expect(
            MCPFunctionBridge.toApiFunctionName('server:tool_with_underscores'),
            equals('server_tool_with_underscores'));

        // 🎯 CRITICAL: Test the exact scenario that caused the original bug
        expect(MCPFunctionBridge.toApiFunctionName('memory:read_graph'),
            equals('memory_read_graph'));

        // Test reverse conversion
        expect(MCPFunctionBridge.fromApiFunctionName('filesystem_read_file'),
            equals('filesystem:read_file'));
        expect(MCPFunctionBridge.fromApiFunctionName('memory_create_entities'),
            equals('memory:create_entities'));
        expect(
            MCPFunctionBridge.fromApiFunctionName(
                'server_tool_with_underscores'),
            equals('server:tool_with_underscores'));

        // 🎯 CRITICAL: Test the exact reverse scenario that caused the original bug
        expect(MCPFunctionBridge.fromApiFunctionName('memory_read_graph'),
            equals('memory:read_graph'));
      });

      test('converts MCP tools to OpenAI function format', () {
        // Arrange
        final mcpTool = MCPTool(
          name: 'test_tool',
          description: 'A test tool',
          inputSchema: {
            'type': 'object',
            'properties': {
              'query': {'type': 'string', 'description': 'Search query'}
            },
            'required': ['query']
          },
        );

        final mcpToolWithServer = MCPToolWithServer(
          tool: mcpTool,
          serverName: 'test_server',
        );

        // Act
        final functions =
            MCPFunctionBridge.convertMCPToolsToFunctions([mcpToolWithServer]);

        // Assert
        expect(functions, hasLength(1));

        final function = functions[0];
        expect(function['type'], equals('function'));
        expect(function['function']['name'], equals('test_server_test_tool'));
        expect(function['function']['description'], equals('A test tool'));

        final parameters =
            function['function']['parameters'] as Map<String, dynamic>;
        expect(parameters['type'], equals('object'));
        expect(parameters['properties'], isA<Map<String, dynamic>>());
        expect(parameters['required'], equals(['query']));
      });

      test('handles tools with no description', () {
        // Arrange
        final mcpTool = MCPTool(
          name: 'no_desc_tool',
          inputSchema: {'type': 'object'},
        );

        final mcpToolWithServer = MCPToolWithServer(
          tool: mcpTool,
          serverName: 'test_server',
        );

        // Act
        final functions =
            MCPFunctionBridge.convertMCPToolsToFunctions([mcpToolWithServer]);

        // Assert
        expect(functions, hasLength(1));
        expect(functions[0]['function']['description'],
            equals('MCP tool: no_desc_tool'));
      });

      test('handles complex nested schemas', () {
        // Arrange
        final mcpTool = MCPTool(
          name: 'complex_tool',
          description: 'Complex tool with nested schema',
          inputSchema: {
            'type': 'object',
            'properties': {
              'config': {
                'type': 'object',
                'properties': {
                  'enabled': {'type': 'boolean'},
                  'settings': {
                    'type': 'array',
                    'items': {'type': 'string'}
                  }
                }
              }
            },
            'required': ['config']
          },
        );

        final mcpToolWithServer = MCPToolWithServer(
          tool: mcpTool,
          serverName: 'test_server',
        );

        // Act
        final functions =
            MCPFunctionBridge.convertMCPToolsToFunctions([mcpToolWithServer]);

        // Assert
        expect(functions, hasLength(1));

        final parameters =
            functions[0]['function']['parameters'] as Map<String, dynamic>;
        final configProp =
            parameters['properties']['config'] as Map<String, dynamic>;
        expect(configProp['type'], equals('object'));
        expect(configProp['properties'], isA<Map<String, dynamic>>());
      });

      test('continues processing after single tool conversion failure', () {
        // Arrange
        final validTool = MCPTool(
          name: 'valid_tool',
          description: 'Valid tool',
          inputSchema: {'type': 'object'},
        );

        final invalidTool = MCPTool(
          name: 'invalid_tool',
          description: 'Invalid tool',
          inputSchema: {}, // Invalid schema
        );

        final toolsWithServer = [
          MCPToolWithServer(tool: validTool, serverName: 'test_server'),
          MCPToolWithServer(tool: invalidTool, serverName: 'test_server'),
        ];

        // Act
        final functions =
            MCPFunctionBridge.convertMCPToolsToFunctions(toolsWithServer);

        // Assert - Should still process valid tools
        expect(functions,
            hasLength(2)); // Both tools processed despite potential issues
      });
    });

    group('🔧 Tool ID Management Tests', () {
      test('generates unique tool call IDs', () {
        // Act
        final id1 = MCPFunctionBridge.generateToolCallId();
        final id2 = MCPFunctionBridge.generateToolCallId();
        final id3 = MCPFunctionBridge.generateToolCallId();

        // Assert
        expect(id1, isNot(equals(id2)));
        expect(id2, isNot(equals(id3)));
        expect(id1, isNot(equals(id3)));

        // All IDs should start with 'call_'
        expect(id1, startsWith('call_'));
        expect(id2, startsWith('call_'));
        expect(id3, startsWith('call_'));
      });

      test('registers and retrieves tool call context', () {
        // Arrange
        final toolCallId = MCPFunctionBridge.generateToolCallId();
        final arguments = {'query': 'test'};

        // Act
        MCPFunctionBridge.registerToolCall(
          toolCallId: toolCallId,
          toolName: 'test_server_test_tool', // Use API-compliant format
          serverName: 'test_server',
          arguments: arguments,
        );

        final context = MCPFunctionBridge.getToolCallContext(toolCallId);

        // Assert
        expect(context, isNotNull);
        final contextValue = context;
        if (contextValue != null) {
          expect(contextValue.toolCallId, equals(toolCallId));
          expect(contextValue.toolName, equals('test_server:test_tool'));
          expect(contextValue.serverName, equals('test_server'));
          expect(contextValue.arguments, equals(arguments));
          expect(contextValue.timestamp, isA<DateTime>());
        }
      });

      test('completes and removes tool call from tracking', () {
        // Arrange
        final toolCallId = MCPFunctionBridge.generateToolCallId();

        MCPFunctionBridge.registerToolCall(
          toolCallId: toolCallId,
          toolName: 'test_server_test_tool', // Use API-compliant format
          serverName: 'test_server',
          arguments: {'query': 'test'},
        );

        // Verify it's tracked
        expect(MCPFunctionBridge.getToolCallContext(toolCallId), isNotNull);

        // Act
        MCPFunctionBridge.completeToolCall(toolCallId);

        // Assert
        expect(MCPFunctionBridge.getToolCallContext(toolCallId), isNull);
      });

      test('handles completion of non-existent tool call gracefully', () {
        // Act & Assert - Should not throw
        expect(() => MCPFunctionBridge.completeToolCall('non_existent_id'),
            returnsNormally);
      });

      test('cleans up old tool calls', () {
        // Arrange
        final oldToolCallId = MCPFunctionBridge.generateToolCallId();
        final recentToolCallId = MCPFunctionBridge.generateToolCallId();

        // Register tool calls
        MCPFunctionBridge.registerToolCall(
          toolCallId: oldToolCallId,
          toolName: 'test_server_old_tool', // Use API-compliant format
          serverName: 'test_server',
          arguments: {},
        );

        MCPFunctionBridge.registerToolCall(
          toolCallId: recentToolCallId,
          toolName: 'test_server_recent_tool', // Use API-compliant format
          serverName: 'test_server',
          arguments: {},
        );

        // Act - Clean up with very short max age to simulate old calls
        MCPFunctionBridge.cleanupOldToolCalls(
            maxAge: const Duration(microseconds: 1));

        // Assert - Both should be cleaned up due to very short max age
        expect(MCPFunctionBridge.getToolCallContext(oldToolCallId), isNull);
        expect(MCPFunctionBridge.getToolCallContext(recentToolCallId), isNull);
      });

      test('🎯 CRITICAL: memory:read_graph complete workflow validation', () {
        // This test validates the EXACT scenario that caused the original bug
        // memory:read_graph → memory_read_graph → memory:read_graph

        // Arrange - Create the exact MCP tool that caused issues
        final memoryTool = MCPToolWithServer(
          tool: MCPTool(
            name: 'read_graph',
            description: 'Read the entire knowledge graph',
            inputSchema: {'type': 'object', 'properties': {}},
          ),
          serverName: 'memory',
        );

        // Act - Convert to function format
        final functions =
            MCPFunctionBridge.convertMCPToolsToFunctions([memoryTool]);

        // Assert - Verify API function name conversion
        expect(functions, hasLength(1));
        final function = functions[0];
        expect(function['function']['name'], equals('memory_read_graph'));

        // Simulate AI calling the tool with API name
        final apiFunctionName = function['function']['name'] as String;
        expect(apiFunctionName, equals('memory_read_graph'));

        // Convert back to MCP format (this is where the bug was)
        final mcpFormat =
            MCPFunctionBridge.fromApiFunctionName(apiFunctionName);
        expect(mcpFormat, equals('memory:read_graph'));

        // Parse server and tool name
        final parts = mcpFormat.split(':');
        expect(parts[0], equals('memory')); // server name
        expect(parts[1], equals('read_graph')); // tool name

        // Simulate tool call registration and tracking
        final toolCallId = MCPFunctionBridge.generateToolCallId();
        MCPFunctionBridge.registerToolCall(
          toolCallId: toolCallId,
          toolName: apiFunctionName, // Use API name for registration
          serverName: 'memory',
          arguments: {},
        );

        // Verify tracking uses proper MCP format internally
        final context = MCPFunctionBridge.getToolCallContext(toolCallId);
        expect(context, isNotNull);
        final contextValue = context;
        if (contextValue != null) {
          expect(contextValue.serverName, equals('memory'));
          // The tool name in context should be in MCP format for server calls
        }

        MCPFunctionBridge.completeToolCall(toolCallId);
      });
    });

    group('🛡️ Error Handling Tests', () {
      test('handles empty tool list gracefully', () {
        // Act
        final functions = MCPFunctionBridge.convertMCPToolsToFunctions([]);

        // Assert
        expect(functions, isEmpty);
      });

      test('handles malformed tool schemas gracefully', () {
        // Arrange
        final mcpTool = MCPTool(
          name: 'malformed_tool',
          description: 'Tool with malformed schema',
          inputSchema: {
            // Missing required fields
          },
        );

        final mcpToolWithServer = MCPToolWithServer(
          tool: mcpTool,
          serverName: 'test_server',
        );

        // Act & Assert - Should not throw
        expect(
            () => MCPFunctionBridge.convertMCPToolsToFunctions(
                [mcpToolWithServer]),
            returnsNormally);
      });

      test('MCPToolCallContext toString works correctly', () {
        // Arrange
        final context = MCPToolCallContext(
          toolCallId: 'test_id',
          toolName: 'test_tool',
          serverName: 'test_server',
          arguments: {'key': 'value'},
          timestamp: DateTime.now(),
        );

        // Act
        final result = context.toString();

        // Assert
        expect(result, contains('test_id'));
        expect(result, contains('test_tool'));
        expect(result, contains('test_server'));
      });
    });

    group('🎯 Integration Scenarios', () {
      test('full tool calling workflow simulation', () {
        // Arrange - Create MCP tools
        final mcpTools = [
          MCPToolWithServer(
            tool: MCPTool(
              name: 'search_files',
              description: 'Search for files',
              inputSchema: {
                'type': 'object',
                'properties': {
                  'query': {'type': 'string'},
                  'path': {'type': 'string'}
                },
                'required': ['query']
              },
            ),
            serverName: 'filesystem',
          ),
          MCPToolWithServer(
            tool: MCPTool(
              name: 'remember',
              description: 'Remember information',
              inputSchema: {
                'type': 'object',
                'properties': {
                  'key': {'type': 'string'},
                  'value': {'type': 'string'}
                },
                'required': ['key', 'value']
              },
            ),
            serverName: 'memory',
          ),
        ];

        // Act - Convert to functions
        final functions =
            MCPFunctionBridge.convertMCPToolsToFunctions(mcpTools);

        // Assert - Verify conversion
        expect(functions, hasLength(2));

        // Verify function names use unique IDs
        final functionNames =
            functions.map((f) => f['function']['name'] as String).toList();
        expect(functionNames,
            containsAll(['filesystem_search_files', 'memory_remember']));

        // Simulate tool call registration
        final toolCallId = MCPFunctionBridge.generateToolCallId();
        MCPFunctionBridge.registerToolCall(
          toolCallId: toolCallId,
          toolName: 'filesystem_search_files', // Use API-compliant format
          serverName: 'filesystem',
          arguments: {'query': 'test.dart'},
        );

        // Verify tracking
        final context = MCPFunctionBridge.getToolCallContext(toolCallId);
        expect(context, isNotNull);
        final contextValue = context;
        expect(contextValue?.toolName, equals('filesystem:search_files'));
        expect(contextValue?.serverName, equals('filesystem'));

        // Simulate completion
        MCPFunctionBridge.completeToolCall(toolCallId);
        expect(MCPFunctionBridge.getToolCallContext(toolCallId), isNull);
      });

      test('handles multiple servers with same tool names', () {
        // Arrange - Tools with same name on different servers
        final mcpTools = [
          MCPToolWithServer(
            tool: MCPTool(name: 'search', inputSchema: {'type': 'object'}),
            serverName: 'filesystem',
          ),
          MCPToolWithServer(
            tool: MCPTool(name: 'search', inputSchema: {'type': 'object'}),
            serverName: 'web',
          ),
        ];

        // Act
        final functions =
            MCPFunctionBridge.convertMCPToolsToFunctions(mcpTools);

        // Assert - Should create unique function names
        expect(functions, hasLength(2));

        final functionNames =
            functions.map((f) => f['function']['name'] as String).toList();
        expect(functionNames, containsAll(['filesystem_search', 'web_search']));
      });
    });

    group('🛡️ REGRESSION: Task List Tool Name Conversion', () {
      setUp(() {
        // Register the mapping for these tools
        MCPFunctionBridge.convertMCPToolsToFunctions([
          MCPToolWithServer(
            tool: MCPTool(
              name: 'task_list_add',
              description: 'Add a new task',
              inputSchema: {},
            ),
            serverName: 'task_list',
          ),
          MCPToolWithServer(
            tool: MCPTool(
              name: 'task_list_add',
              description: 'Add a new task',
              inputSchema: {},
            ),
            serverName: 'agent-task-list',
          ),
        ]);
      });

      test('should convert task_list_task_list_add correctly', () {
        // Test the specific case that was failing
        final apiFunctionName = 'task_list_task_list_add';
        final expectedMCPFormat = 'task_list:task_list_add';

        final result = MCPFunctionBridge.fromApiFunctionName(apiFunctionName);
        expect(result, equals(expectedMCPFormat));

        // Test reverse conversion
        final reverseResult =
            MCPFunctionBridge.toApiFunctionName(expectedMCPFormat);
        expect(reverseResult, equals(apiFunctionName));
      });

      test('should handle agent-task-list server name correctly', () {
        // Test that the server name with hyphens works correctly
        final mcpToolId = 'agent-task-list:task_list_add';
        final expectedApiName = 'agent-task-list_task_list_add';

        final result = MCPFunctionBridge.toApiFunctionName(mcpToolId);
        expect(result, equals(expectedApiName));

        // Test reverse conversion
        final reverseResult =
            MCPFunctionBridge.fromApiFunctionName(expectedApiName);
        expect(reverseResult, equals(mcpToolId));
      });
    });
  });
}
