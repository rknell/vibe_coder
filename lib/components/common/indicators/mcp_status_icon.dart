import 'package:flutter/material.dart';
import 'package:vibe_coder/models/mcp_server_model.dart';
import 'package:vibe_coder/services/services.dart';

/// MCP Status Icon Component
///
/// ## MISSION ACCOMPLISHED
/// **REPLACES DIALOG-BASED MCP STATUS** with compact, non-intrusive status indicator
/// Shows loading state, connection counts, and tool availability in a single icon
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Dialog UI | Full detail | Space consuming | ELIMINATED - too much real estate |
/// | Status Banner | Always visible | Takes up space | REJECTED - persistent UI clutter |
/// | Status Icon | Compact, elegant | Limited detail | CHOSEN - perfect balance |
/// | Tooltip Only | Zero space | Hidden info | REJECTED - insufficient feedback |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Space Consumption Elimination**
///    - 🔍 Symptom: Dialog takes up entire screen real estate
///    - 🎯 Root Cause: Modal dialog architecture for status display
///    - 💥 Kill Shot: Compact icon with layered information display
///
/// 2. **Persistent Visibility Achievement**
///    - 🔍 Symptom: Status hidden until user clicks dialog
///    - 🎯 Root Cause: Information buried behind interaction
///    - 💥 Kill Shot: Always-visible status with visual indicators
///
/// 3. **Non-Dismissible Status Problem**
///    - 🔍 Symptom: Dialog can't be cleared easily
///    - 🎯 Root Cause: Modal dialog requires explicit dismissal
///    - 💥 Kill Shot: Icon-based status with automatic state updates
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Status update: O(1) - direct icon state change
/// - Tooltip generation: O(n) where n = number of servers (only on hover)
/// - UI rendering: O(1) - single icon with overlays
/// - Memory usage: O(1) - minimal state storage
class MCPStatusIcon extends StatelessWidget {
  final bool isServiceInitialized;
  final VoidCallback? onTap;

  const MCPStatusIcon({
    super.key,
    required this.isServiceInitialized,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isServiceInitialized) {
      return IconButton(
        onPressed: null,
        icon: const Icon(Icons.settings_outlined),
        tooltip: 'MCP Service Initializing...',
      );
    }

    return ListenableBuilder(
      listenable: services.mcpService,
      builder: (context, child) {
        final mcpService = services.mcpService;
        final allServers = mcpService.data;
        final connectedServers = mcpService.connectedServers;
        final connectingServers = allServers
            .where((s) => s.status == MCPServerStatus.connecting)
            .toList();
        final errorServers =
            allServers.where((s) => s.status == MCPServerStatus.error).toList();
        final totalTools = mcpService.getAllTools().length;

        // Determine primary status
        final isConnecting = connectingServers.isNotEmpty;
        final hasErrors = errorServers.isNotEmpty;
        final hasConnected = connectedServers.isNotEmpty;

        // Icon and color selection based on status
        IconData iconData;
        Color? iconColor;

        if (isConnecting) {
          iconData = Icons.settings_ethernet;
          iconColor = Colors.orange;
        } else if (hasErrors && !hasConnected) {
          iconData = Icons.settings_remote;
          iconColor = Colors.red;
        } else if (hasConnected) {
          iconData = Icons.settings_input_antenna;
          iconColor = Colors.green;
        } else {
          iconData = Icons.settings_outlined;
          iconColor = Colors.grey;
        }

        // Generate tooltip with detailed status
        final tooltipText = _generateTooltipText(
          connectedServers: connectedServers,
          connectingServers: connectingServers,
          errorServers: errorServers,
          totalServers: allServers,
          totalTools: totalTools,
        );

        return Stack(
          children: [
            IconButton(
              onPressed: onTap,
              icon: Icon(iconData, color: iconColor),
              tooltip: tooltipText,
            ),

            // Connection indicator badge
            if (isConnecting)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

            // Connected count badge
            if (hasConnected && !isConnecting)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    '${connectedServers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Error indicator badge
            if (hasErrors)
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Generate detailed tooltip text with server and tool information
  /// PERF: O(n) where n = number of servers (only called on hover)
  String _generateTooltipText({
    required List<MCPServerModel> connectedServers,
    required List<MCPServerModel> connectingServers,
    required List<MCPServerModel> errorServers,
    required List<MCPServerModel> totalServers,
    required int totalTools,
  }) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('MCP Infrastructure Status');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━');

    // Connection summary
    if (connectingServers.isNotEmpty) {
      buffer.writeln('🔄 Connecting: ${connectingServers.length} server(s)');
    }

    if (connectedServers.isNotEmpty) {
      buffer.writeln(
          '✅ Connected: ${connectedServers.length}/${totalServers.length} server(s)');
      buffer.writeln('🛠️ Available Tools: $totalTools');
    }

    if (errorServers.isNotEmpty) {
      buffer.writeln('❌ Failed: ${errorServers.length} server(s)');
    }

    if (connectedServers.isEmpty && connectingServers.isEmpty) {
      buffer.writeln('⏸️ No active connections');
    }

    // Connected servers detail
    if (connectedServers.isNotEmpty) {
      buffer.writeln('\nConnected Servers:');
      for (final server in connectedServers.take(5)) {
        // Limit to prevent tooltip overflow
        final toolCount = server.availableTools.length;
        buffer.writeln('• ${server.name} ($toolCount tools)');
      }
      if (connectedServers.length > 5) {
        buffer.writeln('• ... and ${connectedServers.length - 5} more');
      }
    }

    // Failed servers (if any)
    if (errorServers.isNotEmpty) {
      buffer.writeln('\nFailed Servers:');
      for (final server in errorServers.take(3)) {
        // Limit to prevent tooltip overflow
        buffer.writeln('• ${server.name}');
      }
      if (errorServers.length > 3) {
        buffer.writeln('• ... and ${errorServers.length - 3} more');
      }
    }

    buffer.writeln('\nClick for server management');

    return buffer.toString().trim();
  }
}
