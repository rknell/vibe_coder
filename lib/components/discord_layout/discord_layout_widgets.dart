import 'package:flutter/material.dart';
import '../../models/agent_model.dart';
import 'left_sidebar_panel.dart';
import 'center_chat_panel.dart';
import 'right_sidebar_panel.dart';
import '../../services/services.dart';

/// Discord-style responsive layout widget
class DiscordResponsiveLayoutWidget extends StatelessWidget {
  /// Constraints for responsive calculations
  final BoxConstraints constraints;

  /// Animation controllers and values
  final AnimationController leftSidebarController;
  final AnimationController rightSidebarController;
  final Animation<double> leftSidebarAnimation;
  final Animation<double> rightSidebarAnimation;

  /// Current sidebar widths
  final double currentLeftWidth;
  final double currentRightWidth;

  /// Selected agent
  final AgentModel? selectedAgent;

  /// Callbacks
  final void Function(AgentModel?) onAgentSelected;
  final void Function() onCreateAgent;
  final void Function() onThemeToggle;
  final void Function() onToggleLeftSidebar;
  final void Function() onToggleRightSidebar;
  final void Function(AgentModel, String)? onSendMessage;
  final void Function(AgentModel)? onClearConversation;
  final void Function(AgentModel) onAgentEdit;
  final void Function(double, bool) onPanelResize;
  final VoidCallback? onDebugOverlay;

