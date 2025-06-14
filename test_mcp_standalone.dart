#!/usr/bin/env dart

// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'lib/ai_agent/services/mcp_manager.dart';
import 'lib/ai_agent/services/mcp_client.dart';

/// 🧪 **STANDALONE MCP TESTING SCRIPT**
///
/// Tests MCP functionality without Flutter dependencies
/// Run with: dart test_mcp_standalone.dart
void main() async {
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

  print('🚀 **STARTING MCP STANDALONE TESTS**');
  print('=' * 60);

  // Test 1: Individual Server Connections
  await testFilesystemServer();
  await testMemoryServer();

  // Test 2: Manager Integration
  await testMCPManager();

  // Test 3: Stability Test
  await testConnectionStability();

  print('=' * 60);
  print('✅ **ALL TESTS COMPLETED**');
}

/// Test filesystem server connection
Future<void> testFilesystemServer() async {
  print('\n🔧 **TEST 1: FILESYSTEM SERVER**');
  print('-' * 40);

  final client = MCPClient.stdio(
    command: '/home/rknell/Applications/nvm/versions/node/v23.5.0/bin/npx',
    args: [
      '@modelcontextprotocol/server-filesystem',
      '/home/rknell/Projects/vibe_coder'
    ],
    env: {
      'DEBUG': 'false',
      'NODE_PATH': '/home/rknell/Applications/nvm/versions/node/v23.5.0/bin',
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

    if (tools.isEmpty) {
      print('❌ FAILURE: Filesystem server should provide tools');
      exit(1);
    }

    print('📚 RESOURCES: Listing available resources...');
    try {
      final resources = await client.listResources();
      print('📊 RESULT: Found ${resources.length} resources');
    } catch (e) {
      print('ℹ️ RESOURCES: Not supported by this server');
    }

    print('📝 PROMPTS: Listing available prompts...');
    try {
      final prompts = await client.listPrompts();
      print('📊 RESULT: Found ${prompts.length} prompts');
    } catch (e) {
      print('ℹ️ PROMPTS: Not supported by this server');
    }

    await client.close();
    print('🔒 CLEANUP: Client closed successfully');
    print('✅ FILESYSTEM TEST: PASSED');
  } catch (e, stackTrace) {
    print('💥 FAILURE: Filesystem test failed: $e');
    print('STACK: $stackTrace');
    await client.close();
    exit(1);
  }
}

/// Test memory server connection
Future<void> testMemoryServer() async {
  print('\n🧠 **TEST 2: MEMORY SERVER**');
  print('-' * 40);

  final client = MCPClient.stdio(
    command: '/home/rknell/Applications/nvm/versions/node/v23.5.0/bin/npx',
    args: ['@modelcontextprotocol/server-memory'],
    env: {
      'DEBUG': 'false',
      'NODE_PATH': '/home/rknell/Applications/nvm/versions/node/v23.5.0/bin',
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

    if (tools.isEmpty) {
      print('❌ FAILURE: Memory server should provide tools');
      exit(1);
    }

    print('📚 RESOURCES: Listing available resources...');
    try {
      final resources = await client.listResources();
      print('📊 RESULT: Found ${resources.length} resources');
    } catch (e) {
      print('ℹ️ RESOURCES: Not supported by this server');
    }

    print('📝 PROMPTS: Listing available prompts...');
    try {
      final prompts = await client.listPrompts();
      print('📊 RESULT: Found ${prompts.length} prompts');
    } catch (e) {
      print('ℹ️ PROMPTS: Not supported by this server');
    }

    await client.close();
    print('🔒 CLEANUP: Client closed successfully');
    print('✅ MEMORY TEST: PASSED');
  } catch (e, stackTrace) {
    print('💥 FAILURE: Memory test failed: $e');
    print('STACK: $stackTrace');
    await client.close();
    exit(1);
  }
}

/// Test MCP Manager integration
Future<void> testMCPManager() async {
  print('\n🏗️ **TEST 3: MCP MANAGER INTEGRATION**');
  print('-' * 40);

  final manager = MCPManager();

  try {
    print('📂 CONFIG: Loading MCP configuration...');
    await manager.initialize('mcp.json');

    final configuredServers = manager.configuredServers;
    final connectedServers = manager.connectedServers;

    print('⚙️ CONFIGURED: ${configuredServers.length} servers configured');
    print('🔗 CONNECTED: ${connectedServers.length} servers connected');
    print('📋 SERVERS: ${configuredServers.join(', ')}');

    if (configuredServers.isEmpty) {
      print('❌ FAILURE: Should have configured servers');
      exit(1);
    }

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

    if (allTools.isEmpty) {
      print('⚠️ WARNING: No tools found - this might indicate a problem');
    }

    await manager.closeAll();
    print('🔒 CLEANUP: Manager closed successfully');
    print('✅ MANAGER TEST: PASSED');
  } catch (e, stackTrace) {
    print('💥 FAILURE: Manager test failed: $e');
    print('STACK: $stackTrace');
    await manager.closeAll();
    exit(1);
  }
}

/// Test connection stability over time
Future<void> testConnectionStability() async {
  print('\n🔄 **TEST 4: CONNECTION STABILITY**');
  print('-' * 40);

  final manager = MCPManager();

  try {
    await manager.initialize('mcp.json');

    // Test stability over multiple iterations
    for (int i = 0; i < 3; i++) {
      print('🔄 ITERATION[$i]: Checking server status...');

      final connectedServers = manager.connectedServers;
      final allTools = manager.getAllTools();

      print('🔗 CONNECTED[$i]: ${connectedServers.length} servers');
      print('🛠️ TOOLS[$i]: ${allTools.length} tools');

      // Wait between checks
      await Future.delayed(const Duration(seconds: 2));

      // Refresh capabilities to test stability
      print('🔄 REFRESHING: Capabilities for iteration $i...');
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
    print('✅ STABILITY TEST: PASSED');
  } catch (e, stackTrace) {
    print('💥 STABILITY FAILURE: $e');
    print('STACK: $stackTrace');
    await manager.closeAll();
    exit(1);
  }
}
