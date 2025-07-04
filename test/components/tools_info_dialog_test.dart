import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/components/common/dialogs/tools_info_dialog.dart';
import 'package:vibe_coder/models/mcp_server_info.dart';

void main() {
  group('ToolsInfoDialog Tests', () {
    // Test data setup using strongly-typed models
    final mockEmptyMcpInfo = MCPServerInfoResponse(
      servers: {},
      toolCount: 0,
      connectedCount: 0,
      totalCount: 0,
    );

    final mockMcpInfoWithServers = MCPServerInfoResponse(
      servers: {
        'filesystem': MCPServerInfo(
          name: 'filesystem',
          displayName: 'filesystem',
          status: 'connected',
          type: 'stdio',
          toolCount: 11,
          resourceCount: 0,
          promptCount: 0,
          tools: [
            MCPToolInfo(
              name: 'read_file',
              description: 'Read file contents',
              uniqueId: 'filesystem:read_file',
            ),
            MCPToolInfo(
              name: 'write_file',
              description: 'Write file contents',
              uniqueId: 'filesystem:write_file',
            ),
            MCPToolInfo(
              name: 'list_files',
              description: 'List directory contents',
              uniqueId: 'filesystem:list_files',
            ),
          ],
          supported: true,
        ),
        'memory': MCPServerInfo(
          name: 'memory',
          displayName: 'memory',
          status: 'disconnected',
          type: 'stdio',
          toolCount: 0,
          resourceCount: 0,
          promptCount: 0,
          tools: [],
          supported: true,
          reason: 'Connection failed: Server not found',
        ),
      },
      toolCount: 11,
      connectedCount: 1,
      totalCount: 2,
    );

    testWidgets('renders correctly with empty MCP info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolsInfoDialog(mcpInfo: mockEmptyMcpInfo),
          ),
        ),
      );

      expect(find.byType(ToolsInfoDialog), findsOneWidget);
      expect(find.text('MCP Servers & Tools'), findsOneWidget);
      expect(find.text('Total Tools: 0'), findsOneWidget);
      expect(find.text('Connected: 0/0'), findsOneWidget);
      expect(find.text('No MCP servers configured'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('renders correctly with MCP server info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolsInfoDialog(mcpInfo: mockMcpInfoWithServers),
          ),
        ),
      );

      expect(find.byType(ToolsInfoDialog), findsOneWidget);
      expect(find.text('MCP Servers & Tools'), findsOneWidget);
      expect(find.text('Total Tools: 11'), findsOneWidget);
      expect(find.text('Connected: 1/2'), findsOneWidget);

      // Check server names are displayed
      expect(find.text('filesystem'), findsOneWidget);
      expect(find.text('memory'), findsOneWidget);

      // Check status indicators
      expect(find.byIcon(Icons.cloud_done), findsOneWidget); // Connected server
      expect(
          find.byIcon(Icons.cloud_off), findsOneWidget); // Disconnected server

      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('close button dismisses dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    ToolsInfoDialog.show(context, mockEmptyMcpInfo),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(ToolsInfoDialog), findsOneWidget);

      // Tap close button
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(ToolsInfoDialog), findsNothing);
    });

    testWidgets('static show method works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    ToolsInfoDialog.show(context, mockMcpInfoWithServers),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Initially no dialog
      expect(find.byType(ToolsInfoDialog), findsNothing);

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should appear with server info
      expect(find.byType(ToolsInfoDialog), findsOneWidget);
      expect(find.text('filesystem'), findsOneWidget);
      expect(find.text('memory'), findsOneWidget);
    });

    testWidgets('dialog layout and styling is correct', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolsInfoDialog(mcpInfo: mockMcpInfoWithServers),
          ),
        ),
      );

      // Check dialog structure
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));

      // Check stats container
      final statContainer = find.byType(Container).first;
      expect(statContainer, findsOneWidget);

      // Check server cards structure
      expect(find.byType(Card), findsNWidgets(2)); // Two servers
      expect(find.byType(ExpansionTile), findsNWidgets(2)); // Expandable tiles
    });

    testWidgets('expansion tiles work correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolsInfoDialog(mcpInfo: mockMcpInfoWithServers),
          ),
        ),
      );

      // Find the filesystem server expansion tile
      final filesystemTile = find.widgetWithText(ExpansionTile, 'filesystem');
      expect(filesystemTile, findsOneWidget);

      // Tap to expand
      await tester.tap(filesystemTile);
      await tester.pumpAndSettle();

      // Check for tool details (should be visible after expansion)
      expect(find.text('Available Tools:'), findsOneWidget);
      expect(find.text('read_file'), findsOneWidget);
      expect(find.text('write_file'), findsOneWidget);
      expect(find.text('list_files'), findsOneWidget);
    });

    testWidgets('displays connection status correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolsInfoDialog(mcpInfo: mockMcpInfoWithServers),
          ),
        ),
      );

      // Check connected server status
      expect(find.text('CONNECTED'), findsOneWidget);
      expect(find.text('DISCONNECTED'), findsOneWidget);

      // Check failure reason for disconnected server
      expect(find.text('Connection failed: Server not found'), findsOneWidget);
    });
  });
}
