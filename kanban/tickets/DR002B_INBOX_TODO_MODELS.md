# DR002B - Inbox & Todo Content Models Implementation

## 🎯 TICKET OBJECTIVE
Create specialized MCPInboxItem and MCPTodoItem models with full CRUD operations, priority management, and interactive editing capabilities.

## 📋 ACCEPTANCE CRITERIA

### ✅ FUNCTIONAL REQUIREMENTS
- [ ] MCPInboxItem with read status, sender, priority management
- [ ] MCPTodoItem with completion status, due dates, tags
- [ ] Priority-based sorting and filtering
- [ ] Preview generation (first 5 lines) for UI display
- [ ] Full CRUD operations with validation
- [ ] Interactive editing support (mark read, complete, reprioritize)

### ✅ TECHNICAL SPECIFICATIONS
- [ ] MCPInboxItem: isRead, sender, priority, dateReceived
- [ ] MCPTodoItem: isCompleted, dueDate, priority, tags, completedAt
- [ ] Preview methods: getPreview(int maxLines = 5)
- [ ] CRUD operations: create, update, delete, markRead, complete
- [ ] Sorting: by priority, date, completion status
- [ ] Validation: due date validation, tag format validation

### ✅ ARCHITECTURAL COMPLIANCE
- [ ] Extends MCPContentItem base class from DR002A
- [ ] ChangeNotifier integration for reactive UI updates
- [ ] Self-management: Items handle own state transitions
- [ ] Object-oriented: Specialized methods for each content type
- [ ] Null safety: Proper handling of optional fields

## 🔧 IMPLEMENTATION DETAILS

### 📂 FILE LOCATIONS
- `lib/models/mcp_inbox_item.dart` - Inbox item implementation
- `lib/models/mcp_todo_item.dart` - Todo item implementation
- `test/models/mcp_inbox_item_test.dart` - Inbox item tests
- `test/models/mcp_todo_item_test.dart` - Todo item tests

### 🎯 KEY CLASSES
```dart
class MCPInboxItem extends MCPContentItem {
  bool isRead;
  String? sender;
  MCPPriority priority;
  DateTime dateReceived;
  
  void markAsRead();
  void markAsUnread();
  void setPriority(MCPPriority priority);
  String getPreview({int maxLines = 5});
  List<String> getPreviewLines();
}

class MCPTodoItem extends MCPContentItem {
  bool isCompleted;
  DateTime? dueDate;
  MCPPriority priority;
  List<String> tags;
  DateTime? completedAt;
  
  void markAsCompleted();
  void markAsIncomplete();
  void setDueDate(DateTime? date);
  void addTag(String tag);
  void removeTag(String tag);
  bool isOverdue();
  String getPreview({int maxLines = 5});
  Duration? timeUntilDue();
}
```

### 🔗 INTEGRATION POINTS
- **DR002A**: Extends MCPContentItem base infrastructure
- **DR002C**: Will be managed by MCPContentCollection
- **UI Components**: Preview methods for sidebar display
- **MCP Services**: Data source for content synchronization

## 🧪 TESTING REQUIREMENTS

### 📋 TEST CASES
- [ ] Inbox item state transitions: unread → read
- [ ] Todo item completion: incomplete → complete → incomplete
- [ ] Priority management: setting and changing priorities
- [ ] Due date handling: validation, overdue detection
- [ ] Tag management: add, remove, duplicate handling
- [ ] Preview generation: 5-line truncation with proper formatting
- [ ] Content validation: inherited validation plus specific rules
- [ ] Serialization: JSON round-trip with all specialized fields
- [ ] ChangeNotifier: Notifications on all state changes

### 🎯 PERFORMANCE TESTS
- [ ] Preview generation: < 5ms for large content
- [ ] State transitions: < 1ms for status changes
- [ ] Collection operations: < 10ms for priority sorting

## 🏆 DEFINITION OF DONE

### ✅ CODE QUALITY
- [ ] Zero linter errors/warnings
- [ ] All unit tests passing
- [ ] Test coverage > 90%
- [ ] Comprehensive documentation
- [ ] Performance benchmarks met

### ✅ FEATURE COMPLETENESS
- [ ] Full inbox functionality implemented
- [ ] Complete todo management implemented
- [ ] Preview generation working correctly
- [ ] All CRUD operations functional
- [ ] Integration points ready for DR002C

## 🔄 DEPENDENCIES
- **DR002A**: MCP Content Infrastructure (REQUIRED)

## 🎮 NEXT TICKETS
- DR002C: Notepad Content & Collection Management (parallel development)
- DR005A: MCP Content Service Foundation (depends on complete DR002 series)

## 📊 ESTIMATED EFFORT
**2-3 hours** - Specialized model implementation with testing

## 🚨 RISKS & MITIGATION
- **Risk**: Complex todo item state management could introduce bugs
- **Mitigation**: Comprehensive state transition testing and validation
- **Risk**: Preview generation inconsistencies across content types
- **Mitigation**: Standardized preview format and extensive testing

## 💡 IMPLEMENTATION NOTES
- Implement comprehensive state validation for todo items
- Consider time zone handling for due dates and timestamps
- Design tag system for future search and filtering capabilities
- Ensure preview generation handles various content formats gracefully 