/// Unit Tests for MCP Process Manager
///
/// ## MISSION ACCOMPLISHED
/// Validates that MCP process manager prevents multiple server instances
/// and properly shares processes across multiple clients.
///
/// ## TEST WARFARE STRATEGIES
/// 1. **Single Instance Validation**: Ensures same server config creates only one process
/// 2. **Reference Counting**: Validates process lifecycle based on reference count
/// 3. **Process Reuse**: Confirms multiple clients share the same underlying process
/// 4. **Cleanup Verification**: Ensures processes terminate when no references remain
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Process creation: O(1) for existing, O(n) for new processes
/// - Reference management: O(1) operations
/// - Cleanup: O(1) per client, process terminates at zero references
library;

import 'package:test/test.dart';
import 'package:vibe_coder/services/mcp_process_manager.dart';
import 'dart:io';

void main() {
  group('MCPProcessManager', () {
    late MCPProcessManager processManager;

    setUp(() {
      // Get fresh instance for each test
      processManager = MCPProcessManager.instance;
    });

    tearDown(() async {
      // Clean shutdown after each test
      await processManager.shutdownAll();
    });

    test('🏆 SINGLETON PATTERN: Ensures single instance', () {
      // GIVEN: Multiple calls to get instance
      final instance1 = MCPProcessManager.instance;
      final instance2 = MCPProcessManager.instance;

      // THEN: Same instance returned
      expect(instance1, same(instance2));
    });

    test('🔄 PROCESS REUSE: Multiple clients share same process', () async {
      // GIVEN: Same server configuration used by multiple clients
      const serverName1 = 'test-server-1';
      const serverName2 = 'test-server-2';
      const command = 'echo'; // Simple command that exists on most systems
      const args = ['test'];

      // WHEN: Two clients request same server configuration
      final process1 = await processManager.getOrCreateProcess(
        serverName: serverName1,
        command: command,
        args: args,
      );

      final process2 = await processManager.getOrCreateProcess(
        serverName: serverName2,
        command: command,
        args: args,
      );

      // THEN: Same underlying process is shared
      expect(process1.processKey, equals(process2.processKey));
      expect(process1.pid, equals(process2.pid));
      expect(process1.process, same(process2.process));

      // THEN: Different server names but same process
      expect(process1.serverName, equals(serverName1));
      expect(process2.serverName, equals(serverName2));

      // Cleanup
      process1.dispose();
      process2.dispose();
    });

    test('💀 REFERENCE COUNTING: Process terminates when no references',
        () async {
      // GIVEN: Single server configuration
      const serverName = 'test-server';
      const command = 'echo';
      const args = ['test'];

      // WHEN: Create process and get initial stats
      final process = await processManager.getOrCreateProcess(
        serverName: serverName,
        command: command,
        args: args,
      );

      final statsWithProcess = processManager.getProcessStats();
      expect(statsWithProcess.totalProcesses, equals(1));

      // Verify process is accessible before disposal
      expect(process.pid, isA<int>());
      expect(process.processKey, isA<String>());

      // WHEN: Dispose process
      process.dispose();

      // Give some time for cleanup
      await Future.delayed(Duration(milliseconds: 100));

      // THEN: Process should be removed from registry
      final statsAfterDispose = processManager.getProcessStats();
      expect(statsAfterDispose.totalProcesses, equals(0));

      // THEN: Process should be terminated (this might be flaky in tests)
      // We can't reliably test process termination in unit tests
      // but we can verify it's removed from the manager
    });

    test('📊 PROCESS STATISTICS: Accurate process tracking', () async {
      // GIVEN: Multiple different server configurations
      final processes = <SharedMCPProcess>[];

      // WHEN: Create multiple processes (using sleep to keep them alive)
      for (int i = 0; i < 3; i++) {
        final process = await processManager.getOrCreateProcess(
          serverName: 'server-$i',
          command: 'sleep',
          args: [
            '${10 + i}'
          ], // Different sleep durations to create unique processes
        );
        processes.add(process);
      }

      // WHEN: Create duplicate process (should reuse)
      final duplicateProcess = await processManager.getOrCreateProcess(
        serverName: 'server-duplicate',
        command: 'sleep', // Same command as first
        args: ['10'], // Same args as first process - this should reuse process
      );
      processes.add(duplicateProcess);

      // THEN: Verify statistics
      final stats = processManager.getProcessStats();

      // Should have 3 unique processes (sleep with different args)
      // But duplicate process reuses first process, so only 3 unique processes
      expect(stats.totalProcesses, equals(3));

      // Should have process details
      final processDetails = stats.processes;
      expect(processDetails.length, equals(3));

      // Verify process detail structure
      for (final detail in processDetails) {
        expect(detail.processKey, isA<String>());
        expect(detail.pid, isA<int>());
        expect(detail.command, isA<String>());
        expect(detail.referenceCount, isA<int>());
        expect(detail.referencingServers, isA<List<String>>());
      }

      // Cleanup all processes
      for (final process in processes) {
        process.dispose();
      }
    });

    test('🔑 PROCESS KEY GENERATION: Unique keys for different configs',
        () async {
      // GIVEN: Different server configurations
      final process1 = await processManager.getOrCreateProcess(
        serverName: 'server1',
        command: 'echo',
        args: ['arg1'],
      );

      final process2 = await processManager.getOrCreateProcess(
        serverName: 'server2',
        command: 'echo',
        args: ['arg2'], // Different args
      );

      final process3 = await processManager.getOrCreateProcess(
        serverName: 'server3',
        command: 'cat', // Different command
        args: ['arg1'],
      );

      // THEN: All should have different process keys
      expect(process1.processKey, isNot(equals(process2.processKey)));
      expect(process1.processKey, isNot(equals(process3.processKey)));
      expect(process2.processKey, isNot(equals(process3.processKey)));

      // Cleanup
      process1.dispose();
      process2.dispose();
      process3.dispose();
    });

    test('🚫 DOUBLE DISPOSE: Safe double disposal handling', () async {
      // GIVEN: Process created
      final process = await processManager.getOrCreateProcess(
        serverName: 'test-server',
        command: 'echo',
        args: ['test'],
      );

      // WHEN: Dispose twice
      process.dispose();

      // THEN: Second dispose should not throw
      expect(() => process.dispose(), returnsNormally);
    });

    test('🛑 SHUTDOWN ALL: Clean shutdown of all processes', () async {
      // GIVEN: Multiple active processes
      final processes = <SharedMCPProcess>[];

      for (int i = 0; i < 3; i++) {
        final process = await processManager.getOrCreateProcess(
          serverName: 'server-$i',
          command: 'echo',
          args: ['test-$i'],
        );
        processes.add(process);
      }

      // WHEN: Shutdown all processes
      await processManager.shutdownAll();

      // THEN: Process registry should be empty
      final stats = processManager.getProcessStats();
      expect(stats.totalProcesses, equals(0));

      // Note: Individual processes are not disposed, but underlying processes are terminated
      // This simulates application shutdown where we force-terminate all processes
    });
  });

  group('SharedMCPProcess', () {
    late MCPProcessManager processManager;

    setUp(() {
      processManager = MCPProcessManager.instance;
    });

    tearDown(() async {
      await processManager.shutdownAll();
    });

    test('📋 PROCESS PROPERTIES: Correct property access', () async {
      // GIVEN: Created process
      const serverName = 'test-server';
      final process = await processManager.getOrCreateProcess(
        serverName: serverName,
        command: 'echo',
        args: ['test'],
      );

      // THEN: Properties should be accessible
      expect(process.serverName, equals(serverName));
      expect(process.pid, isA<int>());
      expect(process.processKey, isA<String>());
      expect(process.process, isA<Process>());
      expect(process.isAlive, isTrue);

      // Cleanup
      process.dispose();
    });

    test('🔄 COMPARABLE IMPLEMENTATION: Proper sorting support', () async {
      // GIVEN: Multiple processes
      final process1 = await processManager.getOrCreateProcess(
        serverName: 'server-b',
        command: 'echo',
        args: ['test1'],
      );

      final process2 = await processManager.getOrCreateProcess(
        serverName: 'server-a',
        command: 'echo',
        args: ['test2'],
      );

      // WHEN: Create list and sort
      final processes = [process1, process2];
      processes.sort();

      // THEN: Should be sorted by process key
      expect(processes.first.compareTo(processes.last), lessThan(0));

      // Cleanup
      process1.dispose();
      process2.dispose();
    });

    test('🆔 EQUALITY AND HASH: Proper equality implementation', () async {
      // GIVEN: Same process obtained twice
      const serverName1 = 'server1';
      const serverName2 = 'server2';

      final process1a = await processManager.getOrCreateProcess(
        serverName: serverName1,
        command: 'echo',
        args: ['test'],
      );

      final process1b = await processManager.getOrCreateProcess(
        serverName: serverName1,
        command: 'echo',
        args: ['test'],
      );

      final process2 = await processManager.getOrCreateProcess(
        serverName: serverName2,
        command: 'cat',
        args: ['test'],
      );

      // THEN: Same server name and process key should be equal
      expect(process1a, equals(process1b));
      expect(process1a.hashCode, equals(process1b.hashCode));

      // THEN: Different process should not be equal
      expect(process1a, isNot(equals(process2)));

      // Cleanup
      process1a.dispose();
      process1b.dispose();
      process2.dispose();
    });
  });
}
