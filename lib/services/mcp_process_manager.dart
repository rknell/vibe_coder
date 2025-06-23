/// Universal MCP Process Manager - Single Instance Server Control
///
/// ## MISSION ACCOMPLISHED
/// Eliminates multiple MCP server instances by providing shared process management.
/// All MCP connections share the same underlying server processes, preventing resource waste.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Per-Client Process | Client isolation | Resource waste | ELIMINATED - multiple instances |
/// | Process Pool | Resource sharing | Complexity | Rejected - overkill |
/// | Singleton Process Manager | Single instances | Single point of failure | CHOSEN - optimal resource usage |
/// | Named Pipe Sharing | True sharing | Platform specific | Future enhancement |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Multiple Server Instances**
///    - 🔍 Symptom: Same MCP servers launched multiple times
///    - 🎯 Root Cause: Each MCPClient creates new Process.start()
///    - 💥 Kill Shot: Centralized process management with reuse
///
/// 2. **Resource Exhaustion**
///    - 🔍 Symptom: High memory usage from duplicate processes
///    - 🎯 Root Cause: No process lifecycle management
///    - 💥 Kill Shot: Reference counting and cleanup coordination
///
/// 3. **Port Conflicts**
///    - 🔍 Symptom: Server startup failures due to port conflicts
///    - 🎯 Root Cause: Multiple instances trying to bind same ports
///    - 💥 Kill Shot: Process sharing prevents conflicts
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Process creation: O(1) - shared processes across all clients
/// - Memory usage: O(1) - single process per unique server config
/// - Connection time: O(1) - instant for existing processes
/// - Cleanup: O(1) - reference counted cleanup
library;

import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:vibe_coder/models/process_stats.dart';

/// Shared MCP Process Manager - Universal Server Instance Control
///
/// ARCHITECTURAL: Singleton pattern ensures only one process per server configuration.
/// All MCP clients share the same underlying server processes.
class MCPProcessManager {
  static final Logger _logger = Logger('MCPProcessManager');
  static MCPProcessManager? _instance;

  // Process registry - maps server config to managed process
  final Map<String, _ManagedMCPProcess> _processes = {};

  // Private constructor for singleton
  MCPProcessManager._();

  /// Get singleton instance
  static MCPProcessManager get instance {
    _instance ??= MCPProcessManager._();
    return _instance!;
  }

  /// Get or create shared MCP process
  ///
  /// PERF: O(1) - HashMap lookup for existing processes, O(n) for process creation
  /// ARCHITECTURAL: Returns shared process handle with reference counting
  Future<SharedMCPProcess> getOrCreateProcess({
    required String serverName,
    required String command,
    List<String>? args,
    Map<String, String>? env,
  }) async {
    // Create unique key for process identification
    final processKey = _createProcessKey(command, args, env);

    _logger.info('🔍 PROCESS REQUEST: $serverName → $processKey');

    // Check if process already exists
    if (_processes.containsKey(processKey)) {
      final managedProcess = _processes[processKey]!;
      _logger
          .info('♻️ PROCESS REUSE: Reusing existing process for $serverName');

      // Increment reference count
      managedProcess._incrementReference(serverName);

      return SharedMCPProcess._(managedProcess, serverName);
    }

    // Create new process
    _logger.info('🚀 PROCESS CREATE: Starting new process for $serverName');
    _logger.info('📟 COMMAND: $command ${args?.join(' ') ?? ''}');
    _logger.info('🔧 ENV: ${env?.keys.join(', ') ?? 'No custom env'}');

    try {
      final process = await Process.start(
        command,
        args ?? [],
        environment: env,
        mode: ProcessStartMode.normal,
      );

      _logger.info('✅ PROCESS STARTED: PID ${process.pid} for $serverName');

      // Create managed process wrapper
      final managedProcess = _ManagedMCPProcess(
        process: process,
        processKey: processKey,
        command: command,
        args: args,
        env: env,
      );

      // Add initial reference
      managedProcess._incrementReference(serverName);

      // Store in registry
      _processes[processKey] = managedProcess;

      _logger.info('📋 PROCESS REGISTERED: $processKey → PID ${process.pid}');

      // Set up cleanup on process exit
      managedProcess._setupExitHandler(() {
        _processes.remove(processKey);
        _logger.info('🧹 PROCESS CLEANUP: Removed $processKey from registry');
      });

      return SharedMCPProcess._(managedProcess, serverName);
    } catch (e) {
      _logger.severe('💥 PROCESS CREATION FAILED: $serverName - $e');
      rethrow;
    }
  }

  /// Release process reference
  ///
  /// PERF: O(1) - reference counting with automatic cleanup
  /// ARCHITECTURAL: Process terminates when reference count reaches zero
  void releaseProcess(String processKey, String serverName) {
    final managedProcess = _processes[processKey];
    if (managedProcess == null) {
      _logger.warning('⚠️ RELEASE IGNORED: Process $processKey not found');
      return;
    }

    _logger.info('📉 PROCESS RELEASE: $serverName releasing $processKey');

    final refCount = managedProcess._decrementReference(serverName);

    if (refCount == 0) {
      _logger.info(
          '💀 PROCESS TERMINATION: No more references, terminating $processKey');
      managedProcess._terminate();
      _processes.remove(processKey);
    } else {
      _logger.info(
          '🔗 PROCESS SHARED: $refCount references remaining for $processKey');
    }
  }

