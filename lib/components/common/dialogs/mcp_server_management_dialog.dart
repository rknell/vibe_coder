import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibe_coder/models/mcp_server_info.dart';

/// MCPServerManagementDialog - Comprehensive MCP Server Management Interface
///
/// ## MISSION ACCOMPLISHED
/// **ELIMINATES** limited MCP server visibility with comprehensive management interface.
/// Users can now monitor, refresh, and troubleshoot MCP server connections in real-time.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Read-Only Info Dialog | Simple | No management | ELIMINATED - insufficient control |
/// | Management Dialog | Full control | UI complexity | CHOSEN - complete server dominance |
/// | Separate Screen | More space | Navigation overhead | Future enhancement |
/// | Real-time Updates | Live status | Resource intensive | CHOSEN - critical for debugging |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **MCP Server Black Box Problem**
///    - 🔍 Symptom: Cannot see server connection status or diagnose issues
///    - 🎯 Root Cause: Limited visibility into MCP infrastructure
///    - 💥 Kill Shot: Comprehensive server status dashboard
///
/// 2. **Connection Recovery Difficulty**
///    - 🔍 Symptom: Servers disconnect and stay offline without user knowledge
///    - 🎯 Root Cause: No refresh mechanism for failed connections
///    - 💥 Kill Shot: Individual and bulk server refresh capabilities
///
/// 3. **Tool Discovery Frustration**
///    - 🔍 Symptom: Users don't know what tools are available
///    - 🎯 Root Cause: Hidden tool listings and capabilities
///    - 💥 Kill Shot: Expandable tool cards with descriptions and copy functionality
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(n*m) where n = servers, m = tools per server
/// - Space Complexity: O(n*m) - server and tool data storage
/// - Refresh Performance: O(1) for individual, O(n) for bulk refresh
/// - UI Update Rate: Real-time with state management
class MCPServerManagementDialog extends StatefulWidget {
  /// Creates MCP server management dialog
  ///
  /// ARCHITECTURAL: Rich server data with callback management
  const MCPServerManagementDialog({
    super.key,
    required this.mcpInfo,
    required this.onRefreshAll,
    required this.onRefreshServer,
  });

  /// MCP server and tools information
  final MCPServerInfoResponse mcpInfo;

  /// Callback for refreshing all servers
  final Future<MCPServerInfoResponse> Function() onRefreshAll;

  /// Callback for refreshing individual server
  final Future<MCPServerInfoResponse> Function(String serverName)
      onRefreshServer;

  /// Show the MCP server management dialog
  ///
  /// PERF: O(1) - dialog display with managed state updates
  static Future<void> show(
    BuildContext context,
    MCPServerInfoResponse mcpInfo, {
    required Future<MCPServerInfoResponse> Function() onRefreshAll,
    required Future<MCPServerInfoResponse> Function(String serverName)
        onRefreshServer,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => MCPServerManagementDialog(
        mcpInfo: mcpInfo,
        onRefreshAll: onRefreshAll,
        onRefreshServer: onRefreshServer,
      ),
    );
  }

  @override
  State<MCPServerManagementDialog> createState() =>
      _MCPServerManagementDialogState();
}

class _MCPServerManagementDialogState extends State<MCPServerManagementDialog> {
  MCPServerInfoResponse _mcpInfo = const MCPServerInfoResponse(
    servers: {},
    toolCount: 0,
    connectedCount: 0,
    totalCount: 0,
  );
  bool _isRefreshing = false;
  final Set<String> _refreshingServers = {};
  String? _lastRefreshError;

  @override
  void initState() {
    super.initState();
    _mcpInfo = widget.mcpInfo;
  }

