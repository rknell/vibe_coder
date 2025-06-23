/// 📊 PROCESS STATISTICS MODEL
///
/// ARCHITECTURAL: Strongly-typed data model for MCP process statistics
/// Replaces Map<String, dynamic> returns with type-safe structures
/// Provides comprehensive process status and reference information
library;

/// Individual process information
class ProcessInfo {
  final String processKey;
  final int pid;
  final String command;
  final List<String>? args;
  final int referenceCount;
  final List<String> referencingServers;

  const ProcessInfo({
    required this.processKey,
    required this.pid,
    required this.command,
    this.args,
    required this.referenceCount,
    required this.referencingServers,
  });

  Map<String, dynamic> toJson() => {
        'processKey': processKey,
        'pid': pid,
        'command': command,
        'args': args,
        'referenceCount': referenceCount,
        'referencingServers': referencingServers,
      };

  factory ProcessInfo.fromJson(Map<String, dynamic> json) => ProcessInfo(
        processKey: json['processKey'] as String,
        pid: json['pid'] as int,
        command: json['command'] as String,
        args: (json['args'] as List<dynamic>?)?.cast<String>(),
        referenceCount: json['referenceCount'] as int,
        referencingServers:
            (json['referencingServers'] as List<dynamic>).cast<String>(),
      );
}

/// Complete process statistics response
///
/// ARCHITECTURAL: Top-level container for all process statistics
/// Provides summary counts and individual process details
class ProcessStatsResponse {
  final int totalProcesses;
  final List<ProcessInfo> processes;

  const ProcessStatsResponse({
    required this.totalProcesses,
    required this.processes,
  });

  /// Convert to JSON (for serialization)
  Map<String, dynamic> toJson() => {
        'activeProcesses': processes.map((p) => p.toJson()).toList(),
        'totalProcesses': totalProcesses,
        'uniqueProcesses': processes.length,
        'duplicateShares': processes.where((p) => p.referenceCount > 1).length,
      };

  /// Create from JSON (for deserialization)
  factory ProcessStatsResponse.fromJson(Map<String, dynamic> json) {
    return ProcessStatsResponse(
      totalProcesses: json['totalProcesses'] as int,
      processes: (json['activeProcesses'] as List<dynamic>)
          .map((p) => ProcessInfo.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convenience getters for common queries
  List<ProcessInfo> get activeProcesses => processes;

  List<ProcessInfo> get sharedProcesses =>
      processes.where((p) => p.referenceCount > 1).toList();

  List<ProcessInfo> get singleUseProcesses =>
      processes.where((p) => p.referenceCount == 1).toList();

  /// Get total reference count across all processes
  int get totalReferences =>
      processes.fold(0, (sum, process) => sum + process.referenceCount);

  /// Get process by PID
  ProcessInfo? getProcessByPid(int pid) {
    try {
      return processes.firstWhere((p) => p.pid == pid);
    } catch (e) {
      return null;
    }
  }

  /// Get processes by server name
  List<ProcessInfo> getProcessesByServer(String serverName) => processes
      .where((p) => p.referencingServers.contains(serverName))
      .toList();
}