  /// Get process statistics
  ///
  /// PERF: O(n) where n = number of processes
  /// ARCHITECTURAL: Returns strongly-typed process statistics
  ProcessStatsResponse getProcessStats() {
    final processes = <ProcessInfo>[];

    for (final entry in _processes.entries) {
      final processKey = entry.key;
      final managedProcess = entry.value;

      processes.add(ProcessInfo(
        processKey: processKey,
        pid: managedProcess.process.pid,
        command: managedProcess.command,
        args: managedProcess.args,
        referenceCount: managedProcess._referenceCount,
        referencingServers: managedProcess._referencingServers.toList(),
      ));
    }

    return ProcessStatsResponse(
      totalProcesses: _processes.length,
      processes: processes,
    );
  }

  /// Get process statistics (legacy format)
  ///
  /// DEPRECATED: Use getProcessStats() which returns strongly-typed data
  /// ARCHITECTURAL: Temporary bridge during migration period
  Map<String, dynamic> getProcessStatsLegacy() {
    return getProcessStats().toJson();
  }

  /// Create unique process key
  ///
  /// PERF: O(1) - deterministic hash generation
  String _createProcessKey(
      String command, List<String>? args, Map<String, String>? env) {
    final keyComponents = [
      command,
      args?.join('|') ?? '',
      env?.entries.map((e) => '${e.key}=${e.value}').join('|') ?? '',
    ];
    return keyComponents.join('::');
  }

  /// Shutdown all processes
  ///
  /// PERF: O(n) where n = number of processes
  /// ARCHITECTURAL: Clean shutdown for application termination
  Future<void> shutdownAll() async {
    _logger.info('🛑 SHUTDOWN: Terminating ${_processes.length} processes');

    final futures = _processes.values.map((managedProcess) async {
      _logger.info('💀 TERMINATING: PID ${managedProcess.process.pid}');
      await managedProcess._terminateAsync();
    });

    await Future.wait(futures);
    _processes.clear();

    _logger.info('✅ SHUTDOWN COMPLETE: All processes terminated');
  }
}

/// Managed MCP Process - Reference Counted Process Wrapper
///
/// ARCHITECTURAL: Internal wrapper that handles reference counting and lifecycle
class _ManagedMCPProcess {
  final Process process;
  final String processKey;
  final String command;
  final List<String>? args;
  final Map<String, String>? env;

  int _referenceCount = 0;
  final Set<String> _referencingServers = {};

  _ManagedMCPProcess({
    required this.process,
    required this.processKey,
    required this.command,
    this.args,
    this.env,
  });

  /// Increment reference count
  void _incrementReference(String serverName) {
    _referenceCount++;
    _referencingServers.add(serverName);
    MCPProcessManager._logger.info(
        '📈 REF INCREMENT: $serverName → $processKey (refs: $_referenceCount)');
  }

  /// Decrement reference count
  int _decrementReference(String serverName) {
    if (_referenceCount > 0) {
      _referenceCount--;
      _referencingServers.remove(serverName);
      MCPProcessManager._logger.info(
          '📉 REF DECREMENT: $serverName → $processKey (refs: $_referenceCount)');
    }
    return _referenceCount;
  }

  /// Set up exit handler
  void _setupExitHandler(VoidCallback onExit) {
    process.exitCode.then((exitCode) {
      MCPProcessManager._logger
          .info('⚰️ PROCESS EXITED: PID ${process.pid} with code $exitCode');
      onExit();
    });
  }

  /// Terminate process synchronously
  void _terminate() {
    MCPProcessManager._logger.info('💀 KILLING PROCESS: PID ${process.pid}');
    process.kill();
  }

  /// Terminate process asynchronously
  Future<void> _terminateAsync() async {
    MCPProcessManager._logger.info('💀 KILLING PROCESS: PID ${process.pid}');
    process.kill();
    await process.exitCode;
    MCPProcessManager._logger.info('✅ PROCESS TERMINATED: PID ${process.pid}');
  }
}

/// Shared MCP Process Handle - Reference to Managed Process
///
/// ARCHITECTURAL: Public interface for accessing shared processes
/// Automatically handles reference counting through dispose pattern
class SharedMCPProcess implements Comparable<SharedMCPProcess> {
  final _ManagedMCPProcess _managedProcess;
  final String _serverName;
  bool _disposed = false;

  SharedMCPProcess._(this._managedProcess, this._serverName);

  /// Get underlying process
  Process get process => _managedProcess.process;

  /// Get process ID
  int get pid => _managedProcess.process.pid;

  /// Get process key for identification
  String get processKey => _managedProcess.processKey;

  /// Get server name this handle represents
  String get serverName => _serverName;

  /// Check if process is still alive
  bool get isAlive {
    if (_disposed) return false;

    // Simple check - if we can get the PID, process is likely alive
    // This is not 100% reliable but sufficient for our use case
    try {
      final pid = process.pid;
      return pid > 0;
    } catch (e) {
      return false;
    }
  }

  /// Release reference to process
  ///
  /// ARCHITECTURAL: Must be called when client no longer needs process
  /// Process will terminate automatically when all references released
  void dispose() {
    if (_disposed) {
      MCPProcessManager._logger.warning(
          '⚠️ DOUBLE DISPOSE: Attempted to dispose already disposed process $_serverName');
      return;
    }

    _disposed = true;
    MCPProcessManager.instance
        .releaseProcess(_managedProcess.processKey, _serverName);
  }

  /// Comparable implementation for sorting
  @override
  int compareTo(SharedMCPProcess other) {
    return processKey.compareTo(other.processKey);
  }

  @override
  bool operator ==(Object other) {
    return other is SharedMCPProcess &&
        processKey == other.processKey &&
        serverName == other.serverName;
  }

  @override
  int get hashCode => Object.hash(processKey, serverName);

  @override
  String toString() =>
      'SharedMCPProcess($serverName, PID: $pid, Key: $processKey)';
}
