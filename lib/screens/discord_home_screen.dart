import 'package:flutter/material.dart';
import 'package:vibe_coder/models/layout_preferences_model.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/services/services.dart';
import 'package:vibe_coder/components/discord_layout/discord_layout_widgets.dart';
import 'package:vibe_coder/components/agents/agent_settings_dialog.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';

/// DiscordHomeScreen - Responsive Three-Panel Layout with Animations
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **DISCORD-STYLE RESPONSIVE LAYOUT** with smooth sidebar animations,
/// mobile-friendly behavior, and user-controlled panel resizing.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | AnimatedContainer | Simple to use | Limited control | REJECTED - not smooth enough |
/// | AnimationController | Full control | More complex | CHOSEN - professional animations |
/// | Transform.scale | Performance | Layout issues | REJECTED - breaks panel interaction |
/// | AnimatedSize | Auto-sizing | Clunky behavior | REJECTED - not Discord-style |
/// | Custom Tween | Perfect control | Implementation effort | CHOSEN - smooth transitions |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Sidebar Collapse Animations**
///    - 🔍 Symptom: Static layout with no collapse functionality
///    - 🎯 Root Cause: Missing animation controllers for sidebar transitions
///    - 💥 Kill Shot: AnimationController with Transform.translate for smooth animations
///
/// 2. **Mobile Responsive Behavior**
///    - 🔍 Symptom: Fixed layout breaks on mobile devices
///    - 🎯 Root Cause: No responsive breakpoints or adaptive sidebar behavior
///    - 💥 Kill Shot: LayoutBuilder with breakpoint detection and auto-hide logic
///
/// 3. **State Persistence**
///    - 🔍 Symptom: Sidebar collapsed state lost on app restart
///    - 🎯 Root Cause: Animation state not integrated with LayoutService
///    - 💥 Kill Shot: LayoutService integration for persistent sidebar preferences
///
/// ## PERFORMANCE PROFILE
/// - Animation rendering: O(1) - Transform.translate with GPU acceleration
/// - Responsive calculations: O(1) - MediaQuery-based breakpoint detection
/// - State persistence: O(1) - LayoutService reactive updates
/// - Panel resizing: O(1) - direct width calculations with constraints
/// - Memory usage: O(1) - properly disposed animation controllers
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatefulWidget with TickerProviderStateMixin for animation lifecycle
/// ✅ AnimationController proper disposal in dispose()
/// ✅ LayoutService integration for persistent state management
/// ✅ Mobile-first responsive design with graceful degradation
/// ✅ Object-oriented callback patterns for toggle actions
/// ✅ Single source of truth via LayoutService coordination
class DiscordHomeScreen extends StatefulWidget {
  const DiscordHomeScreen({super.key});

  @override
  State<DiscordHomeScreen> createState() => _DiscordHomeScreenState();
}

