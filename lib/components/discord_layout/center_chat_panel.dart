import 'package:flutter/material.dart';
import 'package:vibe_coder/models/layout_preferences_model.dart';

/// CenterChatPanel - Main Chat Content Panel
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **IMPLEMENTS COMPONENT ARCHITECTURE** - Creates reusable center chat panel
/// from DiscordHomeScreen into proper StatelessWidget component following
/// Flutter Architecture Protocol.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Expanded Container | Flexible sizing, Discord-style | Requires parent Row | CHOSEN - matches original implementation |
/// | Fixed Width | Predictable sizing | Not responsive | REJECTED - center panel should be flexible |
/// | Scaffold Body | Full structure | Overkill for panel | REJECTED - panel component not screen |
/// | MessagingUI Direct | Immediate integration | Tight coupling | REJECTED - placeholder first for foundation |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Crime**
///    - 🔍 Symptom: Center chat panel logic embedded in parent screen widget
///    - 🎯 Root Cause: Widget logic embedded in StatefulWidget build method
///    - 💥 Kill Shot: Extracted to reusable StatelessWidget component
///
/// 2. **Theme Toggle Integration Challenge**
///    - 🔍 Symptom: Theme switching logic scattered throughout build method
///    - 🎯 Root Cause: Theme button embedded in functional builder
///    - 💥 Kill Shot: Clean theme toggle with callback pattern
///
/// 3. **Chat Panel Flexibility Limitation**
///    - 🔍 Symptom: Chat panel logic not reusable across different layouts
///    - 🎯 Root Cause: Tight coupling to DiscordHomeScreen implementation
///    - 💥 Kill Shot: Standalone component with clear prop interface
///
/// ## PERFORMANCE PROFILE
/// - Widget creation: O(1) - Container with Column structure
/// - Theme application: O(1) - Theme.of(context) lookups
/// - Layout calculation: O(1) - flexible sizing within parent Row
/// - Memory usage: O(1) - stateless widget with minimal properties
/// - Rebuild efficiency: O(1) - rebuilds only when parent triggers rebuild
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatelessWidget (mandatory for UI components)
/// ✅ Zero functional widget builders (pure component)
/// ✅ Object-oriented callback pattern (onThemeToggle prop)
/// ✅ Theme integration (respects app theme)
/// ✅ Single responsibility (chat panel display only)
/// ✅ Flexible design (works within Row layout)
class CenterChatPanel extends StatelessWidget {
  /// Current theme for theme toggle button
  final AppTheme currentTheme;

  /// Callback for theme toggle button
  final VoidCallback? onThemeToggle;

  const CenterChatPanel({
    super.key,
    required this.currentTheme,
    this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Panel header
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),

                // Theme toggle button
                IconButton(
                  onPressed: onThemeToggle,
                  icon: Icon(_getThemeIcon(currentTheme)),
                  tooltip: 'Toggle theme',
                ),
              ],
            ),
          ),

          // Panel content - Placeholder for chat interface
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Discord-Style Chat Panel',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Integration with MessagingUI pending',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get theme icon based on current theme
  ///
  /// PERF: O(1) - simple switch statement
  IconData _getThemeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.dark:
        return Icons.dark_mode_outlined;
      case AppTheme.light:
        return Icons.light_mode_outlined;
      case AppTheme.system:
        return Icons.brightness_auto_outlined;
    }
  }
}
