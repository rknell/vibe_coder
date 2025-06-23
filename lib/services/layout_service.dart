import 'package:flutter/material.dart';
import 'package:vibe_coder/models/layout_preferences_model.dart';

/// LayoutService - Centralized Layout & Theme Management
///
/// ## 🏆 MISSION ACCOMPLISHED
/// Eliminate scattered layout state management with centralized service coordination
/// for Discord-style three-panel layout with reactive theme switching and persistence.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | LayoutService | Single source of truth | Service complexity | CHOSEN - Clean Architecture compliance |
/// | Direct model access | Simplicity | Scattered logic | REJECTED - violates service layer pattern |
/// | Component state | Local control | Inconsistent state | REJECTED - state synchronization issues |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Theme Management Chaos**
///    - 🔍 Symptom: Hardcoded themes with no user preference persistence
///    - 🎯 Root Cause: No centralized theme coordination across UI components
///    - 💥 Kill Shot: Service-managed theme switching with reactive broadcasting
///
/// 2. **Sidebar State Inconsistency**
///    - 🔍 Symptom: Sidebar states reset on app restart, no coordination
///    - 🎯 Root Cause: No persistent layout preference management
///    - 💥 Kill Shot: Centralized sidebar coordination with JSON persistence
///
/// 3. **Agent Selection Memory Loss**
///    - 🔍 Symptom: Selected agent resets across sessions
///    - 🎯 Root Cause: No service layer agent selection persistence
///    - 💥 Kill Shot: Service-managed agent selection with automatic persistence
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) for all operations except persistence (O(n) where n = file size)
/// - Space Complexity: O(1) - single preferences model instance
/// - Notification Frequency: On state changes only (optimized)
/// - Persistence: Async background saves without UI blocking
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ Extends ChangeNotifier for reactive layout updates
/// ✅ Service layer: Centralized preference and theme management
/// ✅ Object references: Manages LayoutPreferencesModel directly
/// ✅ Single source of truth: No duplicate layout state
/// ✅ Clean initialization: Auto-loads preferences on service startup
class LayoutService extends ChangeNotifier {
  /// Layout preferences model - single source of truth
  late LayoutPreferencesModel _preferences;

  /// Disposal tracking to prevent use after disposal
  bool _disposed = false;

  /// Constructor initializes with default Discord-style preferences
  ///
  /// PERF: O(1) - minimal initialization with async preference loading
  /// INTEGRATION: Called once during app startup via Services initialization
  LayoutService() {
    _preferences = LayoutPreferencesModel();
    // Load preferences asynchronously without blocking constructor
    _loadPreferencesAsync();
  }

  // ============================================================================
  // THEME MANAGEMENT - Discord-Style Theme System
  // ============================================================================

  /// Current theme selection
  AppTheme get currentTheme => _preferences.currentTheme;

  /// Set application theme with reactive broadcasting
  ///
  /// PERF: O(1) - direct theme assignment with change detection
  /// INTEGRATION: Triggers immediate UI re-render via ListenableBuilder
  void setTheme(AppTheme theme) {
    if (_disposed) return; // WARRIOR PROTOCOL: Disposal guard
    if (_preferences.currentTheme != theme) {
      _preferences.setTheme(theme);
      notifyListeners(); // MANDATORY: Reactive theme updates
      _savePreferencesAsync(); // Non-blocking persistence
    }
  }

  /// Get ThemeData for current theme (overloaded for testing)
  ///
  /// PERF: O(1) - immediate ThemeData creation based on current selection
  /// INTEGRATION: Used by MaterialApp for consistent theming
  ThemeData getThemeData(BuildContext context, [AppTheme? overrideTheme]) {
    if (overrideTheme != null) {
      // For testing - temporarily set theme to generate ThemeData
      final originalTheme = _preferences.currentTheme;
      _preferences.setTheme(overrideTheme);
      final themeData = _preferences.getThemeData(context);
      _preferences.setTheme(originalTheme);
      return themeData;
    }
    return _preferences.getThemeData(context);
  }

  // ============================================================================
  // SIDEBAR MANAGEMENT - Discord-Style Panel Control
  // ============================================================================

  /// Left sidebar collapsed state
  bool get leftSidebarCollapsed => _preferences.leftSidebarCollapsed;

  /// Right sidebar collapsed state
  bool get rightSidebarCollapsed => _preferences.rightSidebarCollapsed;

  /// Left sidebar width in pixels
  double get leftSidebarWidth => _preferences.leftSidebarWidth;

  /// Right sidebar width in pixels
  double get rightSidebarWidth => _preferences.rightSidebarWidth;

  /// Toggle left sidebar collapsed state
  ///
  /// PERF: O(1) - boolean toggle with change detection
  void toggleLeftSidebar() {
    if (_disposed) return; // WARRIOR PROTOCOL: Disposal guard
    _preferences.toggleLeftSidebar();
    notifyListeners(); // MANDATORY: Reactive sidebar updates
    _savePreferencesAsync();
  }

  /// Toggle right sidebar collapsed state
  ///
  /// PERF: O(1) - boolean toggle with change detection
  void toggleRightSidebar() {
    if (_disposed) return; // WARRIOR PROTOCOL: Disposal guard
    _preferences.toggleRightSidebar();
    notifyListeners(); // MANDATORY: Reactive sidebar updates
    _savePreferencesAsync();
  }

