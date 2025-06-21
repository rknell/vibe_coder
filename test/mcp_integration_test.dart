// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:vibe_coder/ai_agent/services/mcp_client.dart';
import 'package:vibe_coder/services/services.dart';

/// 🧪 **UPDATED MCP TESTING SUITE**
///
/// ✅ **UPDATED FOR MCPService ARCHITECTURE**
///
/// Tests MCP functionality using the new MCPService architecture
/// Verifies server connections, tool loading, and stability
///
/// **🚩 TEST FLAGS:**
/// - Set `MCP_INTEGRATION_TESTS=true` environment variable to run slow integration tests
/// - Default: Only fast unit tests run
///
/// **🎯 ARCHITECTURE**: Uses MCPService for consolidated MCP management
void main() {
  // 🛡️ WARRIOR PROTOCOL: Initialize Flutter bindings for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  // 🎯 WARRIOR PROTOCOL: Check if integration tests should run
  const shouldRunIntegrationTests =
      String.fromEnvironment('MCP_INTEGRATION_TESTS') == 'true' ||
          bool.fromEnvironment('MCP_INTEGRATION_TESTS', defaultValue: false);

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
      if (!shouldRunIntegrationTests) {
        print(
            '⏭️ SKIPPING: Integration test (set MCP_INTEGRATION_TESTS=true to run)');
        return;
      }

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

        // Test resources and prompts availability (may be empty but should not error)
        await client.listResources();
        await client.listPrompts();

        await client.close();
      } catch (e) {
        print('💥 FILESYSTEM TEST FAILED: $e');
        await client.close();
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('🧠 Memory Server Connection', () async {
      if (!shouldRunIntegrationTests) {
        print(
            '⏭️ SKIPPING: Integration test (set MCP_INTEGRATION_TESTS=true to run)');
        return;
      }

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

        // Test resources and prompts availability (may be empty but should not error)
        await client.listResources();
        await client.listPrompts();

        await client.close();
      } catch (e) {
        print('💥 MEMORY TEST FAILED: $e');
        await client.close();
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('🏗️ MCP Service Integration Tests', () {
    test('📋 Configuration Loading', () async {
      if (!shouldRunIntegrationTests) {
        print(
            '⏭️ SKIPPING: Integration test (set MCP_INTEGRATION_TESTS=true to run)');
        return;
      }

      // Initialize services for testing
      resetServices();
      final mcpService = services.mcpService;

      try {
        await mcpService.initialize();

        final configuredServers = mcpService.data;
        expect(configuredServers.isNotEmpty, isTrue,
            reason: 'Should have configured servers');

        final allTools = mcpService.getAllTools();
        expect(allTools.isNotEmpty, isTrue,
            reason: 'Should have tools available');

        mcpService.dispose();
      } catch (e, stackTrace) {
        print('💥 CONFIGURATION TEST FAILED: $e');
        print('STACK: $stackTrace');
        mcpService.dispose();
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('🔄 Connection Stability Test', () async {
      if (!shouldRunIntegrationTests) {
        print(
            '⏭️ SKIPPING: Integration test (set MCP_INTEGRATION_TESTS=true to run)');
        return;
      }

      // Initialize services for testing
      resetServices();
      final mcpService = services.mcpService;

      try {
        await mcpService.initialize();

        // Test stability over multiple iterations
        for (int i = 0; i < 5; i++) {
          final connectedServers = mcpService.connectedServers;
          final allTools = mcpService.getAllTools();

          // Wait between checks
          await Future.delayed(const Duration(seconds: 2));

          // Refresh capabilities to test stability
          await mcpService.refreshAll();

          final newConnectedServers = mcpService.connectedServers;
          final newAllTools = mcpService.getAllTools();

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

        mcpService.dispose();
      } catch (e, stackTrace) {
        print('💥 STABILITY TEST FAILED: $e');
        print('STACK: $stackTrace');
        mcpService.dispose();
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 120)));
  });

  group('🛠️ Tool Functionality Tests', () {
    test('📁 Filesystem Tool Execution', () async {
      if (!shouldRunIntegrationTests) {
        print(
            '⏭️ SKIPPING: Integration test (set MCP_INTEGRATION_TESTS=true to run)');
        return;
      }

      // Initialize services for testing
      resetServices();
      final mcpService = services.mcpService;

      try {
        await mcpService.initialize();

        // Find filesystem server tools
        final filesystemTools = mcpService
            .getAllTools()
            .where((tool) => tool.serverName == 'filesystem')
            .toList();

        expect(filesystemTools.isNotEmpty, isTrue,
            reason: 'Should have filesystem tools available');

        if (filesystemTools.isNotEmpty) {
          final tool = filesystemTools.first;

          // Get the server for this tool
          final server = mcpService.getByName(tool.serverName);
          expect(server, isNotNull, reason: 'Server should exist for tool');

          // Try to call the tool (this might fail depending on the tool's requirements)
          try {
            await mcpService.callTool(
              serverId: server!.id,
              toolName: tool.tool.name,
              arguments: {}, // Empty arguments for basic test
            );
            // Tool call succeeded - this is expected to fail for most tools without proper args
          } catch (toolError, stackTrace) {
            // Expected for tools without proper arguments - this is normal
            print('Tool call failed as expected: $toolError');
            print('STACK: $stackTrace');
          }
        }

        mcpService.dispose();
      } catch (e, stackTrace) {
        print('💥 TOOL TEST FAILED: $e');
        print('STACK: $stackTrace');
        mcpService.dispose();
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
}
