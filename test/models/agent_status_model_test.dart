import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/models/agent_status_model.dart';

void main() {
  group('AgentStatusModel', () {
    group('🏗️ CONSTRUCTION & INITIALIZATION', () {
      test('✅ VICTORY: Creates with default idle status', () {
        final model = AgentStatusModel();

        expect(model.status, AgentProcessingStatus.idle);
        expect(model.errorMessage, isNull);
        expect(model.lastActivity, isA<DateTime>());
        expect(model.lastStatusChange, isA<DateTime>());
      });

      test('✅ VICTORY: Creates with custom status', () {
        final model =
            AgentStatusModel(initialStatus: AgentProcessingStatus.processing);

        expect(model.status, AgentProcessingStatus.processing);
        expect(model.errorMessage, isNull);
      });
    });

    group('⚔️ STATUS TRANSITIONS', () {
      late AgentStatusModel model;

      setUp(() {
        model = AgentStatusModel();
      });

      test('✅ VICTORY: idle → processing transition', () {
        expect(model.status, AgentProcessingStatus.idle);

        model.setProcessing();

        expect(model.status, AgentProcessingStatus.processing);
        expect(model.errorMessage, isNull);
      });

      test('✅ VICTORY: processing → idle transition', () {
        model.setProcessing();
        expect(model.status, AgentProcessingStatus.processing);

        model.setIdle();

        expect(model.status, AgentProcessingStatus.idle);
        expect(model.errorMessage, isNull);
      });

      test('✅ VICTORY: processing → error transition with message', () {
        model.setProcessing();
        const errorMsg = 'Connection timeout error';

        model.setError(errorMsg);

        expect(model.status, AgentProcessingStatus.error);
        expect(model.errorMessage, errorMsg);
      });

      test('✅ VICTORY: error → idle recovery transition', () {
        model.setError('Some error');
        expect(model.status, AgentProcessingStatus.error);

        model.setIdle();

        expect(model.status, AgentProcessingStatus.idle);
        expect(model.errorMessage, isNull);
      });
    });

    group('⏰ TIMESTAMP MANAGEMENT', () {
      late AgentStatusModel model;

      setUp(() {
        model = AgentStatusModel();
      });

      test('✅ VICTORY: Updates lastStatusChange on status transitions',
          () async {
        final initialStatusChange = model.lastStatusChange;

        // Small delay to ensure timestamp difference
        await Future.delayed(const Duration(milliseconds: 1));

        model.setProcessing();

        expect(model.lastStatusChange.isAfter(initialStatusChange), isTrue);
      });

      test('✅ VICTORY: Updates lastActivity on updateActivity() call',
          () async {
        final initialActivity = model.lastActivity;

        await Future.delayed(const Duration(milliseconds: 1));

        model.updateActivity();

        expect(model.lastActivity.isAfter(initialActivity), isTrue);
      });

      test('✅ VICTORY: Status changes trigger activity updates', () async {
        final initialActivity = model.lastActivity;

        await Future.delayed(const Duration(milliseconds: 1));

        model.setProcessing();

        expect(model.lastActivity.isAfter(initialActivity), isTrue);
      });
    });

    group('🔔 CHANGENOTIFIER SUPREMACY', () {
      late AgentStatusModel model;
      late List<void> notifications;

      setUp(() {
        model = AgentStatusModel();
        notifications = [];
        model.addListener(() => notifications.add(null));
      });

      test('✅ VICTORY: Notifies listeners on status transitions', () {
        expect(notifications, isEmpty);

        model.setProcessing();
        expect(notifications, hasLength(1));

        model.setIdle();
        expect(notifications, hasLength(2));

        model.setError('Error message');
        expect(notifications, hasLength(3));
      });

      test('✅ VICTORY: Notifies listeners on activity updates', () {
        expect(notifications, isEmpty);

        model.updateActivity();

        expect(notifications, hasLength(1));
      });

      test('🛡️ EFFICIENCY: No notification for identical status', () {
        model.setIdle(); // Already idle
        expect(notifications, isEmpty);

        model.setProcessing();
        expect(notifications, hasLength(1));

        model.setProcessing(); // Already processing
        expect(notifications, hasLength(1)); // No additional notification
      });
    });

    group('🧪 VALIDATION & ERROR HANDLING', () {
      late AgentStatusModel model;

      setUp(() {
        model = AgentStatusModel();
      });

      test('✅ VICTORY: Validates status transition logic', () {
        // All transitions should be valid in our current design
        expect(() => model.setProcessing(), returnsNormally);
        expect(() => model.setIdle(), returnsNormally);
        expect(() => model.setError('Error'), returnsNormally);
      });

      test('✅ VICTORY: Handles empty error messages gracefully', () {
        model.setError('');

        expect(model.status, AgentProcessingStatus.error);
        expect(model.errorMessage, '');
      });

      test('✅ VICTORY: Clears error message on successful transitions', () {
        model.setError('Some error');
        expect(model.errorMessage, 'Some error');

        model.setIdle();
        expect(model.errorMessage, isNull);

        model.setError('Another error');
        model.setProcessing();
        expect(model.errorMessage, isNull);
      });
    });

    group('💾 JSON SERIALIZATION', () {
      test('✅ VICTORY: Serializes to JSON correctly', () {
        final model = AgentStatusModel();
        model.setProcessing();

        final json = model.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['status'], 'processing');
        expect(json['lastActivity'], isA<String>());
        expect(json['lastStatusChange'], isA<String>());
        expect(json['errorMessage'], isNull);
      });

      test('✅ VICTORY: Deserializes from JSON correctly', () {
        final originalModel = AgentStatusModel();
        originalModel.setError('Test error');

        final json = originalModel.toJson();
        final restoredModel = AgentStatusModel.fromJson(json);

        expect(restoredModel.status, originalModel.status);
        expect(restoredModel.errorMessage, originalModel.errorMessage);
        expect(restoredModel.lastActivity, originalModel.lastActivity);
        expect(restoredModel.lastStatusChange, originalModel.lastStatusChange);
      });

      test('✅ VICTORY: Handles malformed JSON gracefully', () {
        final json = {
          'status': 'invalid_status',
          'lastActivity': 'invalid_date',
        };

        // Should use defaults for invalid data
        final model = AgentStatusModel.fromJson(json);
        expect(model.status, AgentProcessingStatus.idle);
        expect(model.lastActivity, isA<DateTime>());
      });
    });

    group('⚡ PERFORMANCE BENCHMARKS', () {
      test('🚀 STATUS UPDATE: < 1ms performance target', () {
        final model = AgentStatusModel();
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          model.setProcessing();
          model.setIdle();
        }

        stopwatch.stop();
        final avgTime =
            stopwatch.elapsedMicroseconds / 2000; // 2 operations per iteration

        expect(avgTime, lessThan(1000)); // < 1ms (1000 microseconds)
      });

      test('🚀 SERIALIZATION: < 5ms performance target', () {
        final model = AgentStatusModel();
        model.setError('Performance test error message');

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          final json = model.toJson();
          AgentStatusModel.fromJson(json);
        }

        stopwatch.stop();
        final avgTime =
            stopwatch.elapsedMicroseconds / 200; // 2 operations per iteration

        expect(avgTime, lessThan(5000)); // < 5ms (5000 microseconds)
      });
    });

    group('🔒 THREAD SAFETY', () {
      test('✅ VICTORY: Concurrent status updates remain consistent', () async {
        final model = AgentStatusModel();
        final futures = <Future>[];

        // Launch 10 concurrent status updates
        for (int i = 0; i < 10; i++) {
          futures.add(Future.microtask(() {
            model.setProcessing();
            model.setIdle();
            model.updateActivity();
          }));
        }

        await Future.wait(futures);

        // Model should remain in consistent state
        expect(
            model.status,
            anyOf([
              AgentProcessingStatus.idle,
              AgentProcessingStatus.processing,
            ]));
        expect(model.lastActivity, isA<DateTime>());
        expect(model.lastStatusChange, isA<DateTime>());
      });
    });
  });
}