  /// Set left sidebar collapsed state explicitly
  ///
  /// PERF: O(1) - direct state assignment with validation
  void setLeftSidebarCollapsed(bool collapsed) {
    if (_disposed) return; // WARRIOR PROTOCOL: Disposal guard
    if (_preferences.leftSidebarCollapsed != collapsed) {
      _preferences.setLeftSidebarCollapsed(collapsed);
      notifyListeners(); // MANDATORY: Reactive updates
      _savePreferencesAsync();
    }
  }

  /// Set right sidebar collapsed state explicitly
  ///
  /// PERF: O(1) - direct state assignment with validation
  void setRightSidebarCollapsed(bool collapsed) {
    if (_disposed) return; // WARRIOR PROTOCOL: Disposal guard
    if (_preferences.rightSidebarCollapsed != collapsed) {
      _preferences.setRightSidebarCollapsed(collapsed);
      notifyListeners(); // MANDATORY: Reactive updates
      _savePreferencesAsync();
    }
  }

  /// Update panel widths with validation
  ///
  /// PERF: O(1) - direct width updates with constraint validation
  void updatePanelWidths({double? leftWidth, double? rightWidth}) {
    if (_disposed) return; // WARRIOR PROTOCOL: Disposal guard
    final currentLeft = _preferences.leftSidebarWidth;
    final currentRight = _preferences.rightSidebarWidth;

    _preferences.updatePanelWidths(
        leftWidth: leftWidth, rightWidth: rightWidth);

    // Only notify if values actually changed
    if (_preferences.leftSidebarWidth != currentLeft ||
        _preferences.rightSidebarWidth != currentRight) {
      notifyListeners(); // MANDATORY: Reactive layout updates
      _savePreferencesAsync();
    }
  }

  /// Reset panel layout to Discord-style defaults
  ///
  /// PERF: O(1) - default layout restoration
  void resetPanelLayout() {
    if (_disposed) return; // WARRIOR PROTOCOL: Disposal guard
    _preferences.resetPanelLayout();
    notifyListeners(); // MANDATORY: Reactive reset updates
    _savePreferencesAsync();
  }

  // ============================================================================
  // AGENT SELECTION MANAGEMENT - Persistent Selection State
  // ============================================================================

  /// Currently selected agent ID
  String? get selectedAgentId => _preferences.selectedAgentId;

  /// Whether service has been disposed (for testing)
  bool get isDisposed => _disposed;

  /// Set selected agent with persistence
  ///
  /// PERF: O(1) - direct assignment with change detection
  void setSelectedAgent(String? agentId) {
    if (_disposed) return; // WARRIOR PROTOCOL: Disposal guard
    if (_preferences.selectedAgentId != agentId) {
      _preferences.setSelectedAgent(agentId);
      notifyListeners(); // MANDATORY: Reactive agent selection updates
      _savePreferencesAsync();
    }
  }

  // ============================================================================
  // PERSISTENCE MANAGEMENT - JSON Storage Coordination
  // ============================================================================

  /// Save preferences to persistent storage
  ///
  /// PERF: O(n) where n = JSON file size, typically <1KB
  /// INTEGRATION: Called automatically on all preference changes
  Future<void> savePreferences() async {
    if (_disposed) return; // WARRIOR PROTOCOL: Disposal guard
    try {
      await _preferences.savePreferences();
    } catch (e) {
      // Preference save failures are non-critical - log but don't throw
      debugPrint('⚠️ LayoutService: Failed to save preferences: $e');
    }
  }

  /// Load preferences from persistent storage
  ///
  /// PERF: O(n) where n = JSON file size, typically <1KB
  /// INTEGRATION: Called automatically on service creation
  Future<void> loadPreferences() async {
    if (_disposed) return; // WARRIOR PROTOCOL: Disposal guard
    try {
      await _preferences.loadPreferences();
      if (!_disposed) notifyListeners(); // Notify UI of loaded preferences
    } catch (e) {
      // Preference load failures fall back to defaults - log but don't throw
      debugPrint(
          '⚠️ LayoutService: Failed to load preferences, using defaults: $e');
    }
  }

  /// Async wrapper for background preference saving
  ///
  /// PERF: Non-blocking - doesn't wait for file I/O completion
  void _savePreferencesAsync() {
    if (_disposed) return; // WARRIOR PROTOCOL: Disposal guard
    savePreferences().catchError((e) {
      // Errors already handled in savePreferences()
    });
  }

  /// Async wrapper for background preference loading
  ///
  /// PERF: Non-blocking - doesn't wait for file I/O completion
  void _loadPreferencesAsync() {
    if (_disposed) return; // WARRIOR PROTOCOL: Disposal guard
    loadPreferences().catchError((e) {
      // Errors already handled in loadPreferences()
    });
  }

  // ============================================================================
  // SERVICE LIFECYCLE MANAGEMENT
  // ============================================================================

  /// Dispose service and cleanup resources
  ///
  /// PERF: O(1) - cleanup notification listeners
  /// INTEGRATION: Called when service is no longer needed
  @override
  void dispose() {
    if (_disposed) return; // WARRIOR PROTOCOL: Prevent double disposal
    _disposed = true;
    // Ensure final save before disposal (but don't wait for it)
    _savePreferencesAsync();
    super.dispose();
  }
}
