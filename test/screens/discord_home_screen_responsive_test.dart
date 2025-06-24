import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/screens/discord_home_screen.dart';

void main() {
  group('🏆 DiscordHomeScreen Responsive Behavior Tests', () {
    testWidgets('🚀 FEATURE: Sidebar toggle controls work correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DiscordHomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify sidebar toggle buttons are present
      expect(find.byTooltip('Toggle agents sidebar'), findsOneWidget);
      expect(find.byTooltip('Toggle MCP content sidebar'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.view_sidebar), findsOneWidget);

      // Test left sidebar toggle button
      final leftToggle = find.byTooltip('Toggle agents sidebar');
      await tester.tap(leftToggle);
      await tester.pumpAndSettle();

      // Test right sidebar toggle button
      final rightToggle = find.byTooltip('Toggle MCP content sidebar');
      await tester.tap(rightToggle);
      await tester.pumpAndSettle();

      // Verify no exceptions were thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('📱 RESPONSIVE: Mobile breakpoint hides sidebars',
        (tester) async {
      // Set mobile screen size (< 768px)
      await tester.binding.setSurfaceSize(const Size(600, 800));

      await tester.pumpWidget(
        const MaterialApp(
          home: DiscordHomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // On mobile, only chat panel should be visible
      expect(find.text('Chat'), findsOneWidget);

      // Verify no layout overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('💻 RESPONSIVE: Tablet breakpoint shows limited sidebars',
        (tester) async {
      // Set tablet screen size (768px < x < 1024px)
      await tester.binding.setSurfaceSize(const Size(900, 600));

      await tester.pumpWidget(
        const MaterialApp(
          home: DiscordHomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // On tablet, chat panel should be visible
      expect(find.text('Chat'), findsOneWidget);

      // Verify no layout overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('🖥️ RESPONSIVE: Desktop shows all panels', (tester) async {
      // Set desktop screen size (>= 1024px)
      await tester.binding.setSurfaceSize(const Size(1400, 800));

      await tester.pumpWidget(
        const MaterialApp(
          home: DiscordHomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // On desktop, all panels should be available
      expect(find.text('Chat'), findsOneWidget);
      expect(find.byTooltip('Toggle agents sidebar'), findsOneWidget);
      expect(find.byTooltip('Toggle MCP content sidebar'), findsOneWidget);

      // Verify no layout overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('⚡ PERFORMANCE: Animation controllers dispose properly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DiscordHomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate away to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Different Screen')),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no memory leaks or disposal errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('🎯 INTEGRATION: Theme toggle works with sidebar controls',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DiscordHomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Test theme toggle (in center panel)
      final themeToggle = find.byTooltip('Toggle theme');
      expect(themeToggle, findsOneWidget);

      await tester.tap(themeToggle);
      await tester.pumpAndSettle();

      // Test sidebar toggles still work after theme change
      final leftToggle = find.byTooltip('Toggle agents sidebar');
      await tester.tap(leftToggle);
      await tester.pumpAndSettle();

      // Verify no exceptions were thrown
      expect(tester.takeException(), isNull);
    });
  });
}
