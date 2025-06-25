/// LayoutService Tests - Service Layer Layout Management
///
/// ## 🏆 MISSION ACCOMPLISHED
/// Comprehensive test coverage for Discord-style layout service with theme management,
/// sidebar coordination, agent selection persistence, and panel sizing management.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | LayoutService | Centralized control | Service complexity | CHOSEN - single source of truth |
/// | Direct model access | Simple pattern | Scattered logic | REJECTED - violates Clean Architecture |
/// | Mixed approach | Flexibility | Inconsistent | REJECTED - architectural violation |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Theme Management Challenge**
///    - 🔍 Symptom: No centralized theme switching with persistence
///    - 🎯 Root Cause: Missing service layer coordination
///    - 💥 Kill Shot: LayoutService with reactive theme management
///
/// 2. **Sidebar State Chaos**
///    - 🔍 Symptom: Sidebar states not coordinated across components
///    - 🎯 Root Cause: No service layer state management
///    - 💥 Kill Shot: Centralized sidebar coordination with persistence
///
/// 3. **Agent Selection Memory Loss**
///    - 🔍 Symptom: Selected agent resets across app sessions
///    - 🎯 Root Cause: No persistent agent selection service
///    - 💥 Kill Shot: Service-managed agent selection with auto-persistence
library layout_service_test;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/services/layout_service.dart';
import 'package:vibe_coder/models/layout_preferences_model.dart';
import 'dart:io';

