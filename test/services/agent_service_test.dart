import 'package:test/test.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/models/agent_status_model.dart';
import 'package:vibe_coder/services/agent_service.dart';

void main() {
  group('🔧 AGENT SERVICE BASIC TESTS', () {
    test('✅ Service initialization', () {
      final service = AgentService();
      expect(service.data, isEmpty);
      expect(service.isInitialized, isFalse);
    });

    test('✅ Agent creation', () async {
      final service = AgentService();
      await service.initialize();

      final agent = await service.createAgent(
        name: 'Test Agent',
        systemPrompt: 'Test prompt',
      );

      expect(service.data.length, equals(1));
      expect(service.getById(agent.id), equals(agent));
      expect(service.getByName('Test Agent'), equals(agent));
    });
  });

  group('🎯 AGENT STATUS INTEGRATION TESTS (DR004)', () {
    test('✅ Get agents by processing status', () async {
      final service = AgentService();
      await service.initialize();

      // Create test agents
      final idleAgent = await service.createAgent(
        name: 'Idle Agent',
        systemPrompt: 'Test prompt',
      );

      final processingAgent = await service.createAgent(
        name: 'Processing Agent',
        systemPrompt: 'Test prompt',
      );

      final errorAgent = await service.createAgent(
        name: 'Error Agent',
        systemPrompt: 'Test prompt',
      );

      // Set different statuses
      processingAgent.setProcessing();
      errorAgent.setError('Test error');

      // Test status filtering
      final idleAgents = service.getIdleAgents();
      final processingAgents = service.getProcessingAgents();
      final errorAgents = service.getErrorAgents();

      expect(idleAgents.length, equals(1));
      expect(idleAgents.first.id, equals(idleAgent.id));

      expect(processingAgents.length, equals(1));
      expect(processingAgents.first.id, equals(processingAgent.id));

      expect(errorAgents.length, equals(1));
      expect(errorAgents.first.id, equals(errorAgent.id));
    });

    test('✅ Agent status updates via service', () async {
      final service = AgentService();
      await service.initialize();

      final testAgent = await service.createAgent(
        name: 'Test Agent',
        systemPrompt: 'Test prompt',
      );

      expect(testAgent.status, equals(AgentProcessingStatus.idle));

      // Test service status update methods
      await service.setAgentProcessing(testAgent.id);
      expect(testAgent.status, equals(AgentProcessingStatus.processing));

      await service.setAgentIdle(testAgent.id);
      expect(testAgent.status, equals(AgentProcessingStatus.idle));

      await service.setAgentError(testAgent.id, 'Test error message');
      expect(testAgent.status, equals(AgentProcessingStatus.error));
      expect(testAgent.errorMessage, equals('Test error message'));
    });

    test('✅ Status summary generation', () async {
      final service = AgentService();
      await service.initialize();

      // Create test agents with different statuses
      final agent1 =
          await service.createAgent(name: 'Agent 1', systemPrompt: 'Test');
      final agent2 =
          await service.createAgent(name: 'Agent 2', systemPrompt: 'Test');
      final agent3 =
          await service.createAgent(name: 'Agent 3', systemPrompt: 'Test');

      // Set different statuses
      agent1.setIdle();
      agent2.setProcessing();
      agent3.setError('Test error');

      final summary = service.getStatusSummary();

      expect(summary['totalAgents'], equals(3));
      expect(summary['idleCount'], equals(1));
      expect(summary['processingCount'], equals(1));
      expect(summary['errorCount'], equals(1));

      expect(summary['idleAgents'], contains(agent1.id));
      expect(summary['processingAgents'], contains(agent2.id));
      expect(summary['errorAgents'], contains(agent3.id));
    });

    test('🚀 PERFORMANCE: Status queries < 5ms', () async {
      final service = AgentService();
      await service.initialize();

      // Create multiple agents for performance test
      final agents = <AgentModel>[];
      for (int i = 0; i < 10; i++) {
        final agent = await service.createAgent(
          name: 'Agent $i',
          systemPrompt: 'Test prompt',
        );
        agents.add(agent);

        // Set various statuses
        if (i % 3 == 0) {
          agent.setProcessing();
        } else if (i % 3 == 1) {
          agent.setError('Error $i');
        }
        // else remains idle
      }

      // Performance test for status queries
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        service.getProcessingAgents();
        service.getIdleAgents();
        service.getErrorAgents();
        service.getStatusSummary();
      }
      stopwatch.stop();

      final averageTimeMs = stopwatch.elapsedMilliseconds / 100;
      expect(averageTimeMs, lessThan(5),
          reason: 'Status queries should be < 5ms average');
    });

    test('✅ Status update exception handling', () async {
      final service = AgentService();
      await service.initialize();

      // Test updating non-existent agent
      expect(
        () async => await service.setAgentProcessing('non-existent-id'),
        throwsA(isA<Exception>()),
      );

      expect(
        () async => await service.setAgentError('non-existent-id', 'Error'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
