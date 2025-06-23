library agent_tab_bar;

/// AgentTabBar - Agent-specific tab bar with reactive updates
///
/// ## MISSION ACCOMPLISHED
/// **ELIMINATES COMPLEX TABBAR CONSTRUCTION ANTI-PATTERN** by extracting tab creation logic.
/// Provides reactive agent count updates and interactive tab management.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Inline TabBar | Simple | Complex construction | ELIMINATED - violates component extraction rule |
/// | AgentTabBar Component | Reusable, clean | Extra abstraction | CHOSEN - separates concerns |
/// | Generic TabBar | General purpose | No agent-specific features | REJECTED - need agent-specific logic |
/// | Multiple TabBars | Type safety | Code duplication | REJECTED - single component handles all states |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Complex Tab Construction Elimination**
///    - 🔍 Symptom: Complex inline TabBar with agent-specific logic
///    - 🎯 Root Cause: Mixed concerns in HomeScreen build method
///    - 💥 Kill Shot: Dedicated component for agent tab management
///
/// 2. **Reactive Agent Count Achievement**
///    - 🔍 Symptom: Manual agent count management in UI
///    - 🎯 Root Cause: UI directly accessing service data
///    - 💥 Kill Shot: ListenableBuilder integration for automatic updates
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Tab creation: O(n) where n = number of agent tabs
/// - Agent count updates: O(1) via reactive ListenableBuilder
/// - Tab close operations: O(1) - direct callback to parent
/// - Memory usage: O(n) for tab widget instances
import 'package:flutter/material.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/services/services.dart';

/// Agent tab data structure for tab management
class AgentTab {
  final AgentModel agent;
  final String? error;

  const AgentTab({
    required this.agent,
    this.error,
  });

  AgentTab copyWith({
    AgentModel? agent,
    String? error,
  }) {
    return AgentTab(
      agent: agent ?? this.agent,
      error: error ?? this.error,
    );
  }
}

/// AgentTabBar - Reactive tab bar for agent management
class AgentTabBar extends StatelessWidget {
  final TabController tabController;
  final List<AgentTab> agentTabs;
  final void Function(int index) onCloseTab;

  const AgentTabBar({
    super.key,
    required this.tabController,
    required this.agentTabs,
    required this.onCloseTab,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: services.agentService,
      builder: (context, child) {
        return TabBar(
          controller: tabController,
          isScrollable: true,
          tabs: [
            // Agents list tab - ARCHITECTURAL: Reactive agent count
            Tab(
              icon: const Icon(Icons.group),
              text: 'Agents (${services.agentService.data.length})',
            ),
            // Agent conversation tabs
            ...agentTabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              return Tab(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.agent.isProcessing
                        ? Icons.hourglass_empty
                        : Icons.chat),
                    if (tab.error != null)
                      const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onCloseTab(index),
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
                text: tab.agent.name,
              );
            }),
          ],
        );
      },
    );
  }
}
