import 'package:flutter/material.dart';
import '../../../models/mcp_server_info.dart';

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
///
/// ## MISSION ACCOMPLISHED
/// Eliminated functional widget builders and extracted them into proper components
/// following flutter_architecture.mdc warrior protocols
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |-----|-----|---|----|
/// | Component Extraction | Reusable, maintainable, testable | More files | Architectural compliance |
/// | Functional Builders | Quick to write | Maintenance nightmare | BANNED by warrior protocols |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(n) where n = number of servers
/// - Space Complexity: O(n) for server data
/// - Rebuild Frequency: On server status changes
class ToolsInfoDialog extends StatelessWidget {
  /// Creates a tools info dialog with MCP server information
  ///
  /// ARCHITECTURAL: Rich server data injected via constructor
  const ToolsInfoDialog({
    super.key,
    required this.mcpInfo,
  });

  /// MCP server and tools information
  final MCPServerInfoResponse mcpInfo;

  /// Show the MCP tools info dialog
  ///
  /// PERF: O(1) - dialog display with O(n*m) content rendering
  static Future<void> show(
      BuildContext context, MCPServerInfoResponse mcpInfo) {
    return showDialog<void>(
      context: context,
      builder: (context) => ToolsInfoDialog(mcpInfo: mcpInfo),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get MCP server info data from your service
    final servers = mcpInfo.servers.values.toList();
    final totalTools = mcpInfo.toolCount;
    final connectedServers = mcpInfo.connectedCount;
    final configuredServers = mcpInfo.totalCount;

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
                  ToolsInfoStatChip(
                    label: 'Total Tools',
                    value: totalTools.toString(),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  ToolsInfoStatChip(
                    label: 'Connected',
                    value: '$connectedServers/$configuredServers',
                    color: connectedServers > 0 ? Colors.green : Colors.orange,
                  ),
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
                        final server = servers[index];
                        return ToolsInfoServerCard(server: server);
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
}

/// Tools Info Stat Chip Component
///
/// ## MISSION ACCOMPLISHED
/// Extracted from functional widget builder to proper component
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - Static chip rendering
/// - Space Complexity: O(1) - Fixed chip layout
/// - Rebuild Frequency: On value changes
class ToolsInfoStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const ToolsInfoStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// Tools Info Server Card Component
///
/// ## MISSION ACCOMPLISHED
/// Extracted from functional widget builder to proper component
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(n) where n = number of tools per server
/// - Space Complexity: O(n) for tool data
/// - Rebuild Frequency: On server status changes
class ToolsInfoServerCard extends StatelessWidget {
  final MCPServerInfo server;

  const ToolsInfoServerCard({
    super.key,
    required this.server,
  });

  @override
  Widget build(BuildContext context) {
    final serverName = server.name;
    final status = server.status;
    final type = server.type;
    final toolCount = server.toolCount;
    final tools = server.tools;
    final supported = server.supported;
    final reason = server.reason;
    final url = server.url;

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
                    final name = tool.name;
                    final description = tool.description.isNotEmpty
                        ? tool.description
                        : 'No description';

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
                  }),
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
