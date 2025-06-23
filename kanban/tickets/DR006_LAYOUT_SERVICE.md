# DR006 - Layout Service Implementation

## 🎯 TICKET OBJECTIVE
Create LayoutService to manage theme switching, sidebar states, and layout preferences with centralized state management for Discord-style UI coordination.

## 📋 ACCEPTANCE CRITERIA

### ✅ FUNCTIONAL REQUIREMENTS
- [ ] Centralized theme management (dark/light/system)
- [ ] Sidebar collapse state coordination
- [ ] Agent selection persistence and broadcasting
- [ ] Window/panel size management
- [ ] Preference persistence via JSON storage
- [ ] Real-time theme change broadcasting to all UI components

### ✅ TECHNICAL SPECIFICATIONS
- [ ] Theme management: `setTheme()`, `getCurrentTheme()`, `getThemeData()`
- [ ] Sidebar coordination: `toggleLeftSidebar()`, `toggleRightSidebar()`
- [ ] Agent selection: `setSelectedAgent()`, `getSelectedAgent()`
- [ ] Panel sizing: `updatePanelWidths()`, `resetToDefaults()`
- [ ] Persistence: Automatic save/load of layout preferences
- [ ] Broadcasting: ChangeNotifier for real-time UI updates

### ✅ ARCHITECTURAL COMPLIANCE
- [ ] Extends ChangeNotifier for reactive layout updates
- [ ] Service layer: Centralized preference and theme management
- [ ] Object references: Manage LayoutPreferencesModel directly
- [ ] GetIt integration: Singleton service registration
- [ ] Clean initialization: Load preferences on service startup

## 🔧 IMPLEMENTATION DETAILS

### 📂 FILE LOCATIONS
- `lib/services/layout_service.dart` - Main service class
- `test/services/layout_service_test.dart` - Unit tests

### 🎯 KEY CLASSES
```dart
class LayoutService extends ChangeNotifier {
  LayoutPreferencesModel _preferences;
  
  // Theme Management
  AppTheme get currentTheme => _preferences.currentTheme;
  ThemeData get currentThemeData;
  void setTheme(AppTheme theme);
  
  // Sidebar Management
  bool get leftSidebarCollapsed => _preferences.leftSidebarCollapsed;
  bool get rightSidebarCollapsed => _preferences.rightSidebarCollapsed;
  void toggleLeftSidebar();
  void toggleRightSidebar();
  
  // Agent Selection
  String? get selectedAgentId => _preferences.selectedAgentId;
  void setSelectedAgent(String? agentId);
  
  // Panel Management
  double get leftSidebarWidth => _preferences.leftSidebarWidth;
  double get rightSidebarWidth => _preferences.rightSidebarWidth;
  void updatePanelWidths(double? leftWidth, double? rightWidth);
  
  // Persistence
  Future<void> savePreferences();
  Future<void> loadPreferences();
}
```

### 🔗 INTEGRATION POINTS
- **MaterialApp**: Theme data provider for app-wide theming
- **Discord Home Screen**: Layout state coordination
- **Sidebar Components**: Collapse state and width management
- **Agent Selection**: Coordinate active agent across all components

## 🧪 TESTING REQUIREMENTS

### 📋 TEST CASES
- [ ] Theme switching: Verify theme data changes and broadcasting
- [ ] Sidebar toggling: State management and persistence
- [ ] Agent selection: Selection persistence and coordination
- [ ] Panel sizing: Width updates and constraints
- [ ] Persistence: Save/load preference cycles
- [ ] ChangeNotifier: Broadcasting verification on all changes
- [ ] Service lifecycle: Initialization and cleanup
- [ ] Integration: MaterialApp theme binding

### 🎯 PERFORMANCE TESTS
- [ ] Theme switching: < 50ms for complete UI update
- [ ] Preference persistence: < 100ms for save/load operations
- [ ] State broadcasting: < 10ms for ChangeNotifier updates

## 🏆 DEFINITION OF DONE

### ✅ CODE QUALITY
- [ ] Zero linter errors/warnings
- [ ] All unit tests passing
- [ ] Test coverage > 90%
- [ ] Integration tests with UI components
- [ ] Performance benchmarks documented

### ✅ INTEGRATION READY
- [ ] MaterialApp theme integration
- [ ] Layout component integration contracts
- [ ] Agent selection coordination
- [ ] Services.dart registration completed
- [ ] UI binding documentation complete

## 🔄 DEPENDENCIES
- **DR003**: Layout Preferences Model (REQUIRED)

## 🎮 NEXT TICKETS
- DR007: Discord Home Screen (depends on DR006)
- DR012: Theme System Integration (depends on DR006)

## 📊 ESTIMATED EFFORT
**2-3 hours** - Service coordination and theme management

## 🚨 RISKS & MITIGATION
- **Risk**: Theme changes could cause UI flicker during transitions
- **Mitigation**: Implement smooth theme transition animations
- **Risk**: Layout state could get out of sync between components
- **Mitigation**: Centralized state management with single source of truth

## 💡 IMPLEMENTATION NOTES
- Consider implementing theme transition animations for smooth UX
- Design preference structure for easy extension with new layout options
- Implement validation for panel width constraints and minimum sizes
- Plan for future layout customization features and responsive breakpoints 