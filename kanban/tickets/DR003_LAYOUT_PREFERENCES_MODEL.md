# DR003 - Layout Preferences Model Implementation

## 🎯 TICKET OBJECTIVE
Create LayoutPreferencesModel to manage theme selection, sidebar collapse states, and Discord-style layout preferences with persistence.

## 📋 ACCEPTANCE CRITERIA

### ✅ FUNCTIONAL REQUIREMENTS
- [ ] Theme management: Dark/Light theme with default dark
- [ ] Sidebar state management: Left/right sidebar collapse states
- [ ] Window/panel size preferences
- [ ] Agent selection persistence across app restarts
- [ ] Layout preference persistence via JSON storage
- [ ] Reactive updates for immediate UI theme changes

### ✅ TECHNICAL SPECIFICATIONS
- [ ] Enum: `AppTheme { dark, light, system }`
- [ ] Fields: `currentTheme`, `leftSidebarCollapsed`, `rightSidebarCollapsed`
- [ ] Fields: `selectedAgentId`, `windowSize`, `panelWidths`
- [ ] Methods: `setTheme()`, `toggleLeftSidebar()`, `toggleRightSidebar()`
- [ ] Persistence: Save/load from JSON file
- [ ] Validation: Theme and state validation

### ✅ ARCHITECTURAL COMPLIANCE
- [ ] Extends ChangeNotifier for reactive theme changes
- [ ] Self-management: Handles own persistence and validation
- [ ] Single source of truth: No duplicate preference storage
- [ ] Object-oriented: Direct preference mutation methods
- [ ] Null safety: Safe handling of optional preferences

## 🔧 IMPLEMENTATION DETAILS

### 📂 FILE LOCATIONS
- `lib/models/layout_preferences_model.dart` - Main model class
- `test/models/layout_preferences_model_test.dart` - Unit tests

### 🎯 KEY CLASSES
```dart
enum AppTheme { dark, light, system }

class LayoutPreferencesModel extends ChangeNotifier {
  AppTheme currentTheme;
  bool leftSidebarCollapsed;
  bool rightSidebarCollapsed;
  String? selectedAgentId;
  Size? windowSize;
  double leftSidebarWidth;
  double rightSidebarWidth;
  
  // Methods: setTheme(), toggleSidebars(), savePreferences(), etc.
}

class PanelLayout {
  double leftWidth;
  double rightWidth;
  bool leftCollapsed;
  bool rightCollapsed;
  double minWidth;
  double maxWidth;
}
```

### 🔗 INTEGRATION POINTS
- **Theme System**: Connect to Flutter MaterialApp theme
- **Sidebar Components**: Provide collapse state and width preferences
- **Agent Selection**: Persist last selected agent
- **Layout Service**: Service layer will manage preference updates

## 🧪 TESTING REQUIREMENTS

### 📋 TEST CASES
- [ ] Theme switching: Dark → Light → System transitions
- [ ] Sidebar state: Collapse/expand state management
- [ ] Persistence: Save/load preferences from JSON
- [ ] Agent selection: Last selected agent persistence
- [ ] Window size: Size preference handling
- [ ] ChangeNotifier: Verify notifications on preference changes
- [ ] Validation: Invalid theme/state handling
- [ ] Default values: Proper default preference initialization

### 🎯 PERFORMANCE TESTS
- [ ] Theme switching: < 50ms for complete UI update
- [ ] Preference saving: < 100ms for JSON persistence
- [ ] Memory usage: No preference-related memory leaks

## 🏆 DEFINITION OF DONE

### ✅ CODE QUALITY
- [ ] Zero linter errors/warnings
- [ ] All unit tests passing
- [ ] Test coverage > 95%
- [ ] Comprehensive documentation
- [ ] Performance benchmarks completed

### ✅ INTEGRATION READY
- [ ] Theme system integration specification
- [ ] Sidebar component integration contracts
- [ ] Layout service integration strategy
- [ ] UI component theme binding documentation

## 🔄 DEPENDENCIES
- **NONE** - Independent foundational model

## 🎮 NEXT TICKETS
- DR004: Agent Status Service 
- DR006: Layout Service (depends on DR003)
- DR007: Discord Home Screen (depends on DR003)

## 📊 ESTIMATED EFFORT
**2-3 hours** - Straightforward model with persistence

## 🚨 RISKS & MITIGATION
- **Risk**: Theme changes could cause UI flicker or inconsistency
- **Mitigation**: Implement smooth theme transitions with proper state management
- **Risk**: Preference file corruption could reset user settings
- **Mitigation**: Implement backup/restore mechanism and validation

## 💡 IMPLEMENTATION NOTES
- Consider system theme detection for automatic theme switching
- Implement smooth animations for sidebar collapse/expand
- Store preferences in user-specific directory for multi-user support
- Design for future extension with additional layout customization options 