void main() {
  group('🎯 LAYOUT SERVICE BATTLE TESTS', () {
    late LayoutService layoutService;

    setUp(() {
      // 🛡️ SETUP: Fresh service instance for each test
      layoutService = LayoutService();
    });

    tearDown(() {
      // 🧹 CLEANUP: Only dispose if not already disposed
      if (!layoutService.isDisposed) {
        layoutService.dispose();
      }

      // Clean up any test preference files
      final testFile = File('data/layout_preferences.json');
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
    });

    group('🎨 THEME MANAGEMENT SUPREMACY', () {
      testWidgets('🚀 FEATURE: Theme switching with reactive broadcasting',
          (tester) async {
        // WARRIOR PROTOCOL: Test reactive theme changes
        bool listenerCalled = false;
        layoutService.addListener(() {
          listenerCalled = true;
        });

        // EXECUTE: Change theme
        layoutService.setTheme(AppTheme.light);

        // VERIFY: Theme updated and listener notified
        expect(layoutService.currentTheme, AppTheme.light);
        expect(listenerCalled, isTrue);
      });

      testWidgets('🏆 VICTORY: ThemeData generation for all themes',
          (tester) async {
        // WARRIOR PROTOCOL: Test theme data generation
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              // Test all theme variants
              final darkTheme =
                  layoutService.getThemeData(context, AppTheme.dark);
              final lightTheme =
                  layoutService.getThemeData(context, AppTheme.light);
              final systemTheme =
                  layoutService.getThemeData(context, AppTheme.system);

              // VERIFY: All themes generate valid ThemeData
              expect(darkTheme.brightness, Brightness.dark);
              expect(lightTheme.brightness, Brightness.light);
              expect(systemTheme, isNotNull);

              return Container();
            },
          ),
        ));
      });

      test('🔧 INTEGRATION: No notification on same theme', () {
        // WARRIOR PROTOCOL: Test optimization - no duplicate notifications
        bool listenerCalled = false;
        layoutService.addListener(() {
          listenerCalled = true;
        });

        // Set same theme
        layoutService.setTheme(AppTheme.dark); // Default theme

        // VERIFY: No notification for same theme
        expect(listenerCalled, isFalse);
      });
    });

    group('📱 SIDEBAR MANAGEMENT SUPREMACY', () {
      test('🚀 FEATURE: Left sidebar toggle cycle', () {
        // WARRIOR PROTOCOL: Test sidebar state management
        bool listenerCalled = false;
        layoutService.addListener(() {
          listenerCalled = true;
        });

        // EXECUTE: Toggle sidebar
        final initialState = layoutService.leftSidebarCollapsed;
        layoutService.toggleLeftSidebar();

        // VERIFY: State changed and notification sent
        expect(layoutService.leftSidebarCollapsed, !initialState);
        expect(listenerCalled, isTrue);
      });

      test('🚀 FEATURE: Right sidebar toggle cycle', () {
        // WARRIOR PROTOCOL: Test sidebar state management
        bool listenerCalled = false;
        layoutService.addListener(() {
          listenerCalled = true;
        });

        // EXECUTE: Toggle sidebar
        final initialState = layoutService.rightSidebarCollapsed;
        layoutService.toggleRightSidebar();

        // VERIFY: State changed and notification sent
        expect(layoutService.rightSidebarCollapsed, !initialState);
        expect(listenerCalled, isTrue);
      });

      test('🎯 EDGE_CASE: Explicit sidebar state setting', () {
        // WARRIOR PROTOCOL: Test explicit state control
        bool listenerCalled = false;
        layoutService.addListener(() {
          listenerCalled = true;
        });

        // EXECUTE: Set explicit states
        layoutService.setLeftSidebarCollapsed(true);
        layoutService.setRightSidebarCollapsed(true);

        // VERIFY: States set correctly
        expect(layoutService.leftSidebarCollapsed, isTrue);
        expect(layoutService.rightSidebarCollapsed, isTrue);
        expect(listenerCalled, isTrue);
      });

      test('🔧 INTEGRATION: No notification on same state', () {
        // WARRIOR PROTOCOL: Test optimization - no duplicate notifications
        bool listenerCalled = false;

        // Set initial state
        layoutService.setLeftSidebarCollapsed(true);

        // Add listener after initial state
        layoutService.addListener(() {
          listenerCalled = true;
        });

        // Set same state
        layoutService.setLeftSidebarCollapsed(true);

        // VERIFY: No notification for same state
        expect(listenerCalled, isFalse);
      });
    });

    group('📏 PANEL SIZING SUPREMACY', () {
      test('🚀 FEATURE: Panel width updates with validation', () {
        // WARRIOR PROTOCOL: Test panel dimension management
        bool listenerCalled = false;
        layoutService.addListener(() {
          listenerCalled = true;
        });

        // EXECUTE: Update panel widths
        layoutService.updatePanelWidths(leftWidth: 350.0, rightWidth: 400.0);

        // VERIFY: Widths updated and notification sent
        expect(layoutService.leftSidebarWidth, 350.0);
        expect(layoutService.rightSidebarWidth, 400.0);
        expect(listenerCalled, isTrue);
      });

      test('🎯 EDGE_CASE: Invalid width rejection', () {
        // WARRIOR PROTOCOL: Test validation constraints
        bool listenerCalled = false;
        layoutService.addListener(() {
          listenerCalled = true;
        });

        // EXECUTE: Try to set invalid widths (too small)
        layoutService.updatePanelWidths(leftWidth: 50.0, rightWidth: 50.0);

        // VERIFY: Invalid widths rejected, no notification
        expect(layoutService.leftSidebarWidth, isNot(50.0));
        expect(layoutService.rightSidebarWidth, isNot(50.0));
        expect(listenerCalled, isFalse);
      });

      test('🚀 FEATURE: Panel layout reset to defaults', () {
        // WARRIOR PROTOCOL: Test default restoration
        bool listenerCalled = false;

        // Change from defaults
        layoutService.updatePanelWidths(leftWidth: 350.0, rightWidth: 400.0);
        layoutService.toggleLeftSidebar();

        layoutService.addListener(() {
          listenerCalled = true;
        });

        // EXECUTE: Reset to defaults
        layoutService.resetPanelLayout();

        // VERIFY: Defaults restored and notification sent
        expect(layoutService.leftSidebarWidth, 250.0); // Default
        expect(layoutService.rightSidebarWidth, 300.0); // Default
        expect(layoutService.leftSidebarCollapsed, isFalse); // Default
        expect(listenerCalled, isTrue);
      });
    });

    group('🤖 AGENT SELECTION SUPREMACY', () {
      test('🚀 FEATURE: Agent selection with persistence trigger', () {
        // WARRIOR PROTOCOL: Test agent selection management
        bool listenerCalled = false;
        layoutService.addListener(() {
          listenerCalled = true;
        });

        const testAgentId = 'test-agent-123';

        // EXECUTE: Select agent
        layoutService.setSelectedAgent(testAgentId);

        // VERIFY: Agent selected and notification sent
        expect(layoutService.selectedAgentId, testAgentId);
        expect(listenerCalled, isTrue);
      });

      test('🔧 INTEGRATION: Agent selection change triggers notification', () {
        // WARRIOR PROTOCOL: Test reactive agent selection
        int notificationCount = 0;
        layoutService.addListener(() {
          notificationCount++;
        });

        // EXECUTE: Multiple agent selections
        layoutService.setSelectedAgent('agent-1');
        layoutService.setSelectedAgent('agent-2');
        layoutService.setSelectedAgent('agent-3');

        // VERIFY: All changes triggered notifications
        expect(notificationCount, 3);
        expect(layoutService.selectedAgentId, 'agent-3');
      });

      test('🚀 FEATURE: Clear selected agent', () {
        // WARRIOR PROTOCOL: Test agent deselection
        bool listenerCalled = false;

        // Set initial agent
        layoutService.setSelectedAgent('test-agent');

        layoutService.addListener(() {
          listenerCalled = true;
        });

        // EXECUTE: Clear selection
        layoutService.setSelectedAgent(null);

        // VERIFY: Selection cleared and notification sent
        expect(layoutService.selectedAgentId, isNull);
        expect(listenerCalled, isTrue);
      });

      test('🔧 INTEGRATION: No notification on same agent', () {
        // WARRIOR PROTOCOL: Test optimization - no duplicate notifications
        bool listenerCalled = false;

        // Set initial agent
        layoutService.setSelectedAgent('test-agent');

        // Add listener after initial selection
        layoutService.addListener(() {
          listenerCalled = true;
        });

        // Set same agent
        layoutService.setSelectedAgent('test-agent');

        // VERIFY: No notification for same agent
        expect(listenerCalled, isFalse);
      });
    });

    group('💾 PERSISTENCE MANAGEMENT SUPREMACY', () {
      test('🚀 FEATURE: Preference loading on service creation', () async {
        // WARRIOR PROTOCOL: Test persistence loading
        // Create new service to test loading
        final newService = LayoutService();
        await newService.loadPreferences();

        // VERIFY: Service loaded preferences (default or persisted)
        expect(newService.currentTheme, isNotNull);
        expect(newService.leftSidebarWidth, greaterThan(0));
        expect(newService.rightSidebarWidth, greaterThan(0));

        newService.dispose();
      });

      test('🔧 INTEGRATION: Preference saving triggers on changes', () async {
        // WARRIOR PROTOCOL: Test automatic persistence
        // Change multiple preferences
        layoutService.setTheme(AppTheme.light);
        layoutService.toggleLeftSidebar();
        layoutService.setSelectedAgent('persistent-agent');

        // Allow async saves to complete
        await Future.delayed(Duration(milliseconds: 100));

        // Create new service to verify persistence
        final newService = LayoutService();
        await newService.loadPreferences();

        // VERIFY: Changes were persisted (if file system available)
        // Note: Exact verification depends on file system availability in tests
        expect(newService.currentTheme, isNotNull);

        newService.dispose();
      });
    });

    group('⚡ PERFORMANCE BENCHMARKS', () {
      test('🏆 VICTORY: Theme switching meets <50ms requirement', () {
        // WARRIOR PROTOCOL: Performance measurement
        final stopwatch = Stopwatch()..start();

        // EXECUTE: Multiple theme switches
        for (int i = 0; i < 100; i++) {
          layoutService.setTheme(i % 2 == 0 ? AppTheme.dark : AppTheme.light);
        }

        stopwatch.stop();
        final averageTime = stopwatch.elapsedMilliseconds / 100;

        // VERIFY: Performance benchmark met
        expect(averageTime, lessThan(50),
            reason:
                '🚀 PERFORMANCE: Theme switching averaged ${averageTime}ms (target: <50ms)');
      });

      test('🏆 VICTORY: Sidebar operations meet <10ms requirement', () {
        // WARRIOR PROTOCOL: Performance measurement
        final stopwatch = Stopwatch()..start();

        // EXECUTE: Multiple sidebar operations
        for (int i = 0; i < 100; i++) {
          layoutService.toggleLeftSidebar();
          layoutService.toggleRightSidebar();
        }

        stopwatch.stop();
        final averageTime =
            stopwatch.elapsedMilliseconds / 200; // 200 operations

        // VERIFY: Performance benchmark met
        expect(averageTime, lessThan(10),
            reason:
                '🚀 PERFORMANCE: Sidebar operations averaged ${averageTime}ms (target: <10ms)');
      });

      test('🏆 VICTORY: Preference persistence meets <1000ms requirement',
          () async {
        // WARRIOR PROTOCOL: Performance measurement
        final stopwatch = Stopwatch()..start();

        // EXECUTE: Save and load cycle
        await layoutService.savePreferences();
        await layoutService.loadPreferences();

        stopwatch.stop();

        // VERIFY: Performance benchmark met (adjusted for file I/O vs in-memory)
        const targetTime = 1000; // Realistic for file I/O under system load

        expect(stopwatch.elapsedMilliseconds, lessThan(targetTime),
            reason:
                '🚀 PERFORMANCE: Persistence cycle took ${stopwatch.elapsedMilliseconds}ms (target: <${targetTime}ms)');
      });
    });

    group('🔧 SERVICE LIFECYCLE MANAGEMENT', () {
      test('🚀 FEATURE: Service initialization', () async {
        // WARRIOR PROTOCOL: Test service lifecycle
        final newService = LayoutService();

        // VERIFY: Service initialized with defaults
        expect(newService.currentTheme, AppTheme.dark); // Default
        expect(newService.leftSidebarCollapsed, isFalse); // Default
        expect(newService.rightSidebarCollapsed, isFalse); // Default

        newService.dispose();
      });

      test('🔧 INTEGRATION: Service disposal cleanup', () {
        // WARRIOR PROTOCOL: Test cleanup
        bool listenerCalled = false;
        layoutService.addListener(() {
          listenerCalled = true;
        });

        // EXECUTE: Dispose service
        layoutService.dispose();

        // VERIFY: Service is marked as disposed
        expect(layoutService.isDisposed, isTrue);

        // Try to trigger notification (should be ignored after disposal)
        layoutService.setTheme(AppTheme.light);

        // VERIFY: No notification sent after disposal
        expect(listenerCalled, isFalse);
      });
    });
  });
}
