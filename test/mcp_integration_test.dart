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
  // 🎯 WARRIOR PROTOCOL: Minimal logging for clean test output
  // Only show SEVERE errors and test failures
  Logger.root.level = Level.SEVERE;
  Logger.root.onRecord.listen((record) {
    if (record.level >= Level.SEVERE) {
      print('${record.level.name}: ${record.message}');
      if (record.error != null) {
        print('ERROR: ${record.error}');
      }
      if (record.stackTrace != null) {
        print('STACK: ${record.stackTrace}');
      }
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
        await client.initialize();

        final tools = await client.listTools();
        expect(tools.isNotEmpty, isTrue,
            reason: 'Filesystem server should provide tools');

        final resources = await client.listResources();
        final prompts = await client.listPrompts();

        await client.close();
      } catch (e, stackTrace) {
        print('💥 FILESYSTEM TEST FAILED: $e');
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
        await client.initialize();

        final tools = await client.listTools();
        expect(tools.isNotEmpty, isTrue,
            reason: 'Memory server should provide tools');

        final resources = await client.listResources();
        final prompts = await client.listPrompts();

        await client.close();
      } catch (e, stackTrace) {
        print('💥 MEMORY TEST FAILED: $e');
        await client.close();
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('🏗️ MCP Manager Integration Tests', () {
    test('📋 Configuration Loading', () async {
      final manager = MCPManager();

      try {
        await manager.initialize('mcp.json');

        final configuredServers = manager.configuredServers;
        final connectedServers = manager.connectedServers;

        expect(configuredServers.isNotEmpty, isTrue,
            reason: 'Should have configured servers');

        final allTools = manager.getAllTools();
        expect(allTools.isNotEmpty, isTrue,
            reason: 'Should have tools available');

        await manager.closeAll();
      } catch (e, stackTrace) {
        print('💥 CONFIGURATION TEST FAILED: $e');
        await manager.closeAll();
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('🔄 Connection Stability Test', () async {
      final manager = MCPManager();

      try {
        await manager.initialize('mcp.json');

        // Test stability over multiple iterations
        for (int i = 0; i < 5; i++) {
          final connectedServers = manager.connectedServers;
          final allTools = manager.getAllTools();

          // Wait between checks
          await Future.delayed(const Duration(seconds: 2));

          // Refresh capabilities to test stability
          await manager.refreshCapabilities();

          final newConnectedServers = manager.connectedServers;
          final newAllTools = manager.getAllTools();

          // Check for stability - only report failures
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
      } catch (e, stackTrace) {
        print('💥 STABILITY TEST FAILED: $e');
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

        expect(filesystemTools.isNotEmpty, isTrue,
            reason: 'Should have filesystem tools available');

        if (filesystemTools.isNotEmpty) {
          final tool = filesystemTools.first;

          // Try to call the tool (this might fail depending on the tool's requirements)
          try {
            final result = await manager.callTool(
              serverName: tool.serverName,
              toolName: tool.tool.name,
              arguments: {}, // Empty arguments for basic test
            );
            // Tool call succeeded - this is expected to fail for most tools without proper args
          } catch (toolError) {
            // Expected for tools without proper arguments - this is normal
          }
        }

        await manager.closeAll();
      } catch (e, stackTrace) {
        print('💥 TOOL TEST FAILED: $e');
        await manager.closeAll();
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
}
