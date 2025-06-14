# Model Context Protocol (MCP) Integration

This project has been updated to use the **Model Context Protocol (MCP)** for tool interactions, replacing the previous broken tools implementation.

## ⚔️ CONQUEST REPORT: MCP INTEGRATION

### 🏆 MISSION ACCOMPLISHED
Eliminated the broken tools system and replaced it with industry-standard MCP protocol integration, providing scalable tool access across multiple servers.

### ⚔️ STRATEGIC DECISIONS

| Option | Power-Ups | Weaknesses | Victory Reason |
|--------|-----------|------------|----------------|
| Fix existing tools | Simple, no API changes | Limited, fragile, non-standard | Rejected - technical debt |
| Custom tool protocol | Full control, tailored | Maintenance burden, compatibility | Rejected - reinventing wheel |
| **MCP Integration** | Industry standard, extensible, future-proof | Learning curve, external deps | **CHOSEN - Standards compliance** |

### 💀 BOSS FIGHTS DEFEATED

1. **Undefined ToolType/ToolFactory**
   - 🔍 Symptom: Compilation errors, missing types
   - 🎯 Root Cause: Incomplete tool system implementation
   - 💥 Kill Shot: Complete MCP integration with proper models

2. **Broken Tool Architecture**
   - 🔍 Symptom: BaseTool abstract class with no implementations
   - 🎯 Root Cause: Abandoned tool development
   - 💥 Kill Shot: MCP client-server architecture

3. **No Tool Discovery Mechanism**
   - 🔍 Symptom: No way to load external tools
   - 🎯 Root Cause: Missing configuration system
   - 💥 Kill Shot: JSON-based MCP server configuration

## What is MCP?

Model Context Protocol (MCP) is an open protocol that standardizes how applications provide context to LLMs. It acts like a "USB-C port for AI applications" - a standardized way to connect AI models to different data sources and tools.

## Architecture

### Core Components

- **MCPClient**: JSON-RPC 2.0 client for communicating with MCP servers
- **MCPManager**: Manages multiple MCP clients and configurations
- **Agent**: Updated to use MCP instead of broken tools system

### MCP Features Supported

- ✅ **Tools**: Execute functions via MCP servers
- ✅ **Resources**: Access data and content
- ✅ **Prompts**: Use templated messages and workflows
- ✅ **JSON-RPC 2.0**: Standard protocol communication
- ✅ **Multiple Servers**: Connect to multiple MCP servers simultaneously
- ✅ **HTTP/SSE Transport**: Support for web-based MCP servers
- ⚠️ **STDIO Transport**: Not yet implemented (requires process management)

## Configuration

### MCP Configuration File (`mcp.json`)

Create a `mcp.json` file in your project root:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-filesystem", "/path/to/directory"],
      "env": {
        "DEBUG": "true"
      }
    },
    "web-search": {
      "type": "sse",
      "url": "http://localhost:3000/sse",
      "env": {
        "API_KEY": "your-api-key"
      }
    }
  }
}
```

### Server Types

1. **STDIO Servers** (not yet implemented):
   ```json
   {
     "command": "node",
     "args": ["server.js"],
     "env": {"KEY": "value"}
   }
   ```

2. **HTTP/SSE Servers**:
   ```json
   {
     "type": "sse",
     "url": "http://localhost:3000/sse",
     "env": {"API_KEY": "value"}
   }
   ```

## Usage

### Creating an Agent with MCP

```dart
final agent = Agent(
  systemPrompt: "You are a helpful assistant",
  name: "MyAgent",
  mcpConfigPath: "mcp.json",  // Path to MCP configuration
);

// MCP will be automatically initialized
```

### Using MCP Tools

```dart
// Get available tools
final tools = agent.getAvailableTools();
print('Available tools: ${tools.map((t) => t.uniqueId).join(', ')}');

// Call a tool
final result = await agent.callMCPTool(
  toolName: "read_file",
  arguments: {"path": "/path/to/file.txt"},
);

