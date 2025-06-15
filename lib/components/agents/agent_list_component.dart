/// AgentListComponent - Multi-Agent Management Interface
library;

///
/// ## MISSION ACCOMPLISHED
/// Eliminates single-agent limitation by providing comprehensive agent management UI.
/// Shows all agents, their status, allows switching, and provides agent creation/management.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builders | Simple | Not reusable | ELIMINATED - violates architecture |
/// | Component Extraction | Reusable + testable | Extra files | CHOSEN - architectural excellence |
/// | ListView | Performant | Complex state | CHOSEN - handles large agent lists |
/// | GridView | Visual appeal | Space inefficient | Rejected - agents are list-oriented |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Agent Discovery Challenge**
///    - 🔍 Symptom: No visibility into available agents
///    - 🎯 Root Cause: No agent list interface
///    - 💥 Kill Shot: Comprehensive agent list with status indicators
///
/// 2. **Agent Switching Difficulty**
///    - 🔍 Symptom: No way to switch between agents
///    - 🎯 Root Cause: Single-agent UI design
///    - 💥 Kill Shot: One-tap agent switching with visual feedback
///
/// 3. **Agent Status Confusion**
///    - 🔍 Symptom: Can't tell which agents are active/processing
///    - 🎯 Root Cause: No status visualization
///    - 💥 Kill Shot: Real-time status indicators with color coding
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Agent list rendering: O(n) where n = number of agents
/// - Agent switching: O(1) - direct callback execution
/// - Status updates: O(1) - reactive stream updates
import 'package:flutter/material.dart';
import 'package:vibe_coder/models/agent_model.dart';

/// AgentListComponent - Comprehensive Agent Management Interface
///
/// ARCHITECTURAL: Zero functional widget builders - all UI components properly extracted.
/// Provides agent list display, status indicators, and management actions.
/// 🎯 ENHANCED: Now includes Edit capability for agent configuration updates
class AgentListComponent extends StatelessWidget {
  final List<AgentModel> agents;
  final String? currentAgentId;
  final bool isLoading;
  final String? errorMessage;
  final void Function(AgentModel agent) onAgentSelected;
  final void Function() onCreateAgent;
  final void Function(String agentId) onDeleteAgent;
  final void Function(String agentId) onViewAgent;
  final void Function(String agentId) onEditAgent;

  const AgentListComponent({
    super.key,
    required this.agents,
    this.currentAgentId,
    this.isLoading = false,
    this.errorMessage,
    required this.onAgentSelected,
    required this.onCreateAgent,
    required this.onDeleteAgent,
    required this.onViewAgent,
    required this.onEditAgent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with create button
        AgentListHeader(
          agentCount: agents.length,
          onCreateAgent: onCreateAgent,
          isLoading: isLoading,
        ),

        // Error display
        if (errorMessage != null)
          AgentListErrorDisplay(errorMessage: errorMessage!),

        // Agent list
        Expanded(
          child: agents.isEmpty
              ? const AgentListEmptyState()
              : AgentListView(
                  agents: agents,
                  currentAgentId: currentAgentId,
                  onAgentSelected: onAgentSelected,
                  onDeleteAgent: onDeleteAgent,
                  onViewAgent: onViewAgent,
                  onEditAgent: onEditAgent,
                ),
        ),
      ],
    );
  }
}

/// AgentListHeader - Header with agent count and create button
///
/// ARCHITECTURAL: Extracted component following Flutter architecture rules
class AgentListHeader extends StatelessWidget {
  final int agentCount;
  final void Function() onCreateAgent;
  final bool isLoading;

