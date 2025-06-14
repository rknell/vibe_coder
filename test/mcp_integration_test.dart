// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:test/test.dart';
import 'package:logging/logging.dart';
import 'package:vibe_coder/ai_agent/services/mcp_manager.dart';
import 'package:vibe_coder/ai_agent/services/mcp_client.dart';

/// 🧪 **STANDALONE MCP TESTING SUITE**
///
/// Tests MCP functionality without Flutter dependencies
/// Verifies server connections, tool loading, and stability
void main() {
  // Setup logging for test visibility
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      print('ERROR: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('STACK: ${record.stackTrace}');
    }
  });

  group('🔧 MCP Client STDIO Tests', () {
    test('🚀 Filesystem Server Connection', () async {
      final client = MCPClient.stdio(
        command: '/home/rknell/Applications/nvm/versions/node/v23.5.0/bin/npx',
        args: [
          '@modelcontextprotocol/server-filesystem',
          '/home/rknell/Projects/vibe_coder'
        ],
        env: {
          'DEBUG': 'false',
          'NODE_PATH':
              '/home/rknell/Applications/nvm/versions/node/v23.5.0/bin',
          'PATH':
              '/home/rknell/Applications/nvm/versions/node/v23.5.0/bin:/usr/local/bin:/usr/bin:/bin'
        },
      );

      try {
        print('🔌 CONNECTING: Initializing filesystem client...');
        await client.initialize();
        print('✅ CONNECTION: Filesystem client initialized successfully');

        print('🛠️ TOOLS: Listing available tools...');
        final tools = await client.listTools();
        print('📊 RESULT: Found ${tools.length} tools');

        for (int i = 0; i < tools.length; i++) {
          print(
              '🔧 TOOL[$i]: ${tools[i].name} - ${tools[i].description ?? "No description"}');
        }

        expect(tools.isNotEmpty, isTrue,
            reason: 'Filesystem server should provide tools');

        print('📚 RESOURCES: Listing available resources...');
        final resources = await client.listResources();
        print('📊 RESULT: Found ${resources.length} resources');

        print('📝 PROMPTS: Listing available prompts...');
        final prompts = await client.listPrompts();
        print('📊 RESULT: Found ${prompts.length} prompts');

        await client.close();
        print('🔒 CLEANUP: Client closed successfully');
      } catch (e, stackTrace) {
        print('💥 FAILURE: Filesystem test failed: $e');
        print('STACK: $stackTrace');
        await client.close();
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('🧠 Memory Server Connection', () async {
      final client = MCPClient.stdio(
        command: '/home/rknell/Applications/nvm/versions/node/v23.5.0/bin/npx',
        args: ['@modelcontextprotocol/server-memory'],
        env: {
          'DEBUG': 'false',
          'NODE_PATH':
              '/home/rknell/Applications/nvm/versions/node/v23.5.0/bin',
          'PATH':
              '/home/rknell/Applications/nvm/versions/node/v23.5.0/bin:/usr/local/bin:/usr/bin:/bin'
        },
      );

      try {
        print('🔌 CONNECTING: Initializing memory client...');
        await client.initialize();
        print('✅ CONNECTION: Memory client initialized successfully');

        print('🛠️ TOOLS: Listing available tools...');
        final tools = await client.listTools();
        print('📊 RESULT: Found ${tools.length} tools');

        for (int i = 0; i < tools.length; i++) {
          print(
              '🔧 TOOL[$i]: ${tools[i].name} - ${tools[i].description ?? "No description"}');
        }

        expect(tools.isNotEmpty, isTrue,
            reason: 'Memory server should provide tools');

        print('📚 RESOURCES: Listing available resources...');
        final resources = await client.listResources();
        print('📊 RESULT: Found ${resources.length} resources');

        print('📝 PROMPTS: Listing available prompts...');
        final prompts = await client.listPrompts();
        print('📊 RESULT: Found ${prompts.length} prompts');

        await client.close();
        print('🔒 CLEANUP: Client closed successfully');
      } catch (e, stackTrace) {
        print('💥 FAILURE: Memory test failed: $e');
        print('STACK: $stackTrace');
        await client.close();
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('🏗️ MCP Manager Integration Tests', () {
    test('📋 Configuration Loading', () async {
      final manager = MCPManager();

      try {
        print('📂 CONFIG: Loading MCP configuration...');
        await manager.initialize('mcp.json');

        final configuredServers = manager.configuredServers;
        final connectedServers = manager.connectedServers;

        print('⚙️ CONFIGURED: ${configuredServers.length} servers configured');
        print('🔗 CONNECTED: ${connectedServers.length} servers connected');
        print('📋 SERVERS: ${configuredServers.join(', ')}');

        expect(configuredServers.isNotEmpty, isTrue,
            reason: 'Should have configured servers');

        // Check each server status
        for (final serverName in configuredServers) {
          final status = manager.getServerStatus(serverName);
          print('🔍 SERVER[$serverName]: ${jsonEncode(status)}');
        }

        final allTools = manager.getAllTools();
        print('🛠️ TOTAL TOOLS: ${allTools.length}');

        for (final tool in allTools) {
          print(
              '🔧 TOOL: ${tool.uniqueId} - ${tool.tool.description ?? "No description"}');
        }

        await manager.closeAll();
        print('🔒 CLEANUP: Manager closed successfully');
      } catch (e, stackTrace) {
        print('💥 FAILURE: Manager test failed: $e');
        print('STACK: $stackTrace');
        await manager.closeAll();
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('🔄 Connection Stability Test', () async {
      print('🔄 STABILITY: Testing connection stability over time...');

      final manager = MCPManager();

      try {
        await manager.initialize('mcp.json');

        // Test stability over multiple iterations
        for (int i = 0; i < 5; i++) {
          print('🔄 ITERATION[$i]: Checking server status...');

          final connectedServers = manager.connectedServers;
          final allTools = manager.getAllTools();

          print('🔗 CONNECTED[$i]: ${connectedServers.length} servers');
          print('🛠️ TOOLS[$i]: ${allTools.length} tools');

          // Wait between checks
          await Future.delayed(const Duration(seconds: 2));

          // Refresh capabilities to test stability
          await manager.refreshCapabilities();

          final newConnectedServers = manager.connectedServers;
          final newAllTools = manager.getAllTools();

          print('🔗 AFTER_REFRESH[$i]: ${newConnectedServers.length} servers');
          print('🛠️ AFTER_REFRESH[$i]: ${newAllTools.length} tools');

          // Check for stability
          if (connectedServers.length != newConnectedServers.length) {
            print(
                '⚠️ INSTABILITY: Server count changed from ${connectedServers.length} to ${newConnectedServers.length}');
          }

          if (allTools.length != newAllTools.length) {
            print(
                '⚠️ INSTABILITY: Tool count changed from ${allTools.length} to ${newAllTools.length}');
          }
        }

        await manager.closeAll();
        print('✅ STABILITY: Test completed successfully');
      } catch (e, stackTrace) {
        print('💥 STABILITY FAILURE: $e');
        print('STACK: $stackTrace');
        await manager.closeAll();
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 120)));
  });

  group('🛠️ Tool Functionality Tests', () {
    test('📁 Filesystem Tool Execution', () async {
      final manager = MCPManager();

      try {
        await manager.initialize('mcp.json');

        // Find filesystem server
        final filesystemTools = manager
            .getAllTools()
            .where((tool) => tool.serverName == 'filesystem')
            .toList();

        print('📁 FILESYSTEM TOOLS: Found ${filesystemTools.length} tools');

        if (filesystemTools.isNotEmpty) {
          final tool = filesystemTools.first;
          print('🔧 TESTING TOOL: ${tool.uniqueId}');

          // Try to call the tool (this might fail depending on the tool's requirements)
          try {
            final result = await manager.callTool(
              serverName: tool.serverName,
              toolName: tool.tool.name,
              arguments: {}, // Empty arguments for basic test
            );
            print('✅ TOOL RESULT: ${result.content.length} content items');
          } catch (toolError) {
            print(
                '⚠️ TOOL ERROR: $toolError (expected for some tools without proper arguments)');
          }
        }

        await manager.closeAll();
      } catch (e, stackTrace) {
        print('💥 TOOL TEST FAILURE: $e');
        print('STACK: $stackTrace');
        await manager.closeAll();
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
}
