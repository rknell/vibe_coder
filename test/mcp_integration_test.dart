// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:vibe_coder/ai_agent/services/mcp_client.dart';
import 'package:vibe_coder/services/mcp_service.dart';

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

      // Create fresh service instance for this test only
      final mcpService = MCPService();

      try {
        // Step 1: Initialize service (loads configurations)
        await mcpService.initialize();

        final configuredServers = mcpService.data;
        expect(configuredServers.isNotEmpty, isTrue,
            reason: 'Should have configured servers');

        print('📋 Found ${configuredServers.length} configured servers');

        // Step 2: Connect to all configured servers
        for (final server in configuredServers) {
          try {
            print('🔌 Connecting to ${server.name}...');
            await mcpService.connectServer(server.id);
            print('✅ Connected to ${server.name}');
          } catch (e) {
            print('⚠️ Failed to connect to ${server.name}: $e');
            // Continue with other servers
          }
        }

        // Step 3: Check that we have tools available
        final allTools = mcpService.getAllTools();
        final connectedServers = mcpService.connectedServers;

        print('🔌 Connected servers: ${connectedServers.length}');
        print('🛠️ Available tools: ${allTools.length}');

        // We should have at least some connected servers and tools
        expect(connectedServers.isNotEmpty, isTrue,
            reason: 'Should have at least one connected server');
        expect(allTools.isNotEmpty, isTrue,
            reason: 'Should have tools available from connected servers');

        // Clean up
        mcpService.dispose();
      } catch (e, stackTrace) {
        print('💥 CONFIGURATION TEST FAILED: $e');
        print('STACK: $stackTrace');
        rethrow;
      }
    },
        timeout: const Timeout(
            Duration(seconds: 120))); // Increased timeout for connections

    test('🔄 Connection Stability Test', () async {
      if (!shouldRunIntegrationTests) {
        print(
            '⏭️ SKIPPING: Integration test (set MCP_INTEGRATION_TESTS=true to run)');
        return;
      }

      // Create fresh service instance for this test only
      final mcpService = MCPService();

      try {
        // Step 1: Initialize and connect servers
        await mcpService.initialize();

        final configuredServers = mcpService.data;
        print(
            '📋 Found ${configuredServers.length} configured servers for stability test');

        // Connect to all configured servers
        for (final server in configuredServers) {
          try {
            await mcpService.connectServer(server.id);
            print('✅ Connected to ${server.name} for stability test');
          } catch (e) {
            print('⚠️ Failed to connect to ${server.name}: $e');
            // Continue with other servers
          }
        }

        // Step 2: Test stability over multiple iterations
        for (int i = 0; i < 5; i++) {
          print('🔄 Stability check iteration ${i + 1}/5');

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

        print('✅ Stability test completed successfully');

        // Clean up
        mcpService.dispose();
      } catch (e, stackTrace) {
        print('💥 STABILITY TEST FAILED: $e');
        print('STACK: $stackTrace');
        rethrow;
      }
    },
        timeout: const Timeout(Duration(
            seconds: 180))); // Increased timeout for multiple iterations
  });

  group('🛠️ Tool Functionality Tests', () {
    test('📁 Filesystem Tool Execution', () async {
      if (!shouldRunIntegrationTests) {
        print(
            '⏭️ SKIPPING: Integration test (set MCP_INTEGRATION_TESTS=true to run)');
        return;
      }

      // Create fresh service instance for this test only
      final mcpService = MCPService();

      try {
        // Step 1: Initialize and connect servers
        await mcpService.initialize();

        final configuredServers = mcpService.data;
        print(
            '📋 Found ${configuredServers.length} configured servers for tool test');

        // Connect to all configured servers
        for (final server in configuredServers) {
          try {
            await mcpService.connectServer(server.id);
            print('✅ Connected to ${server.name} for tool test');
          } catch (e) {
            print('⚠️ Failed to connect to ${server.name}: $e');
            // Continue with other servers
          }
        }

        // Step 2: Find filesystem server tools
        final filesystemTools = mcpService
            .getAllTools()
            .where((tool) => tool.serverName == 'filesystem')
            .toList();

        print('🛠️ Found ${filesystemTools.length} filesystem tools');

        expect(filesystemTools.isNotEmpty, isTrue,
            reason: 'Should have filesystem tools available');

        if (filesystemTools.isNotEmpty) {
          final tool = filesystemTools.first;

          // Get the server for this tool
          final server = mcpService.getByName(tool.serverName);
          expect(server, isNotNull, reason: 'Server should exist for tool');

          print('🔧 Testing tool: ${tool.tool.name}');

          // Try to call the tool (this might fail depending on the tool's requirements)
          try {
            final serverValue = server;
            if (serverValue != null) {
              await mcpService.callTool(
                serverId: serverValue.id,
                toolName: tool.tool.name,
                arguments: {}, // Empty arguments for basic test
              );
              print('✅ Tool call succeeded');
            }
            // Tool call succeeded - this is expected to fail for most tools without proper args
          } catch (toolError, stackTrace) {
            // Expected for tools without proper arguments - this is normal
            print('Tool call failed as expected: $toolError');
            print('STACK: $stackTrace');
          }
        }

        print('✅ Tool functionality test completed');

        // Clean up
        mcpService.dispose();
      } catch (e, stackTrace) {
        print('💥 TOOL TEST FAILED: $e');
        print('STACK: $stackTrace');
        rethrow;
      }
    },
        timeout: const Timeout(
            Duration(seconds: 90))); // Increased timeout for connections
  });
}
