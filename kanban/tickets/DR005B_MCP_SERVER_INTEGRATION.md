# DR005B - MCP Server Integration & Content Sync Implementation

## 🎯 TICKET OBJECTIVE
Integrate MCPContentService with existing MCP servers (notepad, todo, inbox) for real-time content synchronization and intelligent caching with error recovery.

## 📋 ACCEPTANCE CRITERIA

### ✅ FUNCTIONAL REQUIREMENTS
- [ ] Direct integration with existing MCPClient for server communication
- [ ] Content fetching from notepad, todo, and inbox MCP servers
- [ ] Intelligent content caching to reduce unnecessary server calls
- [ ] Content change detection and selective UI updates
- [ ] Robust error handling with exponential backoff retry logic
- [ ] Content synchronization coordination across all MCP content types

### ✅ TECHNICAL SPECIFICATIONS
- [ ] MCP server communication: Integrate with MCPClient for tool calls
- [ ] Content fetching: `_fetchNotepadContent()`, `_fetchTodoItems()`, `_fetchInboxItems()`
- [ ] Caching strategy: Content comparison and change detection
- [ ] Error handling: Network failures, server timeouts, malformed responses
- [ ] Content updates: Populate MCPContentCollection instances
- [ ] Performance optimization: Batch operations and selective updates

### ✅ ARCHITECTURAL COMPLIANCE
- [ ] Service layer: Business logic for MCP server coordination
- [ ] Object references: Update existing MCPContentCollection instances
- [ ] Error propagation: Proper exception handling with user feedback
- [ ] Single source of truth: MCPContentCollection as authoritative data source
- [ ] Non-blocking operations: Background content fetching

## 🔧 IMPLEMENTATION DETAILS

### 📂 FILE LOCATIONS
- `lib/services/mcp_content_service.dart` - Extended with server integration
- `test/services/mcp_content_service_integration_test.dart` - Integration tests

### 🎯 KEY METHODS ADDITIONS
```dart
class MCPContentService extends ChangeNotifier {
  final Map<String, MCPContentCollection> _agentContent = {};
  final Map<String, DateTime> _lastFetchTime = {};
  final Map<String, String> _contentHashes = {};
  
  // MCP Server Integration
  Future<void> fetchAgentContent(String agentId);
  Future<MCPNotepadContent> _fetchNotepadContent(String agentId);
  Future<List<MCPTodoItem>> _fetchTodoItems(String agentId);
  Future<List<MCPInboxItem>> _fetchInboxItems(String agentId);
  
  // Caching and optimization
  bool _hasContentChanged(String key, String newContent);
  void _updateContentHash(String key, String content);
  bool _shouldSkipFetch(String agentId);
  
  // Error handling and recovery
  Future<T> _executeWithRetry<T>(Future<T> Function() operation);
  void _handleFetchError(String agentId, Exception error);
  Duration _calculateBackoffDelay(int attemptCount);
  
  // Content collection management
  MCPContentCollection? getAgentContent(String agentId);
  void _updateAgentCollection(String agentId, MCPContentCollection content);
}
```

### 🔗 INTEGRATION POINTS
- **MCPClient**: Direct integration for MCP tool calls
- **Existing MCP Servers**: notepad_server, todo_server, inbox_server
- **DR005A**: Builds on polling foundation infrastructure
- **DR002 Series**: Populates MCPContentCollection and item models
- **UI Components**: Provides reactive content updates for sidebar

## 🧪 TESTING REQUIREMENTS

### 📋 TEST CASES
- [ ] MCP server communication: Successful tool calls to all server types
- [ ] Content fetching: Notepad, todo, and inbox content retrieval
- [ ] Content caching: Skip unnecessary fetches for unchanged content
- [ ] Error handling: Network failures, server errors, malformed responses
- [ ] Retry logic: Exponential backoff for failed requests
- [ ] Content updates: MCPContentCollection population and updates
- [ ] Agent isolation: Content separation between different agents
- [ ] Performance optimization: Batch operations and selective updates
- [ ] Integration: End-to-end content sync from MCP servers to UI

### 🎯 PERFORMANCE TESTS
- [ ] Content fetching: < 500ms for complete agent content sync
- [ ] Caching efficiency: 90%+ cache hit rate for unchanged content
- [ ] Error recovery: < 30 seconds total for retry completion
- [ ] Memory usage: Efficient content collection management

## 🏆 DEFINITION OF DONE

### ✅ CODE QUALITY
- [ ] Zero linter errors/warnings
- [ ] All unit and integration tests passing
- [ ] Test coverage > 85%
- [ ] Integration tests with mock MCP servers
- [ ] Performance benchmarks documented

### ✅ FUNCTIONAL COMPLETENESS
- [ ] All three MCP content types syncing correctly
- [ ] Error handling and recovery working reliably
- [ ] Content caching optimizing server calls
- [ ] Real-time content updates flowing to UI
- [ ] Agent-specific content isolation maintained

## 🔄 DEPENDENCIES
- **DR005A**: MCP Content Service Foundation (REQUIRED)
- **DR002 Series**: Complete MCP content models (REQUIRED)
- **Existing**: MCPClient and MCP servers

## 🎮 NEXT TICKETS
- DR010: MCP Sidebar Component (depends on DR005B)
- DR011: MCP Content Editors (depends on DR005B)

## 📊 ESTIMATED EFFORT
**2-3 hours** - MCP integration and content synchronization

## 🚨 RISKS & MITIGATION
- **Risk**: MCP server calls could block the UI or fail frequently
- **Mitigation**: Non-blocking background operations with robust error handling
- **Risk**: Content caching could become stale or inconsistent
- **Mitigation**: Intelligent cache invalidation and content change detection
- **Risk**: Large content collections could impact memory usage
- **Mitigation**: Efficient content management with garbage collection

## 💡 IMPLEMENTATION NOTES
- Implement content diff algorithms to minimize unnecessary UI updates
- Design error messages to be user-friendly while preserving debugging information
- Consider implementing content compression for large notepad content
- Plan for future MCP server authentication and security requirements 