class _DiscordHomeScreenState extends State<DiscordHomeScreen>
    with TickerProviderStateMixin {
  // Panel dimension constants - Discord-style adaptive layout
  static const double leftSidebarWidth = 250.0;
  static const double rightSidebarWidth = 300.0;

  // Animation duration - Discord-style timing
  static const Duration animationDuration = Duration(milliseconds: 300);

  // WARRIOR PROTOCOL EXCEPTION: AnimationController requires late initialization for TickerProviderStateMixin
  late AnimationController _leftSidebarController;
  late AnimationController _rightSidebarController;
  late Animation<double> _leftSidebarAnimation;
  late Animation<double> _rightSidebarAnimation;

  // Agent selection state
  AgentModel? _selectedAgent;

  // Current panel widths for resizing
  double _currentLeftWidth = leftSidebarWidth;
  double _currentRightWidth = rightSidebarWidth;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _ensureServicesInitialized();
    _loadPersistedSidebarStates();
  }

  /// Initialize animation controllers and animations
  ///
  /// PERF: O(1) - animation controller setup
  /// ARCHITECTURAL: Proper animation lifecycle management
  void _initializeAnimations() {
    // Left sidebar animation controller
    _leftSidebarController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );

    // Right sidebar animation controller
    _rightSidebarController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );

    // Smooth easing animations - Discord-style feel
    _leftSidebarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _leftSidebarController,
      curve: Curves.easeInOut,
    ));

    _rightSidebarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rightSidebarController,
      curve: Curves.easeInOut,
    ));
  }

  /// Load persisted sidebar states from LayoutService
  ///
  /// PERF: O(1) - state restoration from preferences
  /// INTEGRATION: LayoutService coordination for persistence
  void _loadPersistedSidebarStates() {
    final layoutService = services.layoutService;

    // Initialize animation controllers based on persisted state
    // If sidebar is NOT collapsed, it should be visible (animation value = 1.0)
    if (!layoutService.leftSidebarCollapsed) {
      _leftSidebarController.value = 1.0;
    }

    if (!layoutService.rightSidebarCollapsed) {
      _rightSidebarController.value = 1.0;
    }
  }

  /// Ensure services are initialized for layout coordination
  ///
  /// PERF: O(1) - service initialization check
  /// INTEGRATION: Non-blocking service verification
  void _ensureServicesInitialized() {
    // Services should already be initialized from main app startup
    // This is a safety check for direct screen navigation in testing
    if (!mounted) return;

    // Layout service should be available for theme coordination
    try {
      final layoutService = services.layoutService;
      debugPrint(
          '🎨 DiscordHomeScreen: LayoutService available - Theme: ${layoutService.currentTheme}');
    } catch (e) {
      debugPrint('⚠️ DiscordHomeScreen: Services not fully initialized: $e');
    }
  }

  @override
  void dispose() {
    // WARRIOR PROTOCOL: Proper animation controller disposal
    _leftSidebarController.dispose();
    _rightSidebarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListenableBuilder(
            listenable: services.layoutService,
            builder: (context, child) {
              return DiscordResponsiveLayoutWidget(
                constraints: constraints,
                leftSidebarController: _leftSidebarController,
                rightSidebarController: _rightSidebarController,
                leftSidebarAnimation: _leftSidebarAnimation,
                rightSidebarAnimation: _rightSidebarAnimation,
                currentLeftWidth: _currentLeftWidth,
                currentRightWidth: _currentRightWidth,
                selectedAgent: _selectedAgent,
                onAgentSelected: _handleAgentSelected,
                onCreateAgent: _handleCreateAgent,
                onThemeToggle: _handleThemeToggle,
                onToggleLeftSidebar: _toggleLeftSidebar,
                onToggleRightSidebar: _toggleRightSidebar,
                onSendMessage: _handleSendMessage,
                onClearConversation: _handleClearConversation,
                onAgentEdit: _handleAgentEdit,
                onPanelResize: _handlePanelResize,
              );
            },
          );
        },
      ),
    );
  }

  /// Toggle left sidebar with smooth animation
  ///
  /// PERF: O(1) - animation state toggle
  /// INTEGRATION: LayoutService coordination for state persistence
  void _toggleLeftSidebar() {
    final layoutService = services.layoutService;

    if (_leftSidebarController.value == 1.0) {
      // Collapse sidebar
      _leftSidebarController.reverse();
      layoutService.setLeftSidebarCollapsed(true);
    } else {
      // Expand sidebar
      _leftSidebarController.forward();
      layoutService.setLeftSidebarCollapsed(false);
    }
  }

  /// Toggle right sidebar with smooth animation
  ///
  /// PERF: O(1) - animation state toggle
  /// INTEGRATION: LayoutService coordination for state persistence
  void _toggleRightSidebar() {
    final layoutService = services.layoutService;

    if (_rightSidebarController.value == 1.0) {
      // Collapse sidebar
      _rightSidebarController.reverse();
      layoutService.setRightSidebarCollapsed(true);
    } else {
      // Expand sidebar
      _rightSidebarController.forward();
      layoutService.setRightSidebarCollapsed(false);
    }
  }

  /// Handle panel resize operations
  ///
  /// PERF: O(1) - width calculation with constraints
  /// UX: Smooth resizing with minimum width constraints
  void _handlePanelResize(double delta, bool isLeft) {
    setState(() {
      if (isLeft) {
        _currentLeftWidth = (_currentLeftWidth + delta).clamp(200.0, 400.0);
      } else {
        _currentRightWidth = (_currentRightWidth - delta).clamp(250.0, 500.0);
      }
    });
  }

  /// Handle agent selection
  ///
  /// INTEGRATION: Agent selection coordination with object-oriented pattern
  void _handleAgentSelected(AgentModel agent) {
    setState(() {
      _selectedAgent = agent;
    });

    // Future integration: Update chat service to show selected agent's conversation
    debugPrint('🤖 Agent selected: ${agent.name} (${agent.id})');
  }

  /// Handle create agent action
  ///
  /// INTEGRATION: Real agent creation dialog integration
  void _handleCreateAgent() async {
    if (!mounted) return;

    try {
      final result = await AgentSettingsDialog.showCreateDialog(context);

      if (result != null && mounted) {
        // Agent was created successfully
        await services.agentService.createAgent(
          name: result.name,
          systemPrompt: result.systemPrompt,
          temperature: result.temperature,
          maxTokens: result.maxTokens,
          useBetaFeatures: result.useBetaFeatures,
          useReasonerModel: result.useReasonerModel,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Agent "${result.name}" created successfully'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create agent: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Handle theme toggle action
  ///
  /// INTEGRATION: Cycles through available themes via LayoutService
  void _handleThemeToggle() {
    final layoutService = services.layoutService;
    const themes = AppTheme.values;
    final currentIndex = themes.indexOf(layoutService.currentTheme);
    final nextIndex = (currentIndex + 1) % themes.length;
    layoutService.setTheme(themes[nextIndex]);
  }

  /// Handle message sending to selected agent
  ///
  /// INTEGRATION: Agent conversation management with object-oriented pattern
  void _handleSendMessage(AgentModel agent, String message) {
    // TODO: Integrate with conversation manager for message processing
    debugPrint('💬 Sending message to ${agent.name}: $message');

    // Add user message to agent's conversation history
    // This will be enhanced when conversation manager is integrated
    final userMessage = ChatMessage(
      role: MessageRole.user,
      content: message,
    );
    agent.addMessage(userMessage);
  }

  /// Handle conversation clearing for selected agent
  ///
  /// INTEGRATION: Agent conversation management with confirmation
  void _handleClearConversation(AgentModel agent) {
    debugPrint('🗑️ Clearing conversation for ${agent.name}');

    // Clear the agent's conversation history
    agent.clearConversation();

    // Show confirmation snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cleared conversation with ${agent.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Handle agent editing action
  ///
  /// INTEGRATION: Agent configuration dialog with settings persistence
  void _handleAgentEdit(AgentModel agent) async {
    if (!mounted) return;

    try {
      final result = await AgentSettingsDialog.showEditDialog(context, agent);

      if (result != null && mounted) {
        // Agent was updated successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated ${agent.name} settings'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update agent settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
