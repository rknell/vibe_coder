import 'package:flutter/material.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/components/agents/agent_list_item.dart';
import 'package:vibe_coder/services/services.dart';

/// CreateAgentButton - Discord-style Create Agent Button
///
/// COMPONENT ARCHITECTURE: Extracted from functional widget builder
/// Provides consistent create agent button across different states
class CreateAgentButton extends StatelessWidget {
  final void Function()? onCreateAgent;

  const CreateAgentButton({
    super.key,
    this.onCreateAgent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onCreateAgent,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create Agent'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

/// EmptyAgentState - Discord-style Empty State Display
///
/// COMPONENT ARCHITECTURE: Extracted from functional widget builder
/// Provides empty state UI when no agents exist
class EmptyAgentState extends StatelessWidget {
  final void Function()? onCreateAgent;

  const EmptyAgentState({
    super.key,
    this.onCreateAgent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Agents Yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first AI agent to get started',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Create agent button
        CreateAgentButton(onCreateAgent: onCreateAgent),
      ],
    );
  }
}

/// AgentList - Discord-style Agent List Display
///
/// COMPONENT ARCHITECTURE: Extracted from functional widget builder
/// Provides agent list with ListView.builder
class AgentList extends StatelessWidget {
  final List<AgentModel> agents;
  final AgentModel? selectedAgent;
  final void Function(AgentModel)? onAgentSelected;
  final void Function()? onCreateAgent;

  const AgentList({
    super.key,
    required this.agents,
    this.selectedAgent,
    this.onAgentSelected,
    this.onCreateAgent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Agent list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: agents.length,
            itemBuilder: (context, index) {
              final agent = agents[index];
              final isSelected = selectedAgent?.id == agent.id;

              return AgentListItem(
                agent: agent, // Pass whole object (single source of truth)
                isSelected: isSelected,
                onTap: (selectedAgent) => onAgentSelected?.call(selectedAgent),
              );
            },
          ),
        ),

        // Create agent button
        CreateAgentButton(onCreateAgent: onCreateAgent),
      ],
    );
  }
}

/// AgentSidebarComponent - Discord-style Agent Management Sidebar
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **IMPLEMENTS COMPONENT ARCHITECTURE** - Creates interactive agent sidebar
/// with real agent data, status indicators, selection management, and creation integration.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | ListView.builder | Dynamic sizing, efficient | Complex for simple lists | CHOSEN - scales with agent count |
/// | Column + SingleChildScrollView | Simple structure | No virtualization | REJECTED - need efficient scrolling |
/// | Expanded ListView | Fits parent, scrollable | Static content assumption | REJECTED - dynamic agent lists |
/// | GridView | Multi-column layout | Overkill for agent list | REJECTED - single column needed |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **PlaceholderAgentList Replacement**
///    - 🔍 Symptom: Placeholder component with static fake agents
///    - 🎯 Root Cause: No integration with real AgentService data
///    - 💥 Kill Shot: ListenableBuilder + AgentService integration for reactive real agents
///
/// 2. **Agent Selection Coordination**
///    - 🔍 Symptom: Need to track selected agent across app
///    - 🎯 Root Cause: Agent selection state needs global coordination
///    - 💥 Kill Shot: Object-oriented callback pattern with AgentModel reference
///
/// 3. **Empty State Handling**
///    - 🔍 Symptom: UI needs graceful handling when no agents exist
///    - 🎯 Root Cause: New users start with empty agent collection
///    - 💥 Kill Shot: EmptyAgentState component with call-to-action for agent creation
///
/// ## PERFORMANCE PROFILE
/// - Widget creation: O(1) - ListenableBuilder with conditional rendering
/// - Agent list rendering: O(n) where n = number of agents
/// - Selection updates: O(1) - direct comparison and callback
/// - Memory usage: O(n) - stores agent references, not copies
/// - Rebuild efficiency: O(n) - rebuilds only when agent collection changes
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatelessWidget (mandatory for UI components)
/// ✅ Zero functional widget builders (uses component composition)
/// ✅ Object-oriented interface (AgentModel references throughout)
/// ✅ Single source of truth (AgentService data, no duplication)
/// ✅ Component composition (uses AgentList, EmptyAgentState, CreateAgentButton)
/// ✅ Reactive updates (ListenableBuilder for agent changes)
class AgentSidebarComponent extends StatelessWidget {
  /// Width of the sidebar component
  final double width;

  /// Currently selected agent (for highlighting)
  final AgentModel? selectedAgent;

  /// Callback when an agent is selected (object-oriented pattern)
  final void Function(AgentModel)? onAgentSelected;

  /// Callback when create agent is requested
  final void Function()? onCreateAgent;

  const AgentSidebarComponent({
    super.key,
    required this.width,
    this.selectedAgent,
    this.onAgentSelected,
    this.onCreateAgent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ListenableBuilder(
        listenable: services.agentService,
        builder: (context, child) {
          final agents = services.agentService.data;

          if (agents.isEmpty) {
            return EmptyAgentState(onCreateAgent: onCreateAgent);
          }

          return AgentList(
            agents: agents,
            selectedAgent: selectedAgent,
            onAgentSelected: onAgentSelected,
            onCreateAgent: onCreateAgent,
          );
        },
      ),
    );
  }
}
