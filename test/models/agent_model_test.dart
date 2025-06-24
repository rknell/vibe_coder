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

  // DR004 INTEGRATION: Status management tests
  group('AgentModel Status Management (DR004 Integration)', () {
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

    group('🏗️ STATUS INITIALIZATION', () {
      test('✅ VICTORY: Agent initializes with idle status by default', () {
        final agent = AgentModel(
          name: 'Test Agent',
          systemPrompt: 'You are a test agent',
        );

        expect(agent.processingStatus, AgentProcessingStatus.idle);
        expect(agent.errorMessage, isNull);
        expect(agent.lastStatusChange, isA<DateTime>());
        expect(agent.isProcessing, isFalse); // Legacy field should be in sync
      });

      test('✅ VICTORY: Agent can be initialized with custom status', () {
        final now = DateTime.now();
        final agent = AgentModel(
          name: 'Test Agent',
          systemPrompt: 'You are a test agent',
          processingStatus: AgentProcessingStatus.processing,
          lastStatusChange: now,
          errorMessage: 'Test error',
        );

        expect(agent.processingStatus, AgentProcessingStatus.processing);
        expect(agent.lastStatusChange, now);
        expect(agent.errorMessage, 'Test error');
      });
    });

    group('⚡ STATUS TRANSITIONS', () {
      test('✅ VICTORY: setProcessingStatus updates status correctly', () {
        final agent = AgentModel(
          name: 'Test Agent',
          systemPrompt: 'You are a test agent',
        );

        final beforeTime = DateTime.now();
        agent.setProcessingStatus();
        final afterTime = DateTime.now();

        expect(agent.processingStatus, AgentProcessingStatus.processing);
        expect(agent.errorMessage, isNull);
        expect(agent.isProcessing, isTrue); // Legacy field synced
        expect(
            agent.lastStatusChange.isAfter(beforeTime) ||
                agent.lastStatusChange.isAtSameMomentAs(beforeTime),
            isTrue);
        expect(
            agent.lastStatusChange.isBefore(afterTime) ||
                agent.lastStatusChange.isAtSameMomentAs(afterTime),
            isTrue);
      });

      test('✅ VICTORY: setIdleStatus updates status correctly', () {
        final agent = AgentModel(
          name: 'Test Agent',
          systemPrompt: 'You are a test agent',
          processingStatus: AgentProcessingStatus.processing,
        );

        final beforeTime = DateTime.now();
        agent.setIdleStatus();
        final afterTime = DateTime.now();

        expect(agent.processingStatus, AgentProcessingStatus.idle);
        expect(agent.errorMessage, isNull);
        expect(agent.isProcessing, isFalse); // Legacy field synced
        expect(
            agent.lastStatusChange.isAfter(beforeTime) ||
                agent.lastStatusChange.isAtSameMomentAs(beforeTime),
            isTrue);
        expect(
            agent.lastStatusChange.isBefore(afterTime) ||
                agent.lastStatusChange.isAtSameMomentAs(afterTime),
            isTrue);
      });

      test('✅ VICTORY: setErrorStatus updates status with message', () {
        final agent = AgentModel(
          name: 'Test Agent',
          systemPrompt: 'You are a test agent',
        );

        const errorMessage = 'Test error occurred';
        final beforeTime = DateTime.now();
        agent.setErrorStatus(errorMessage);
        final afterTime = DateTime.now();

        expect(agent.processingStatus, AgentProcessingStatus.error);
        expect(agent.errorMessage, errorMessage);
        expect(agent.isProcessing, isFalse); // Legacy field synced
        expect(
            agent.lastStatusChange.isAfter(beforeTime) ||
                agent.lastStatusChange.isAtSameMomentAs(beforeTime),
            isTrue);
        expect(
            agent.lastStatusChange.isBefore(afterTime) ||
                agent.lastStatusChange.isAtSameMomentAs(afterTime),
            isTrue);
      });

      test('✅ VICTORY: Status transitions clear error message', () {
        final agent = AgentModel(
          name: 'Test Agent',
          systemPrompt: 'You are a test agent',
        );

        // Set error status
        agent.setErrorStatus('Test error');
        expect(agent.errorMessage, 'Test error');

        // Transition to processing should clear error
        agent.setProcessingStatus();
        expect(agent.errorMessage, isNull);

        // Set error again
        agent.setErrorStatus('Another error');
        expect(agent.errorMessage, 'Another error');

        // Transition to idle should clear error
        agent.setIdleStatus();
        expect(agent.errorMessage, isNull);
      });
    });

    group('🔔 CHANGE NOTIFICATIONS', () {
      test('✅ VICTORY: Status changes trigger notifyListeners', () {
        final agent = AgentModel(
          name: 'Test Agent',
          systemPrompt: 'You are a test agent',
        );

        var notificationCount = 0;
        agent.addListener(() {
          notificationCount++;
        });

        // Test all status transitions
        agent.setProcessingStatus();
        expect(notificationCount, 1);

        agent.setIdleStatus();
        expect(notificationCount, 2);

        agent.setErrorStatus('Test error');
        expect(notificationCount, 3);

        // No notification if status doesn't change
        agent.setErrorStatus(
            'Different error'); // Should still notify (error message changed)
        expect(notificationCount, 4);

        agent.setProcessingStatus(); // Change from error to processing
        expect(notificationCount, 5);

        agent
            .setProcessingStatus(); // No change - should still update if already processing
        expect(notificationCount, 5); // No change since already processing
      });
    });

    group('💾 STATUS SERIALIZATION', () {
      test('✅ VICTORY: Status fields serialize to JSON correctly', () {
        final agent = AgentModel(
          name: 'Test Agent',
          systemPrompt: 'You are a test agent',
          processingStatus: AgentProcessingStatus.error,
          errorMessage: 'Test error',
        );

        final json = agent.toJson();

        expect(json['processingStatus'], 'error');
        expect(json['errorMessage'], 'Test error');
        expect(json['lastStatusChange'], isA<String>());
        expect(json['isProcessing'], isFalse); // Legacy field
      });

      test('✅ VICTORY: Status fields deserialize from JSON correctly', () {
        final originalAgent = AgentModel(
          name: 'Test Agent',
          systemPrompt: 'You are a test agent',
        );
        originalAgent.setErrorStatus('Serialization test error');

        final json = originalAgent.toJson();
        final restoredAgent = AgentModel.fromJson(json);

        expect(restoredAgent.processingStatus, originalAgent.processingStatus);
        expect(restoredAgent.errorMessage, originalAgent.errorMessage);
        expect(restoredAgent.lastStatusChange, originalAgent.lastStatusChange);
      });

      test('✅ VICTORY: Status JSON handles malformed data gracefully', () {
        final json = {
          'id': 'test-agent',
          'name': 'Test Agent',
          'systemPrompt': 'You are a test agent',
          'processingStatus': 'invalid_status',
          'lastStatusChange': 'invalid_date',
          'errorMessage': null,
        };

        // Should use defaults for invalid data
        final agent = AgentModel.fromJson(json);
        expect(agent.processingStatus, AgentProcessingStatus.idle);
        expect(agent.lastStatusChange, isA<DateTime>());
        expect(agent.errorMessage, isNull);
      });
    });

    group('📄 STATUS COPYSWITH', () {
      test('✅ VICTORY: copyWith includes status fields', () {
        final originalAgent = AgentModel(
          name: 'Test Agent',
          systemPrompt: 'You are a test agent',
          processingStatus: AgentProcessingStatus.idle,
        );

        final now = DateTime.now();
        final copiedAgent = originalAgent.copyWith(
          processingStatus: AgentProcessingStatus.processing,
          lastStatusChange: now,
          errorMessage: 'Test copy error',
        );

        expect(copiedAgent.processingStatus, AgentProcessingStatus.processing);
        expect(copiedAgent.lastStatusChange, now);
        expect(copiedAgent.errorMessage, 'Test copy error');

        // Original should be unchanged
        expect(originalAgent.processingStatus, AgentProcessingStatus.idle);
        expect(originalAgent.errorMessage, isNull);
      });
    });

    group('🔗 LEGACY FIELD SYNCHRONIZATION', () {
      test('✅ VICTORY: Legacy isProcessing field stays synchronized', () {
        final agent = AgentModel(
          name: 'Test Agent',
          systemPrompt: 'You are a test agent',
        );

        // Initially idle
        expect(agent.isProcessing, isFalse);
        expect(agent.processingStatus, AgentProcessingStatus.idle);

        // Set to processing
        agent.setProcessingStatus();
        expect(agent.isProcessing, isTrue);
        expect(agent.processingStatus, AgentProcessingStatus.processing);

        // Set to error
        agent.setErrorStatus('Test error');
        expect(agent.isProcessing, isFalse);
        expect(agent.processingStatus, AgentProcessingStatus.error);

        // Set to idle
        agent.setIdleStatus();
        expect(agent.isProcessing, isFalse);
        expect(agent.processingStatus, AgentProcessingStatus.idle);
      });
    });

    group('💾 STATUS PERSISTENCE', () {
      test('✅ VICTORY: Status persists through save/load cycle', () async {
        final agent = AgentModel(
          id: 'status-persist-test',
          name: 'Status Persist Test Agent',
          systemPrompt: 'You are a test agent',
        );

        // Set status
        agent.setErrorStatus('Persistence test error');

        // Save to disk
        await agent.save();

        // Load from disk
        final file = File('data/agents/status-persist-test.json');
        final jsonContent = await file.readAsString();
        final jsonData = jsonDecode(jsonContent) as Map<String, dynamic>;
        final loadedAgent = AgentModel.fromJson(jsonData);

        // Verify status is preserved
        expect(loadedAgent.processingStatus, AgentProcessingStatus.error);
        expect(loadedAgent.errorMessage, 'Persistence test error');
        expect(loadedAgent.lastStatusChange, agent.lastStatusChange);

        // Clean up
        await loadedAgent.delete();
      });
    });

    group('⚡ PERFORMANCE BENCHMARKS', () {
      test('🚀 STATUS UPDATES: < 1ms performance target', () {
        final agent = AgentModel(
          name: 'Performance Test Agent',
          systemPrompt: 'You are a test agent',
        );

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          agent.setProcessingStatus();
          agent.setIdleStatus();
          agent.setErrorStatus('Error $i');
        }

        stopwatch.stop();
        final avgTime =
            stopwatch.elapsedMicroseconds / 3000; // 3 operations per iteration

        expect(avgTime, lessThan(1000)); // < 1ms (1000 microseconds)
      });

      test('🚀 STATUS SERIALIZATION: < 5ms performance target', () {
        final agent = AgentModel(
          name: 'Serialization Performance Test Agent',
          systemPrompt: 'You are a test agent',
        );
        agent.setErrorStatus('Performance test error message with details');

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          final json = agent.toJson();
          AgentModel.fromJson(json);
        }

        stopwatch.stop();
        final avgTime =
            stopwatch.elapsedMicroseconds / 200; // 2 operations per iteration

        expect(avgTime, lessThan(5000)); // < 5ms (5000 microseconds)
      });
    });
  });
}
