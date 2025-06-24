import 'package:flutter/material.dart';
import 'package:vibe_coder/models/layout_preferences_model.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/services/services.dart';
import 'package:vibe_coder/components/discord_layout/left_sidebar_panel.dart';
import 'package:vibe_coder/components/discord_layout/center_chat_panel.dart';
import 'package:vibe_coder/components/discord_layout/right_sidebar_panel.dart';
import 'package:vibe_coder/components/agents/agent_settings_dialog.dart';

/// DiscordHomeScreen - Three-Panel Layout Foundation
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **ESTABLISHES DISCORD-STYLE THREE-PANEL LAYOUT** with foundational structure
/// for agent sidebar, chat panel, and MCP content sidebar integration.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Three-Panel Row | Discord consistency | Fixed layout | CHOSEN - matches Discord UX |
/// | Flexible Grid | Responsive design | Complexity | REJECTED - premature optimization |
/// | Nested Containers | Simple structure | Limited flexibility | CHOSEN - foundation first |
/// | Custom Layout | Maximum control | High complexity | REJECTED - overengineering |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Layout Structure Foundation**
///    - 🔍 Symptom: Single-panel chat interface limiting Discord-style UX
///    - 🎯 Root Cause: No three-panel layout foundation for sidebar integration
///    - 💥 Kill Shot: Row-based three-panel structure with fixed panel widths
///
/// 2. **LayoutService Integration**
///    - 🔍 Symptom: Hardcoded layout dimensions and theme settings
///    - 🎯 Root Cause: No reactive layout service integration
///    - 💥 Kill Shot: ListenableBuilder with LayoutService for reactive updates
///
/// 3. **Component Integration Foundation**
///    - 🔍 Symptom: No structure for specialized sidebar components
///    - 🎯 Root Cause: Missing placeholder infrastructure for component development
///    - 💥 Kill Shot: Placeholder components with clear integration points
///
/// ## PERFORMANCE PROFILE
/// - Layout rendering: O(1) - three-panel Row structure
/// - Theme switching: O(1) - ListenableBuilder reactive updates
/// - Panel sizing: O(1) - fixed width calculations
/// - Component integration: O(1) - direct widget composition
/// - Memory usage: O(1) - minimal state tracking
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatefulWidget for screen orchestration (mandatory for screens)
/// ✅ ListenableBuilder for reactive layout updates
/// ✅ Zero functional widget builders (extracted to proper methods)
/// ✅ Component composition pattern for panel content
/// ✅ Object-oriented LayoutService integration
/// ✅ Single source of truth via LayoutService
class DiscordHomeScreen extends StatefulWidget {
  const DiscordHomeScreen({super.key});

  @override
  State<DiscordHomeScreen> createState() => _DiscordHomeScreenState();
}

class _DiscordHomeScreenState extends State<DiscordHomeScreen> {
  // Panel dimension constants - Discord-style fixed layout
  static const double leftSidebarWidth = 250.0;
  static const double rightSidebarWidth = 300.0;

  // Agent selection state
  AgentModel? _selectedAgent;

  @override
  void initState() {
    super.initState();
    // Initialize services if needed (but they should already be initialized)
    _ensureServicesInitialized();
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: services.layoutService,
        builder: (context, child) {
          final layoutService = services.layoutService;

          return Row(
            children: [
              // Left Sidebar Panel - Agent Management
              LeftSidebarPanel(
                width: leftSidebarWidth,
                selectedAgent: _selectedAgent,
                onAgentSelected: _handleAgentSelected,
                onCreateAgent: _handleCreateAgent,
              ),

              // Center Chat Panel - Main Content (Flexible)
              Expanded(
                child: CenterChatPanel(
                  currentTheme: layoutService.currentTheme,
                  onThemeToggle: _handleThemeToggle,
                ),
              ),

              // Right MCP Sidebar Panel - Content Management
              RightSidebarPanel(
                width: rightSidebarWidth,
              ),
            ],
          );
        },
      ),
    );
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
    try {
      final result = await AgentSettingsDialog.showCreateDialog(context);

      if (result != null) {
        // Agent was created successfully
        await services.agentService.createAgent(
          name: result.name,
          systemPrompt: result.systemPrompt,
          temperature: result.temperature,
          maxTokens: result.maxTokens,
          useBetaFeatures: result.useBetaFeatures,
          useReasonerModel: result.useReasonerModel,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Agent "${result.name}" created successfully'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create agent: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
}
