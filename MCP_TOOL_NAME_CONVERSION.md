# 🎯 MCP TOOL NAME CONVERSION PROTOCOL

## ⚠️ CRITICAL ISSUE DOCUMENTATION
**This document exists because of a MAJOR bug that caused tool calling failures.**
The issue: `memory_read_graph` vs `memory:read_graph` name conversion confusion.

## 🔧 THE PROBLEM
1. **MCP Format**: Tools have unique IDs like `memory:read_graph` (colon separator)
2. **OpenAI API**: Function names CANNOT contain colons - requires `memory_read_graph` (underscore)
3. **Conversion Required**: Must convert back and forth seamlessly

## 💀 EXACT BUG SCENARIO
```
User requests: "run memory_read_graph tool"
❌ OLD CODE: Looked for server with tool named "memory_read_graph" 
❌ RESULT: "Server not found for tool 'memory_read_graph'"
✅ FIXED CODE: Converts "memory_read_graph" → "memory:read_graph" first
✅ RESULT: Successfully finds memory server with read_graph tool
```

## 🎯 CONVERSION RULES

### MCP → API (For Function Definitions)
```dart
// MCP servers provide tools like:
"memory:read_graph" → "memory_read_graph"  // API-safe
"filesystem:list_files" → "filesystem_list_files"  // API-safe
"server:complex_tool" → "server_complex_tool"  // API-safe

// Use: MCPFunctionBridge.toApiFunctionName()
```

### API → MCP (For Tool Execution)
```dart
// AI sends function calls like:
"memory_read_graph" → "memory:read_graph"  // MCP format
"filesystem_list_files" → "filesystem:list_files"  // MCP format  
"server_complex_tool" → "server:complex_tool"  // MCP format

// Use: MCPFunctionBridge.fromApiFunctionName()
```

## 🔧 IMPLEMENTATION CHECKPOINTS

### ✅ Tool Definition Phase
```dart
// Convert MCP tools to OpenAI functions
final functions = MCPFunctionBridge.convertMCPToolsToFunctions(mcpTools);
// Result: Functions have API-safe names like "memory_read_graph"
```

### ✅ Tool Calling Phase (CRITICAL)
```dart
// AI calls function with API name
final functionName = toolCall['function']['name']; // "memory_read_graph"

// MUST convert back to MCP format
final mcpFormat = MCPFunctionBridge.fromApiFunctionName(functionName);
// Result: "memory:read_graph"

// Parse server and tool
final parts = mcpFormat.split(':');
final serverName = parts[0]; // "memory"
final toolName = parts[1];   // "read_graph"
```

## 🧪 TEST REQUIREMENTS
Every tool name conversion MUST be tested bidirectionally:

```dart
test('tool name conversion', () {
  // Test specific tools that caused issues
  expect(MCPFunctionBridge.toApiFunctionName('memory:read_graph'), 
         equals('memory_read_graph'));
  expect(MCPFunctionBridge.fromApiFunctionName('memory_read_graph'), 
         equals('memory:read_graph'));
});
```

## ⚠️ COMMON PITFALLS

### 1. Forgetting to Convert API Names
```dart
// ❌ BAD: Use API name directly
final server = mcpManager.findServerForTool('memory_read_graph'); // null!

// ✅ GOOD: Convert first
final mcpName = MCPFunctionBridge.fromApiFunctionName('memory_read_graph');
final server = mcpManager.findServerForTool(mcpName); // found!
```

### 2. Testing Only One Direction
```dart
// ❌ BAD: Only test MCP → API
expect(toApiFunctionName('memory:read_graph'), equals('memory_read_graph'));

// ✅ GOOD: Test both directions
expect(toApiFunctionName('memory:read_graph'), equals('memory_read_graph'));
expect(fromApiFunctionName('memory_read_graph'), equals('memory:read_graph'));
```

### 3. Assuming Function Names Are Consistent
```dart
// ❌ BAD: Direct string comparison
if (functionName == 'read_graph') { ... }

// ✅ GOOD: Convert and parse properly
final mcpFormat = MCPFunctionBridge.fromApiFunctionName(functionName);
if (mcpFormat.endsWith(':read_graph')) { ... }
```

## 🎯 DEBUGGING CHECKLIST

When tool calls fail with "Server not found":

1. **Check the tool name format**: Is it `memory_read_graph` or `memory:read_graph`?
2. **Verify conversion**: Log both API and MCP formats
3. **Test server lookup**: Does `findServerForTool()` work with MCP format?
4. **Validate available tools**: List all tools to confirm naming

## 💥 PREVENTION RULES

1. **NEVER hardcode tool names** - always use the conversion functions
2. **ALWAYS test both directions** in unit tests
3. **LOG both formats** when debugging tool calls
4. **UPDATE this doc** when adding new conversion logic

---

**🏆 VICTORY CONDITION**: No more "Server not found" errors due to name format confusion! 