  /// Creates a Discord responsive layout widget
  ///
  /// ## 🏆 COMPONENT CONQUEST REPORT
  ///
  /// ### 🎯 MISSION ACCOMPLISHED
  /// Extracted functional widget builder `_buildResponsiveLayout` from DiscordHomeScreen
  /// into proper StatelessWidget component following Flutter architecture protocols.
  ///
  /// ### ⚔️ STRATEGIC DECISIONS
  /// | Option | Power-Ups | Weaknesses | Victory Reason |
  /// |--------|-----------|------------|----------------|
  /// | StatelessWidget | Zero state, pure display, reusable | Complex params | Perfect for layout display |
  /// | Extract as component | Clean architecture, testable | Parameter overhead | Architecture compliance |
  /// | Keep as builder | Simple code | Violates protocols | BANNED by flutter_architecture.mdc |
  ///
  /// ### 💀 BOSS FIGHTS DEFEATED
  /// 1. **Functional Widget Builder Violation**
  ///    - 🔍 Symptom: _buildResponsiveLayout method creating UI imperatively
  ///    - 🎯 Root Cause: Architecture protocol violation - functional builders banned
  ///    - 💥 Kill Shot: Extracted to StatelessWidget with comprehensive parameter set
  ///
  /// ### 🚀 PERFORMANCE PROFILE
  /// - Widget creation: O(1) - Direct widget instantiation
  /// - Layout calculation: O(1) - responsive breakpoint evaluation
  /// - Memory usage: Minimal - Single layout container
  /// - Rebuild efficiency: Optimal - Pure StatelessWidget with immutable props
  ///
  /// ### 🎮 USAGE PATTERNS
  /// ```dart
  /// DiscordResponsiveLayoutWidget(
  ///   constraints: constraints,
  ///   leftSidebarAnimation: _leftSidebarAnimation,
  ///   // ... other parameters
  /// )
  /// ```
  ///
  /// ### 🛡️ ARCHITECTURAL COMPLIANCE
  /// - ✅ StatelessWidget component extraction
  /// - ✅ Object-oriented parameter passing (whole objects and callbacks)
  /// - ✅ Immutable widget design
  /// - ✅ Zero functional widget builders
  /// - ✅ Component separation following warrior protocols
  const DiscordResponsiveLayoutWidget({
    super.key,
    required this.constraints,
    required this.leftSidebarController,
    required this.rightSidebarController,
    required this.leftSidebarAnimation,
    required this.rightSidebarAnimation,
    required this.currentLeftWidth,
    required this.currentRightWidth,
    required this.selectedAgent,
    required this.onAgentSelected,
    required this.onCreateAgent,
    required this.onThemeToggle,
    required this.onToggleLeftSidebar,
    required this.onToggleRightSidebar,
    required this.onSendMessage,
    required this.onClearConversation,
    required this.onAgentEdit,
    required this.onPanelResize,
    this.onDebugOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = constraints.maxWidth;
    final layoutService = services.layoutService;

    // Determine sidebar visibility based on responsive breakpoints
    final shouldShowLeftSidebar = _shouldShowLeftSidebar(screenWidth);
    final shouldShowRightSidebar = _shouldShowRightSidebar(screenWidth);

    return Row(
      children: [
        // Left Sidebar Panel - Agent Management (Animated)
        if (shouldShowLeftSidebar) ...[
          AnimatedBuilder(
            animation: leftSidebarAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -currentLeftWidth * (1 - leftSidebarAnimation.value),
                  0,
                ),
                child: SizedBox(
                  width: currentLeftWidth,
                  child: LeftSidebarPanel(
                    width: currentLeftWidth,
                    selectedAgent: selectedAgent,
                    onAgentSelected: onAgentSelected,
                    onCreateAgent: onCreateAgent,
                  ),
                ),
              );
            },
          ),

          // Left panel resize handle
          DiscordPanelDividerWidget(
            isLeft: true,
            onPanelResize: onPanelResize,
          ),
        ],

        // Center Chat Panel - Main Content (Flexible)
        Expanded(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 400, // minCenterPanelWidth
            ),
            child: CenterChatPanel(
              currentTheme: layoutService.currentTheme,
              selectedAgent: selectedAgent,
              onThemeToggle: onThemeToggle,
              onToggleLeftSidebar: onToggleLeftSidebar,
              onToggleRightSidebar: onToggleRightSidebar,
              onSendMessage: onSendMessage,
              onClearConversation: onClearConversation,
              onAgentEdit: onAgentEdit,
              onDebugOverlay: onDebugOverlay,
            ),
          ),
        ),

        // Right MCP Sidebar Panel - Content Management (Animated)
        if (shouldShowRightSidebar) ...[
          // Right panel resize handle
          DiscordPanelDividerWidget(
            isLeft: false,
            onPanelResize: onPanelResize,
          ),

          AnimatedBuilder(
            animation: rightSidebarAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  currentRightWidth * (1 - rightSidebarAnimation.value),
                  0,
                ),
                child: SizedBox(
                  width: currentRightWidth,
                  child: RightSidebarPanel(
                    width: currentRightWidth,
                    selectedAgent: selectedAgent,
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  /// Determine if left sidebar should be visible
  bool _shouldShowLeftSidebar(double screenWidth) {
    const mobileBreakpoint = 768.0;

    if (screenWidth < mobileBreakpoint) {
      return false; // Auto-hide on mobile
    }

    // Check layout service preferences - animation will handle the visual transition
    return !services.layoutService.leftSidebarCollapsed;
  }

  /// Determine if right sidebar should be visible
  bool _shouldShowRightSidebar(double screenWidth) {
    const tabletBreakpoint = 1024.0;

    if (screenWidth < tabletBreakpoint) {
      return false; // Auto-hide on tablet and below
    }

    // Check layout service preferences - animation will handle the visual transition
    return !services.layoutService.rightSidebarCollapsed;
  }
}

/// Discord-style panel divider widget
class DiscordPanelDividerWidget extends StatelessWidget {
  /// Whether this is the left panel divider
  final bool isLeft;

  /// Callback for panel resize
  final void Function(double, bool) onPanelResize;

  /// Creates a Discord panel divider widget
  ///
  /// ## 🏆 COMPONENT CONQUEST REPORT
  ///
  /// ### 🎯 MISSION ACCOMPLISHED
  /// Extracted functional widget builder `_buildPanelDivider` from DiscordHomeScreen
  /// into proper StatelessWidget component following Flutter architecture protocols.
  ///
  /// ### ⚔️ STRATEGIC DECISIONS
  /// | Option | Power-Ups | Weaknesses | Victory Reason |
  /// |--------|-----------|------------|----------------|
  /// | StatelessWidget | Zero state, pure display, reusable | None | Perfect for divider display |
  /// | Extract as component | Clean architecture, testable | Slight complexity | Architecture compliance |
  /// | Keep as builder | Simple code | Violates protocols | BANNED by flutter_architecture.mdc |
  ///
  /// ### 💀 BOSS FIGHTS DEFEATED
  /// 1. **Functional Widget Builder Violation**
  ///    - 🔍 Symptom: _buildPanelDivider method creating UI imperatively
  ///    - 🎯 Root Cause: Architecture protocol violation - functional builders banned
  ///    - 💥 Kill Shot: Extracted to StatelessWidget with callback integration
  ///
  /// ### 🚀 PERFORMANCE PROFILE
  /// - Widget creation: O(1) - Direct widget instantiation
  /// - Mouse interaction: O(1) - simple gesture detection
  /// - Memory usage: Minimal - Single divider container
  /// - Rebuild efficiency: Optimal - Pure StatelessWidget with immutable props
  ///
  /// ### 🎮 USAGE PATTERNS
  /// ```dart
  /// DiscordPanelDividerWidget(
  ///   isLeft: true,
  ///   onPanelResize: _handlePanelResize,
  /// )
  /// ```
  ///
  /// ### 🛡️ ARCHITECTURAL COMPLIANCE
  /// - ✅ StatelessWidget component extraction
  /// - ✅ Object-oriented parameter passing (callback function)
  /// - ✅ Immutable widget design
  /// - ✅ Zero functional widget builders
  /// - ✅ Component separation following warrior protocols
  const DiscordPanelDividerWidget({
    super.key,
    required this.isLeft,
    required this.onPanelResize,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onPanUpdate: (details) => onPanelResize(details.delta.dx, isLeft),
        child: Container(
          width: 4,
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
