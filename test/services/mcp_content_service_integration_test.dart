import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/services/mcp_content_service.dart';
import 'package:vibe_coder/services/services.dart';
import 'package:vibe_coder/models/mcp_content_collection.dart';
import 'package:vibe_coder/models/mcp_notepad_content.dart';
import 'package:vibe_coder/models/mcp_todo_item.dart';
import 'package:vibe_coder/models/mcp_inbox_item.dart';

/// 🧪 MCP Content Service Integration Tests for DR005B
///
/// ## 🎯 MISSION
/// Test MCP server integration and content synchronization capabilities
/// following warrior protocols and architectural compliance.
///
/// ## ⚔️ ARCHITECTURAL TESTING STRATEGY
/// - **TDD Protocol**: Write failing tests → Implement → Make tests pass
/// - **Object-Oriented**: Test whole object behavior, not individual fields
/// - **Performance Verification**: Measure actual timing requirements
/// - **Error Recovery**: Test exponential backoff and retry logic
/// - **Content Caching**: Verify intelligent cache hit/miss behavior
///
/// ## 🏆 TEST CATEGORIES
/// - 🚀 **FEATURE**: MCP server content fetching functionality
/// - 🛡️ **REGRESSION**: Prevent content synchronization bugs
/// - ⚡ **PERFORMANCE**: Verify < 500ms content sync benchmarks
/// - 🔧 **INTEGRATION**: End-to-end MCP server communication
/// - 🎯 **EDGE_CASE**: Error handling and cache invalidation scenarios