  const AgentListHeader({
    super.key,
    required this.agentCount,
    required this.onCreateAgent,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.group,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agents',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                Text(
                  '$agentCount agent${agentCount != 1 ? 's' : ''} available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: isLoading ? null : onCreateAgent,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add, size: 18),
            label: const Text('Create Agent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

/// AgentListErrorDisplay - Error message display
///
/// ARCHITECTURAL: Extracted component for error handling
class AgentListErrorDisplay extends StatelessWidget {
  final String errorMessage;

  const AgentListErrorDisplay({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// AgentListEmptyState - Empty state when no agents exist
///
/// ARCHITECTURAL: Extracted component for empty state handling
class AgentListEmptyState extends StatelessWidget {
  const AgentListEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Agents Available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).disabledColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first agent to get started',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
        ],
      ),
    );
  }
}

/// AgentListView - Main agent list display
///
/// ARCHITECTURAL: Extracted component for list rendering
/// 🎯 ENHANCED: Now includes Edit capability for agent configuration updates
class AgentListView extends StatelessWidget {
  final List<AgentModel> agents;
  final String? currentAgentId;
  final void Function(AgentModel agent) onAgentSelected;
  final void Function(String agentId) onDeleteAgent;
  final void Function(String agentId) onViewAgent;
  final void Function(String agentId) onEditAgent;

  const AgentListView({
    super.key,
    required this.agents,
    this.currentAgentId,
    required this.onAgentSelected,
    required this.onDeleteAgent,
    required this.onViewAgent,
    required this.onEditAgent,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: agents.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final agent = agents[index];
        final isSelected = agent.id == currentAgentId;

        return AgentListItem(
          agent: agent,
          isSelected: isSelected,
          onTap: () => onAgentSelected(agent),
          onDelete: () => onDeleteAgent(agent.id),
          onView: () => onViewAgent(agent.id),
          onEdit: () => onEditAgent(agent.id),
        );
      },
    );
  }
}

/// AgentListItem - Individual agent item in the list
///
/// ARCHITECTURAL: Extracted component for agent item display
/// 🎯 ENHANCED: Now includes Edit capability for agent configuration updates
class AgentListItem extends StatelessWidget {
  final AgentModel agent;
  final bool isSelected;
  final void Function() onTap;
  final void Function() onDelete;
  final void Function() onView;
  final void Function() onEdit;

  const AgentListItem({
    super.key,
    required this.agent,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isSelected ? 4 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                )
              : null,
        ),
        child: ListTile(
          leading: AgentStatusIndicator(
            status: _getAgentStatus(agent),
            isSelected: isSelected,
          ),
          title: Text(
            agent.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).primaryColor : null,
            ),
          ),
          subtitle: AgentSubtitle(agent: agent),
          trailing: AgentActions(
            onView: onView,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
          onTap: onTap,
          selected: isSelected,
        ),
      ),
    );
  }

  AgentStatus _getAgentStatus(AgentModel agent) {
    if (agent.isProcessing) return AgentStatus.processing;
    if (agent.isActive) return AgentStatus.active;
    return AgentStatus.inactive;
  }
}

/// AgentStatusIndicator - Visual status indicator for agents
///
/// ARCHITECTURAL: Extracted component for status visualization
class AgentStatusIndicator extends StatelessWidget {
  final AgentStatus status;
  final bool isSelected;

  const AgentStatusIndicator({
    super.key,
    required this.status,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getStatusColor(context),
        border: isSelected
            ? Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              )
            : null,
      ),
      child: Icon(
        _getStatusIcon(),
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    switch (status) {
      case AgentStatus.active:
        return Colors.green;
      case AgentStatus.processing:
        return Colors.orange;
      case AgentStatus.inactive:
        return Colors.grey;
      case AgentStatus.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case AgentStatus.active:
        return Icons.smart_toy;
      case AgentStatus.processing:
        return Icons.refresh;
      case AgentStatus.inactive:
        return Icons.pause;
      case AgentStatus.error:
        return Icons.error;
    }
  }
}

/// AgentSubtitle - Agent subtitle with metadata
///
/// ARCHITECTURAL: Extracted component for agent metadata display
class AgentSubtitle extends StatelessWidget {
  final AgentModel agent;

  const AgentSubtitle({
    super.key,
    required this.agent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          agent.displaySummary,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (agent.hasConversation) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Text(
                'Last active: ${_formatLastActive(agent.lastActiveAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// AgentActions - Action buttons for agents
///
/// ARCHITECTURAL: Extracted component for agent actions
/// 🎯 ENHANCED: Now includes Edit option for updating agent configurations
class AgentActions extends StatelessWidget {
  final void Function() onView;
  final void Function() onEdit;
  final void Function() onDelete;

  const AgentActions({
    super.key,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'view':
            onView();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edit Settings', style: TextStyle(color: Colors.blue)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 18),
              SizedBox(width: 8),
              Text('View Details'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
