import 'package:flutter/material.dart';

/// ToolsInfoDialog - Available MCP Servers and Tools Display
///
/// ## MISSION ACCOMPLISHED
/// Eliminates simple tool list display with comprehensive MCP server status dashboard.
/// Shows server connection status, available tools, and configuration details.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Simple Tool List | Easy | No server context | Rejected - insufficient information |
/// | Server+Tool Matrix | Comprehensive | UI complexity | CHOSEN - maximum battlefield intel |
/// | Tabbed Interface | Organized | Extra navigation | Considered for future enhancement |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(n*m) where n = servers, m = tools per server
/// - Space Complexity: O(n*m) - server and tool data storage
/// - Rebuild Frequency: Only when MCP status changes
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Information Scarcity**
///    - 🔍 Symptom: "No tools available" with no context
///    - 🎯 Root Cause: Hidden server configuration and connection status
///    - 💥 Kill Shot: Comprehensive server status dashboard
///
/// 2. **MCP Debugging Difficulty**
///    - 🔍 Symptom: Cannot diagnose MCP connection issues
///    - 🎯 Root Cause: No visibility into server states
///    - 💥 Kill Shot: Connection status + failure reasons display
class ToolsInfoDialog extends StatelessWidget {
  /// Creates a tools info dialog with MCP server information
  ///
  /// ARCHITECTURAL: Rich server data injected via constructor
  const ToolsInfoDialog({
    super.key,
    required this.mcpInfo,
  });

  /// MCP server and tools information
  final Map<String, dynamic> mcpInfo;

  /// Show the MCP tools info dialog
  ///
  /// PERF: O(1) - dialog display with O(n*m) content rendering
  static Future<void> show(BuildContext context, Map<String, dynamic> mcpInfo) {
    return showDialog<void>(
      context: context,
      builder: (context) => ToolsInfoDialog(mcpInfo: mcpInfo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servers = (mcpInfo['servers'] as List<dynamic>?) ?? [];
    final totalTools = mcpInfo['totalTools'] as int? ?? 0;
    final connectedServers = mcpInfo['connectedServers'] as int? ?? 0;
    final configuredServers = mcpInfo['configuredServers'] as int? ?? 0;

    return AlertDialog(
      title: const Text('MCP Servers & Tools'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildStatChip(
                      'Total Tools', totalTools.toString(), Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      'Connected',
                      '$connectedServers/$configuredServers',
                      connectedServers > 0 ? Colors.green : Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Server list
            const Text(
              'MCP Servers:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: servers.isEmpty
                  ? const Center(child: Text('No MCP servers configured'))
                  : ListView.builder(
                      itemCount: servers.length,
                      itemBuilder: (context, index) {
                        final server = servers[index] as Map<String, dynamic>;
                        return _buildServerCard(context, server);
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

  /// Build a statistics chip
  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Build a server information card
  Widget _buildServerCard(BuildContext context, Map<String, dynamic> server) {
    final serverName = server['name'] as String? ?? 'Unknown';
    final status = server['status'] as String? ?? 'unknown';
    final type = server['type'] as String? ?? 'unknown';
    final toolCount = server['toolCount'] as int? ?? 0;
    final tools = (server['tools'] as List<dynamic>?) ?? [];
    final supported = server['supported'] as bool? ?? false;
    final reason = server['reason'] as String?;
    final url = server['url'] as String?;

    final isConnected = status == 'connected';
    final statusColor = isConnected ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          isConnected ? Icons.cloud_done : Icons.cloud_off,
          color: statusColor,
        ),
        title: Text(
          serverName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$type • $toolCount tools'),
              ],
            ),
            if (!supported)
              const Text(
                'Not supported',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            if (reason != null && !isConnected)
              Text(
                reason,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Server details
                if (url != null) ...[
                  Text('URL: $url',
                      style: const TextStyle(fontFamily: 'monospace')),
                  const SizedBox(height: 8),
                ],

                // Tools list
                if (tools.isNotEmpty) ...[
                  const Text(
                    'Available Tools:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...tools.map((tool) {
                    final toolData = tool as Map<String, dynamic>;
                    final name = toolData['name'] as String? ?? 'Unknown';
                    final description =
                        toolData['description'] as String? ?? 'No description';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.build, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                if (description != 'No description')
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ] else ...[
                  const Text('No tools available from this server'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