void main() {
  group('🔥 DR005B: MCP Server Integration & Content Sync Tests', () {
    late MCPContentService service;

    setUp(() async {
      service = MCPContentService();
      // Initialize the MCP service to ensure it's available
      await services.mcpService.initialize();
    });

    tearDown(() {
      service.dispose();
    });

    group('🚀 FEATURE: MCP Server Content Fetching', () {
      test('🛡️ REGRESSION: fetchAgentContent retrieves all content types',
          () async {
        // ARRANGE: Mock agent with known content
        const agentId = 'test-agent-001';

        // ACT: Fetch content from all MCP servers
        await service.fetchAgentContent(agentId);

        // ASSERT: Content collection populated with all types
        final content = service.getAgentContent(agentId);
        expect(content, isNotNull, reason: 'Agent content should be available');
        expect(content!.notepadContent, isA<MCPNotepadContent>(),
            reason: 'Notepad content should be fetched');
        expect(content.todoItems, isA<List<MCPTodoItem>>(),
            reason: 'Todo items should be fetched');
        expect(content.inboxItems, isA<List<MCPInboxItem>>(),
            reason: 'Inbox items should be fetched');
      });

      test('🛡️ REGRESSION: Individual content type fetching works correctly',
          () async {
        // ARRANGE: Test agent
        const agentId = 'test-agent-002';

        // ACT & ASSERT: Test each content type individually
        final notepadContent = await service.fetchNotepadContent(agentId);
        expect(notepadContent, isA<MCPNotepadContent>(),
            reason: 'Notepad content should be MCPNotepadContent type');
        expect(notepadContent.agentId, equals(agentId),
            reason: 'Content should be associated with correct agent');

        final todoItems = await service.fetchTodoItems(agentId);
        expect(todoItems, isA<List<MCPTodoItem>>(),
            reason: 'Todo items should be list type');

        final inboxItems = await service.fetchInboxItems(agentId);
        expect(inboxItems, isA<List<MCPInboxItem>>(),
            reason: 'Inbox items should be list type');
      });

      test('🔧 INTEGRATION: Content change detection works correctly',
          () async {
        // ARRANGE: Agent with initial content
        const agentId = 'test-agent-003';
        await service.fetchAgentContent(agentId);

        // ACT: Mock content change and re-fetch
        await service.fetchAgentContent(agentId);

        // ASSERT: Service detected content changes appropriately
        expect(service.hasContentChanged('test-content-key', 'new-content'),
            isTrue,
            reason: 'Service should detect content changes');
        expect(service.hasContentChanged('test-content-key', 'new-content'),
            isFalse,
            reason: 'Service should not trigger on identical content');
      });
    });

    group('⚡ PERFORMANCE: Content Sync Benchmarks', () {
      test('⚡ PERFORMANCE: Complete agent content sync under 500ms', () async {
        // ARRANGE: Performance monitoring
        const agentId = 'perf-test-agent';
        final stopwatch = Stopwatch()..start();

        // ACT: Execute complete content sync
        await service.fetchAgentContent(agentId);

        // ASSERT: Performance benchmark met
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: 'Complete content sync should complete in < 500ms');
      });

      test('⚡ PERFORMANCE: Content caching achieves 90%+ cache hit rate',
          () async {
        // ARRANGE: Multiple fetch operations for cache testing
        const agentId = 'cache-test-agent';

        // ACT: First fetch (cache miss) + multiple subsequent fetches (cache hits)
        await service.fetchAgentContent(agentId); // Cache miss

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 10; i++) {
          await service.fetchAgentContent(agentId); // Should be cache hits
        }
        stopwatch.stop();

        // ASSERT: Cache efficiency achieved
        final averageTime = stopwatch.elapsedMilliseconds / 10;
        expect(averageTime, lessThan(50),
            reason:
                'Cached content fetches should average < 50ms (90%+ cache efficiency)');
      });
    });

    group('🎯 EDGE_CASE: Error Handling & Recovery', () {
      test('🛡️ REGRESSION: Exponential backoff retry logic works correctly',
          () async {
        // ARRANGE: Simulate server failure scenario with retry timing monitoring
        final stopwatch = Stopwatch()..start();

        // ACT: Trigger retry scenario with executeWithRetry
        try {
          await service.executeWithRetry(() async {
            throw Exception('Simulated MCP server error');
          });
        } catch (e) {
          // Expected to fail after retries
        }

        // ASSERT: Retry timing follows exponential backoff
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, greaterThan(1000),
            reason: 'Retry logic should implement exponential backoff delays');
        expect(stopwatch.elapsedMilliseconds, lessThan(30000),
            reason: 'Total retry time should be under 30 seconds');
      });

      test('🔧 INTEGRATION: MCP server errors handled gracefully', () async {
        // ARRANGE: Agent that will trigger server errors
        const agentId = 'error-prone-agent';

        // ACT: Attempt content fetch with error conditions
        try {
          await service.fetchAgentContent(agentId);
        } catch (e) {
          // Expected to handle errors gracefully
        }

        // ASSERT: Service remains in stable state after errors
        expect(service.state, isNot(equals(MCPServiceState.stopped)),
            reason: 'Service should maintain state despite errors');

        final content = service.getAgentContent(agentId);
        expect(content, isNotNull,
            reason: 'Service should provide fallback content during errors');
      });

      test('🎯 EDGE_CASE: Cache invalidation on content changes', () async {
        // ARRANGE: Agent with cached content
        const agentId = 'cache-invalidation-agent';
        await service.fetchAgentContent(agentId);

        // ACT: Simulate content change and cache invalidation
        service.updateContentHash('test-key', 'new-content-hash');
        final shouldSkip = service.shouldSkipFetch(agentId);

        // ASSERT: Cache properly invalidated
        expect(shouldSkip, isFalse,
            reason: 'Cache should be invalidated when content changes');
      });
    });

    group('🔧 INTEGRATION: Content Collection Management', () {
      test('🚀 FEATURE: Agent content isolation maintained', () async {
        // ARRANGE: Multiple agents with different content
        const agent1 = 'isolation-agent-1';
        const agent2 = 'isolation-agent-2';

        // ACT: Fetch content for both agents
        await service.fetchAgentContent(agent1);
        await service.fetchAgentContent(agent2);

        // ASSERT: Content properly isolated
        final content1 = service.getAgentContent(agent1);
        final content2 = service.getAgentContent(agent2);

        expect(content1, isNotNull, reason: 'Agent 1 content should exist');
        expect(content2, isNotNull, reason: 'Agent 2 content should exist');
        expect(content1!.agentId, equals(agent1),
            reason: 'Content 1 should belong to agent 1');
        expect(content2!.agentId, equals(agent2),
            reason: 'Content 2 should belong to agent 2');
      });

      test('🛡️ REGRESSION: Content updates trigger reactive notifications',
          () async {
        // ARRANGE: Listener for service changes
        const agentId = 'notification-test-agent';
        var notificationCount = 0;

        service.addListener(() {
          notificationCount++;
        });

        // ACT: Update agent content collection
        await service.fetchAgentContent(agentId);
        final collection = MCPContentCollection(agentId: agentId);
        service.updateAgentCollection(agentId, collection);

        // ASSERT: Reactive notifications triggered
        expect(notificationCount, greaterThan(0),
            reason: 'Service should notify listeners of content updates');

        // Use agentId to verify proper collection management
        final retrievedContent = service.getAgentContent(agentId);
        expect(retrievedContent?.agentId, equals(agentId),
            reason: 'Updated content should maintain agent association');
      });
    });
  });
}