print('Tool result: ${result.content.first.text}');
```

### Using MCP Resources

```dart
// Get available resources
final resources = await agent.getAvailableResources();

// Access a resource (handled by MCPManager)
final content = await agent.mcpManager.getResource(
  serverName: "filesystem",
  uri: "file:///path/to/document.md",
);
```

## Available MCP Servers

Popular MCP servers you can use:

- **@modelcontextprotocol/server-filesystem**: File system operations
- **@modelcontextprotocol/server-github**: GitHub API integration
- **@modelcontextprotocol/server-sqlite**: SQLite database operations
- **@modelcontextprotocol/server-postgres**: PostgreSQL operations
- **Custom servers**: Build your own using MCP SDKs

## Security Considerations

⚠️ **SECURITY FORTRESS PROTOCOLS**:

- **Environment Variables**: All secrets must be in env vars, never hardcoded
- **Validation**: All MCP server responses are validated
- **Error Handling**: Proper error boundaries prevent system crashes
- **Authentication**: MCP servers can implement their own auth

## Error Handling

The system includes comprehensive error handling:

```dart
try {
  final result = await agent.callMCPTool(
    toolName: "risky_operation",
    arguments: {"data": "test"},
  );
} on MCPException catch (e) {
  // Handle MCP-specific errors
  logger.severe('MCP Error: ${e.message}');
} catch (e) {
  // Handle general errors
  logger.severe('General Error: $e');
}
```

## Migration from Old Tools

### Before (Broken)
```dart
// ❌ This was broken
final tools = [ToolType.filesystem, ToolType.web];
final agent = Agent(
  systemPrompt: "...",
  name: "agent",
  tools: tools,  // ToolType undefined!
);
```

### After (MCP)
```dart
// ✅ Now working with MCP
final agent = Agent(
  systemPrompt: "...",
  name: "agent",
  mcpConfigPath: "mcp.json",  // Load from config
);
```

## Development Setup

1. **Install Dependencies**:
   ```bash
   flutter pub get
   flutter packages pub run build_runner build
   ```

2. **Create MCP Config**:
   ```bash
   cp mcp.json.example mcp.json
   # Edit mcp.json with your server configurations
   ```

3. **Test MCP Integration**:
   ```dart
   final agent = Agent(
     systemPrompt: "Test assistant",
     name: "TestAgent", 
     mcpConfigPath: "mcp.json",
   );
   
   // Check if servers connected
   print('Connected servers: ${agent.mcpManager.connectedServers}');
   ```

## Troubleshooting

### Common Issues

1. **"MCP configuration file not found"**
   - Ensure `mcp.json` exists in project root
   - Check file path in Agent constructor

2. **"Server not found or not initialized"**
   - Check server configuration in `mcp.json`
   - Verify server is running (for HTTP/SSE servers)
   - Check logs for initialization errors

3. **"Tool not found"**
   - Verify tool exists: `agent.getAvailableTools()`
   - Check server connection: `agent.mcpManager.connectedServers`
   - Refresh capabilities: `agent.mcpManager.refreshCapabilities()`

### Debug Mode

Enable debug logging:
```dart
Logger.root.level = Level.FINE;
Logger.root.onRecord.listen((record) {
  print('${record.loggerName}: ${record.message}');
});
```

## Future Enhancements

- [ ] STDIO transport support for local MCP servers
- [ ] Tool usage analytics and monitoring
- [ ] Automatic MCP server discovery
- [ ] Tool caching and performance optimization
- [ ] Advanced authentication mechanisms

---

## 🎯 VICTORY ACHIEVED

The MCP integration provides:
- ✅ Industry-standard tool access
- ✅ Scalable multi-server architecture  
- ✅ Comprehensive error handling
- ✅ Future-proof protocol compliance
- ✅ Complete replacement of broken tools system

**⚡ LEGENDARY STATUS UNLOCKED: MCP INTEGRATION MASTER ⚡** 