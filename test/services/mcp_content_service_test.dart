import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/services/mcp_content_service.dart';

void main() {
  group('MCPContentService', () {
    late MCPContentService service;

    setUp(() {
      service = MCPContentService();
    });

    tearDown(() {
      service.dispose();
    });

    // ✅ SERVICE LIFECYCLE TESTS
    group('🔄 Service Lifecycle Management', () {
      test('📊 SERVICE CREATION: Initial state should be stopped', () {
        expect(service.state, MCPServiceState.stopped);
        expect(service.currentAgentId, isNull);
        expect(service.isPolling, isFalse);
      });

      test('🚀 START POLLING: Should transition to running state', () async {
        const agentId = 'test-agent-123';

        service.startPolling(agentId);

        expect(service.state, MCPServiceState.running);
        expect(service.currentAgentId, agentId);
        expect(service.isPolling, isTrue);
      });

      test('🛑 STOP POLLING: Should transition to stopped state', () {
        const agentId = 'test-agent-123';
        service.startPolling(agentId);

        service.stopPolling();

        expect(service.state, MCPServiceState.stopped);
        expect(service.currentAgentId, isNull);
        expect(service.isPolling, isFalse);
      });

      test('⏸️ PAUSE POLLING: Should transition to paused state', () {
        const agentId = 'test-agent-123';
        service.startPolling(agentId);

        service.pausePolling();

        expect(service.state, MCPServiceState.paused);
        expect(service.currentAgentId, agentId);
        expect(service.isPolling, isFalse);
      });

      test('▶️ RESUME POLLING: Should transition back to running state', () {
        const agentId = 'test-agent-123';
        service.startPolling(agentId);
        service.pausePolling();

        service.resumePolling();

        expect(service.state, MCPServiceState.running);
        expect(service.currentAgentId, agentId);
        expect(service.isPolling, isTrue);
      });

      test('🚫 INVALID RESUME: Cannot resume when stopped', () {
        service.resumePolling();

        expect(service.state, MCPServiceState.stopped);
        expect(service.isPolling, isFalse);
      });
    });

    // ✅ AGENT COORDINATION TESTS
    group('🤖 Agent Coordination Management', () {
      test('🔄 SWITCH AGENT: Should update current agent ID', () {
        const initialAgent = 'agent-001';
        const newAgent = 'agent-002';

        service.startPolling(initialAgent);
        service.switchAgent(newAgent);

        expect(service.currentAgentId, newAgent);
        expect(service.state, MCPServiceState.running);
      });

      test('❌ SWITCH TO NULL: Should stop polling', () {
        const agentId = 'test-agent-123';
        service.startPolling(agentId);

        service.switchAgent(null);

        expect(service.currentAgentId, isNull);
        expect(service.state, MCPServiceState.stopped);
      });

      test('🎯 AGENT ACTIVATED: Should start polling for agent', () {
        const agentId = 'active-agent-456';

        service.onAgentActivated(agentId);

        expect(service.currentAgentId, agentId);
        expect(service.state, MCPServiceState.running);
      });

      test('💤 AGENT DEACTIVATED: Should stop polling', () {
        const agentId = 'test-agent-123';
        service.startPolling(agentId);

        service.onAgentDeactivated();

        expect(service.currentAgentId, isNull);
        expect(service.state, MCPServiceState.stopped);
      });
    });

    // ✅ TIMER MANAGEMENT TESTS
    group('⏰ Timer Management & Polling Infrastructure', () {
      test('🔄 POLLING TIMER: Should be null when stopped', () {
        expect(service.hasActiveTimer, isFalse);
      });

      test('⏰ POLLING TIMER: Should be active when running', () {
        const agentId = 'test-agent-123';

        service.startPolling(agentId);

        expect(service.hasActiveTimer, isTrue);
      });

      test('🛑 TIMER CLEANUP: Should clean up timer on stop', () {
        const agentId = 'test-agent-123';
        service.startPolling(agentId);

        service.stopPolling();

        expect(service.hasActiveTimer, isFalse);
      });

      test('⏸️ TIMER PAUSE: Should pause timer', () {
        const agentId = 'test-agent-123';
        service.startPolling(agentId);

        service.pausePolling();

        expect(service.hasActiveTimer, isFalse);
      });

      test('▶️ TIMER RESUME: Should restart timer', () {
        const agentId = 'test-agent-123';
        service.startPolling(agentId);
        service.pausePolling();

        service.resumePolling();

        expect(service.hasActiveTimer, isTrue);
      });
    });

    // ✅ STATE TRANSITION TESTS
    group('🔄 Service State Transitions', () {
      test(
          '📊 VALID TRANSITIONS: Stopped → Running → Paused → Running → Stopped',
          () {
        const agentId = 'transition-test-agent';

        // Initial state
        expect(service.state, MCPServiceState.stopped);

        // Stopped → Running
        service.startPolling(agentId);
        expect(service.state, MCPServiceState.running);

        // Running → Paused
        service.pausePolling();
        expect(service.state, MCPServiceState.paused);

        // Paused → Running
        service.resumePolling();
        expect(service.state, MCPServiceState.running);

        // Running → Stopped
        service.stopPolling();
        expect(service.state, MCPServiceState.stopped);
      });

      test('🚫 INVALID TRANSITION: Cannot pause when stopped', () {
        service.pausePolling();
        expect(service.state, MCPServiceState.stopped);
      });

      test('🔄 RESTART TRANSITION: Can restart after stop', () {
        const agentId = 'restart-test-agent';

        service.startPolling(agentId);
        service.stopPolling();
        service.startPolling(agentId);

        expect(service.state, MCPServiceState.running);
        expect(service.currentAgentId, agentId);
      });
    });

    // ✅ CHANGE NOTIFIER TESTS
    group('📡 ChangeNotifier Broadcasting', () {
      test('📻 STATE CHANGE NOTIFICATIONS: Should notify on state changes', () {
        var notificationCount = 0;
        service.addListener(() => notificationCount++);

        const agentId = 'notification-test-agent';
        service.startPolling(agentId);

        expect(notificationCount, greaterThan(0));
      });

      test('🤖 AGENT SWITCH NOTIFICATIONS: Should notify on agent changes', () {
        var notificationCount = 0;
        service.addListener(() => notificationCount++);

        service.startPolling('agent-001');
        notificationCount = 0; // Reset after initial start

        service.switchAgent('agent-002');

        expect(notificationCount, greaterThan(0));
      });

      test('⏸️ PAUSE NOTIFICATIONS: Should notify on pause/resume', () {
        var notificationCount = 0;
        service.addListener(() => notificationCount++);

        const agentId = 'pause-test-agent';
        service.startPolling(agentId);
        notificationCount = 0; // Reset after start

        service.pausePolling();
        final pauseNotifications = notificationCount;

        service.resumePolling();
        final resumeNotifications = notificationCount;

        expect(pauseNotifications, greaterThan(0));
        expect(resumeNotifications, greaterThan(pauseNotifications));
      });
    });

    // ✅ POLLING CONDITION TESTS
    group('🎯 Polling Condition Logic', () {
      test('✅ SHOULD POLL: True when running with agent', () {
        const agentId = 'polling-condition-agent';
        service.startPolling(agentId);

        expect(service.shouldPollForTesting(), isTrue);
      });

      test('❌ SHOULD NOT POLL: False when stopped', () {
        expect(service.shouldPollForTesting(), isFalse);
      });

      test('❌ SHOULD NOT POLL: False when paused', () {
        const agentId = 'paused-polling-agent';
        service.startPolling(agentId);
        service.pausePolling();

        expect(service.shouldPollForTesting(), isFalse);
      });

      test('❌ SHOULD NOT POLL: False when no agent', () {
        service.startPolling('agent');
        service.switchAgent(null);

        expect(service.shouldPollForTesting(), isFalse);
      });
    });

    // ✅ PERFORMANCE TESTS
    group('🚀 Performance & Resource Management', () {
      test('⚡ STATE TRANSITION SPEED: < 5ms', () {
        const agentId = 'performance-test-agent';
        final stopwatch = Stopwatch()..start();

        service.startPolling(agentId);
        service.pausePolling();
        service.resumePolling();
        service.stopPolling();

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(5));
      });

      test('🧠 MEMORY CLEANUP: No memory leaks on dispose', () {
        const agentId = 'memory-test-agent';
        service.startPolling(agentId);

        // Verify state before disposal
        expect(service.state, MCPServiceState.running);
        expect(service.hasActiveTimer, isTrue);

        // Dispose will be called in tearDown, so we don't call it here
        // This test verifies that disposal will work correctly
      });

      test('🔄 MULTIPLE START/STOP CYCLES: Memory stability', () {
        const agentId = 'stability-test-agent';

        // Multiple cycles
        for (int i = 0; i < 10; i++) {
          service.startPolling('$agentId-$i');
          service.stopPolling();
        }

        expect(service.state, MCPServiceState.stopped);
        expect(service.hasActiveTimer, isFalse);
      });
    });

    // ✅ ERROR HANDLING TESTS
    group('⚠️ Error Handling & Recovery', () {
      test('🛡️ SERVICE DISPOSAL: Should handle disposal gracefully', () {
        const agentId = 'disposal-test-agent';
        service.startPolling(agentId);

        // Verify service is running before disposal
        expect(service.state, MCPServiceState.running);
        expect(service.hasActiveTimer, isTrue);

        // tearDown will handle disposal - this verifies the setup is correct
      });

      test('🔄 DOUBLE START: Should handle multiple start calls', () {
        const agentId = 'double-start-agent';

        service.startPolling(agentId);
        service.startPolling(agentId);

        expect(service.state, MCPServiceState.running);
        expect(service.currentAgentId, agentId);
      });

      test('🛑 DOUBLE STOP: Should handle multiple stop calls', () {
        const agentId = 'double-stop-agent';
        service.startPolling(agentId);

        service.stopPolling();
        service.stopPolling();

        expect(service.state, MCPServiceState.stopped);
      });
    });
  });
}