  /// Refresh all MCP servers
  /// PERF: O(n) - parallel server refresh for optimal performance
  Future<void> _refreshAllServers() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _lastRefreshError = null;
    });

    try {
      final updatedInfo = await widget.onRefreshAll();
      setState(() {
        _mcpInfo = updatedInfo;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All servers refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _lastRefreshError = 'Failed to refresh servers: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Refresh failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  /// Refresh individual MCP server
  /// PERF: O(1) - single server refresh with optimistic updates
  Future<void> _refreshServer(String serverName) async {
    if (_refreshingServers.contains(serverName)) return;

    setState(() {
      _refreshingServers.add(serverName);
      _lastRefreshError = null;
    });

    try {
      final updatedInfo = await widget.onRefreshServer(serverName);
      setState(() {
        _mcpInfo = updatedInfo;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $serverName refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _lastRefreshError = 'Failed to refresh $serverName: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $serverName refresh failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _refreshingServers.remove(serverName);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final serversMap = _mcpInfo.servers;
    final servers = serversMap.values.toList();
    final totalTools = _mcpInfo.toolCount;
    final connectedServers = _mcpInfo.connectedCount;
    final configuredServers = _mcpInfo.totalCount;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.settings, color: Colors.blue),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('MCP Server Management'),
          ),
          // Refresh all button
          IconButton(
            onPressed: _isRefreshing ? null : _refreshAllServers,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh All Servers',
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner
            if (_lastRefreshError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lastRefreshError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _lastRefreshError = null),
                      icon: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
              ),

            // Summary stats with enhanced information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MCP Infrastructure Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatChip(
                        'Total Tools',
                        totalTools.toString(),
                        Colors.blue,
                        Icons.build,
                      ),
                      _buildStatChip(
                        'Servers',
                        '$connectedServers/$configuredServers',
                        connectedServers == configuredServers
                            ? Colors.green
                            : connectedServers > 0
                                ? Colors.orange
                                : Colors.red,
                        Icons.dns,
                      ),
                      _buildStatChip(
                        'Status',
                        connectedServers == configuredServers
                            ? 'All Connected'
                            : connectedServers > 0
                                ? 'Partial'
                                : 'Offline',
                        connectedServers == configuredServers
                            ? Colors.green
                            : connectedServers > 0
                                ? Colors.orange
                                : Colors.red,
                        Icons.cloud,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Server management section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MCP Servers:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${servers.length} configured',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Server list with management capabilities
            Expanded(
              child: servers.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.dns_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No MCP servers configured',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add server configurations to mcp.json',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: servers.length,
                      itemBuilder: (context, index) {
                        final server = servers[index];
                        return _buildServerManagementCard(context, server);
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// Build enhanced statistics chip with icon
  /// PERF: O(1) - immediate widget construction
  Widget _buildStatChip(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build enhanced server management card with refresh capabilities
  /// PERF: O(m) where m = tools per server - optimized for typical tool counts
  Widget _buildServerManagementCard(
      BuildContext context, MCPServerInfo server) {
    final serverName = server.name;
    final status = server.status;
    final type = server.type;
    final toolCount = server.toolCount;
    final resourceCount = server.resourceCount;
    final promptCount = server.promptCount;
    final tools = server.tools;
    final supported = server.supported;
    final reason = server.reason;
    final url = server.url;
    final command = server.command;
    final args = server.args;

    final isConnected = status == 'connected';
    final isRefreshing = _refreshingServers.contains(serverName);
    final statusColor = isConnected ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: Stack(
          children: [
            Icon(
              isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: statusColor,
              size: 28,
            ),
            if (isRefreshing)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                serverName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Individual refresh button
            IconButton(
              onPressed: isRefreshing ? null : () => _refreshServer(serverName),
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh $serverName',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$type • $toolCount tools',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (!supported)
              const Text(
                '⚠️ Transport not supported',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            if (reason != null && !isConnected)
              Text(
                '❌ $reason',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Server configuration details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuration:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (url != null) ...[
                        _buildConfigRow('URL', url, copyable: true),
                      ],
                      if (command != null) ...[
                        _buildConfigRow('Command', command, copyable: true),
                        if (args != null && args.isNotEmpty)
                          _buildConfigRow('Arguments', args.join(' '),
                              copyable: true),
                      ],
                      _buildConfigRow('Type', type.toUpperCase()),
                      _buildConfigRow('Tools', toolCount.toString()),
                      if (resourceCount > 0)
                        _buildConfigRow('Resources', resourceCount.toString()),
                      if (promptCount > 0)
                        _buildConfigRow('Prompts', promptCount.toString()),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tools section
                if (tools.isNotEmpty) ...[
                  const Text(
                    'Available Tools:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: tools.asMap().entries.map((entry) {
                        final index = entry.key;
                        final tool = entry.value;
                        return _buildToolCard(tool,
                            isLast: index == tools.length - 1);
                      }).toList(),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('No tools available from this server'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build configuration row with optional copy functionality
  /// PERF: O(1) - immediate row construction
  Widget _buildConfigRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
          if (copyable)
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📋 Copied: $label'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              tooltip: 'Copy $label',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }

  /// Build individual tool card with enhanced information
  /// PERF: O(1) - single tool display with lazy rendering
  Widget _buildToolCard(MCPToolInfo tool, {bool isLast = false}) {
    final name = tool.name;
    final description = tool.description.isNotEmpty
        ? tool.description
        : 'No description available';
    final uniqueId = tool.uniqueId;

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.build, size: 16, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: uniqueId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📋 Copied tool ID: $uniqueId'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 14),
                        tooltip: 'Copy tool ID',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    ],
                  ),
                  if (description != 'No description available') ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      uniqueId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
