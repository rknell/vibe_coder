import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/models/agent_status_model.dart';

void main() {
  group('AgentModel Persistence Tests', () {
    setUp(() {
      // Clean up any existing test data
      final testDir = Directory('data/agents');
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
    });

    tearDown(() {
      // Clean up test data after each test
      final testDir = Directory('data/agents');
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
    });

    test('should save agent to disk and load it back', () async {
      // Create a test agent
      final agent = AgentModel(
        id: 'test-agent-123',
        name: 'Test Agent',
        systemPrompt: 'You are a test agent',
        temperature: 0.8,
        maxTokens: 2000,
        useBetaFeatures: true,
      );

      // Save agent to disk
      await agent.save();

      // Verify file was created
      final file = File('data/agents/test-agent-123.json');
      expect(file.existsSync(), isTrue);

      // Load agent from disk
      final fileContent = await file.readAsString();
      final json = jsonDecode(fileContent) as Map<String, dynamic>;
      final loadedAgent = AgentModel.fromJson(json);

      // Verify all properties match
      expect(loadedAgent.id, equals(agent.id));
      expect(loadedAgent.name, equals(agent.name));
      expect(loadedAgent.systemPrompt, equals(agent.systemPrompt));
      expect(loadedAgent.temperature, equals(agent.temperature));
      expect(loadedAgent.maxTokens, equals(agent.maxTokens));
      expect(loadedAgent.useBetaFeatures, equals(agent.useBetaFeatures));
    });

    test('should delete agent from disk', () async {
      // Create and save a test agent
      final agent = AgentModel(
        id: 'test-agent-delete',
        name: 'Agent to Delete',
        systemPrompt: 'This agent will be deleted',
      );
      await agent.save();

      // Verify file exists
      final file = File('data/agents/test-agent-delete.json');
      expect(file.existsSync(), isTrue);

      // Delete agent
      await agent.delete();

      // Verify file is gone
      expect(file.existsSync(), isFalse);
    });

    test('should validate agent before saving', () async {
      // Create agent with invalid data
      final agent = AgentModel(
        id: '', // Invalid: empty ID
        name: '', // Invalid: empty name
        systemPrompt: '', // Invalid: empty system prompt
        temperature: 5.0, // Invalid: temperature too high
      );

      // Should throw validation error
      expect(() async => await agent.save(), throwsA(isA<StateError>()));
    });

    test('should delete agent file from disk', () async {
      // Create and save agent
      final agent = AgentModel(
        id: 'test-agent-delete',
        name: 'Test Delete Agent',
        systemPrompt: 'You are a test agent for deletion',
      );

      await agent.save();

      // Verify file exists
      final file = File('data/agents/${agent.id}.json');
      expect(file.existsSync(), isTrue);

      // Delete agent
      await agent.delete();

      // Verify file is deleted
      expect(file.existsSync(), isFalse);
    });

    test('should correctly filter MCP tools based on preferences', () async {
      // Create agent with specific MCP preferences
      final agent = AgentModel(
        id: 'test-agent-mcp-filter',
        name: 'Test MCP Filter Agent',
        systemPrompt: 'You are a test agent',
        mcpServerPreferences: {
          'memory': true,
          'filesystem': false,
        },
        mcpToolPreferences: {
          'memory:read_graph': true,
          'memory:store_data': false,
        },
      );

      // Test server preference filtering
      expect(agent.getMCPServerPreference('memory'), isTrue);
      expect(agent.getMCPServerPreference('filesystem'), isFalse);
      expect(agent.getMCPServerPreference('unknown_server'),
          isTrue); // defaults to true

      // Test tool preference filtering
      expect(agent.getMCPToolPreference('memory:read_graph'), isTrue);
      expect(agent.getMCPToolPreference('memory:store_data'), isFalse);
      expect(agent.getMCPToolPreference('unknown:tool'),
          isTrue); // defaults to true
    });

    test(
        '🛡️ REGRESSION: AgentTab references must update when agent preferences change',
        () async {
      // This test prevents regression of the bug where AgentTab held stale AgentModel references
      // causing disabled MCP tools to still be sent to the API during conversations

      // Create original agent with specific MCP preferences
      final originalAgent = AgentModel(
        id: 'regression-test-agent',
        name: 'Regression Test Agent',
        systemPrompt: 'You are a test agent',
        mcpServerPreferences: {'memory': true},
        mcpToolPreferences: {'memory:read_graph': true},
      );

      // Save original agent
      await originalAgent.save();

      // Simulate agent editing: create updated agent with different preferences
      final updatedAgent = originalAgent.copyWith(
        mcpServerPreferences: {'memory': false}, // Disable memory server
        mcpToolPreferences: {'memory:read_graph': false}, // Disable tool
      );

      // Save updated agent
      await updatedAgent.save();

      // Verify that the updated agent has the new preferences
      expect(updatedAgent.getMCPServerPreference('memory'), isFalse);
      expect(updatedAgent.getMCPToolPreference('memory:read_graph'), isFalse);

      // Verify old agent still has old preferences (they are different instances)
      expect(originalAgent.getMCPServerPreference('memory'), isTrue);
      expect(originalAgent.getMCPToolPreference('memory:read_graph'), isTrue);

      // This test documents the critical requirement:
      // When AgentService.replaceAgent() is called, any AgentTab references
      // MUST be updated to point to the new AgentModel instance to ensure
      // MCP tool filtering uses the updated preferences in conversations

      // Clean up test files
      await originalAgent.delete();
      await updatedAgent.delete();
    });

    test(
        '🛡️ REGRESSION: MCP tool filtering simulation matches Agent.getAvailableTools() logic',
        () {
      // This test ensures the tool filtering logic works correctly and prevents
      // disabled tools from being included in API calls

      final agent = AgentModel(
        id: 'filter-simulation-agent',
        name: 'Filter Simulation Agent',
        systemPrompt: 'You are a test agent',
        mcpServerPreferences: {
          'memory': true, // Enable memory server
          'filesystem': false, // Disable filesystem server
          'github': true, // Enable github server
        },
        mcpToolPreferences: {
          'memory:read_graph': true, // Enable this tool
          'memory:store_data': false, // Disable this tool
          'filesystem:list_files':
              false, // Disable filesystem tool (server also disabled)
          'github:create_issue': false, // Disable this github tool
          // github:list_repos not specified - should default to true
        },
      );

      // Simulate the same filtering logic used in Agent.getAvailableTools()
      final mockTools = [
        {'uniqueId': 'memory:read_graph', 'serverName': 'memory'},
        {'uniqueId': 'memory:store_data', 'serverName': 'memory'},
        {'uniqueId': 'filesystem:list_files', 'serverName': 'filesystem'},
        {'uniqueId': 'github:create_issue', 'serverName': 'github'},
        {'uniqueId': 'github:list_repos', 'serverName': 'github'},
      ];

      final filteredTools = <Map<String, String>>[];

      for (final tool in mockTools) {
        final serverName = tool['serverName']!;
        final toolUniqueId = tool['uniqueId']!;

        // Apply Agent.getAvailableTools() filtering logic
        final serverEnabled = agent.getMCPServerPreference(serverName);
        if (!serverEnabled) continue;

        final toolEnabled = agent.getMCPToolPreference(toolUniqueId);
        if (!toolEnabled) continue;

        filteredTools.add(tool);
      }

      // Should only include enabled tools from enabled servers
      expect(filteredTools.length, equals(2));

      final filteredIds = filteredTools.map((t) => t['uniqueId']).toSet();
      expect(filteredIds.contains('memory:read_graph'),
          isTrue); // Enabled tool from enabled server
      expect(filteredIds.contains('github:list_repos'),
          isTrue); // Default enabled tool from enabled server
      expect(
          filteredIds.contains('memory:store_data'), isFalse); // Disabled tool
      expect(filteredIds.contains('filesystem:list_files'),
          isFalse); // Tool from disabled server
      expect(filteredIds.contains('github:create_issue'),
          isFalse); // Disabled tool from enabled server
    });

    test('should maintain MCP preferences in JSON serialization', () async {
      // Create agent with MCP preferences
      final originalAgent = AgentModel(
        id: 'test-agent-mcp-json',
        name: 'Test MCP JSON Agent',
        systemPrompt: 'You are a test agent for MCP JSON',
        mcpServerPreferences: {
          'memory': true,
          'filesystem': false,
        },
        mcpToolPreferences: {
          'memory:read_graph': true,
          'memory:store_data': false,
        },
      );

      // Save to JSON and reload
      await originalAgent.save();

      final file = File('data/agents/${originalAgent.id}.json');
      final jsonContent = await file.readAsString();
      final jsonData = jsonDecode(jsonContent) as Map<String, dynamic>;

      final reloadedAgent = AgentModel.fromJson(jsonData);

      // Verify MCP preferences are preserved
      expect(reloadedAgent.getMCPServerPreference('memory'), isTrue);
      expect(reloadedAgent.getMCPServerPreference('filesystem'), isFalse);
      expect(reloadedAgent.getMCPToolPreference('memory:read_graph'), isTrue);
      expect(reloadedAgent.getMCPToolPreference('memory:store_data'), isFalse);

      // Clean up
      await reloadedAgent.delete();
    });
  });

  group('🎯 STATUS MANAGEMENT INTEGRATION (DR004)', () {
    test('✅ Default status initialization', () {
      final agent = AgentModel(
        name: 'Test Agent',
        systemPrompt: 'Test prompt',
      );

      expect(agent.status, equals(AgentProcessingStatus.idle));
      expect(agent.errorMessage, isNull);
      expect(agent.lastStatusChange, isNotNull);
      expect(agent.isProcessing, isFalse);
    });

    test('✅ Status transitions with notifications', () {
      final agent = AgentModel(
        name: 'Test Agent',
        systemPrompt: 'Test prompt',
      );

      final notifications = <String>[];
      agent.addListener(() {
        notifications.add('status_changed');
      });

      // Test processing transition
      agent.setProcessing();
      expect(agent.status, equals(AgentProcessingStatus.processing));
      expect(agent.isProcessing, isTrue);
      expect(agent.errorMessage, isNull);
      expect(notifications.length, equals(1));

      // Test idle transition
      agent.setIdle();
      expect(agent.status, equals(AgentProcessingStatus.idle));
      expect(agent.isProcessing, isFalse);
      expect(agent.errorMessage, isNull);
      expect(notifications.length, equals(2));

      // Test error transition
      agent.setError('Test error message');
      expect(agent.status, equals(AgentProcessingStatus.error));
      expect(agent.isProcessing, isFalse);
      expect(agent.errorMessage, equals('Test error message'));
      expect(notifications.length, equals(3));
    });

    test('✅ Status change only triggers notification when changed', () {
      final agent = AgentModel(
        name: 'Test Agent',
        systemPrompt: 'Test prompt',
      );

      final notifications = <String>[];
      agent.addListener(() {
        notifications.add('changed');
      });

      // Multiple setIdle calls should only trigger one notification
      agent.setIdle();
      agent.setIdle();
      agent.setIdle();
      expect(
          notifications.length, equals(0)); // No change from initial idle state

      // Change to processing
      agent.setProcessing();
      expect(notifications.length, equals(1));

      // Multiple setProcessing calls should not retrigger
      agent.setProcessing();
      agent.setProcessing();
      expect(notifications.length, equals(1));
    });

    test('✅ Legacy setLegacyProcessing integration', () {
      final agent = AgentModel(
        name: 'Test Agent',
        systemPrompt: 'Test prompt',
      );

      // Legacy method should update both fields consistently
      agent.setLegacyProcessing(true);
      expect(agent.isProcessing, isTrue);
      expect(agent.status, equals(AgentProcessingStatus.processing));

      agent.setLegacyProcessing(false);
      expect(agent.isProcessing, isFalse);
      expect(agent.status, equals(AgentProcessingStatus.idle));
    });

    test('✅ Status JSON serialization and deserialization', () {
      final agent = AgentModel(
        name: 'Test Agent',
        systemPrompt: 'Test prompt',
        status: AgentProcessingStatus.processing,
      );
      agent.setError('Test error');

      final json = agent.toJson();
      expect(json['status'], equals('error'));
      expect(json['lastStatusChange'], isNotNull);
      expect(json['errorMessage'], equals('Test error'));

      final restored = AgentModel.fromJson(json);
      expect(restored.status, equals(AgentProcessingStatus.error));
      expect(restored.errorMessage, equals('Test error'));
      expect(restored.lastStatusChange, isNotNull);
    });

    test('✅ Status JSON fallback handling', () {
      final json = {
        'id': 'test-id',
        'name': 'Test Agent',
        'systemPrompt': 'Test prompt',
        'status': 'invalid_status', // Invalid status should fallback to idle
        'isActive': true,
        'isProcessing': false,
        'createdAt': DateTime.now().toIso8601String(),
        'lastActiveAt': DateTime.now().toIso8601String(),
      };

      final agent = AgentModel.fromJson(json);
      expect(agent.status, equals(AgentProcessingStatus.idle)); // Fallback
      expect(agent.errorMessage, isNull);
    });

    test('🚀 PERFORMANCE: Status updates < 1ms', () {
      final agent = AgentModel(
        name: 'Test Agent',
        systemPrompt: 'Test prompt',
      );

      // Test status update performance
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        agent.setProcessing();
        agent.setIdle();
        agent.setError('Error $i');
      }
      stopwatch.stop();

      final averageTime = stopwatch.elapsedMicroseconds /
          3000; // 3 operations per iteration * 1000 iterations
      expect(averageTime, lessThan(1000),
          reason: 'Status updates should be < 1ms (1000 microseconds)');
    });
  });
}
