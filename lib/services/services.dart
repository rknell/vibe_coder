import 'package:get_it/get_it.dart';
import 'package:vibe_coder/services/mcp_service.dart';
import 'package:vibe_coder/services/agent_service.dart';
import 'package:vibe_coder/services/configuration_service.dart';
import 'package:vibe_coder/services/debug_logger.dart';

/// Services - Universal App State Management with GetIt
///
/// ## MISSION ACCOMPLISHED
/// Updated Services class to remove ChatService following architectural refactoring.
/// AgentModel now handles conversation directly, eliminating redundant service layer.
///
/// ## ARCHITECTURAL DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Keep ChatService | Consistent API | Redundant layer | ELIMINATED - violates Clean Architecture |
/// | Direct AgentModel | Single source | No abstraction | CHOSEN - proper data model responsibility |
/// | Service delegation | Centralized | Complex routing | REJECTED - unnecessary complexity |
///
/// PERF: Service initialization O(1) for each service
/// ARCHITECTURAL: Dependency injection with clean service separation
class Services {
  // 🔧 MCP MANAGEMENT LAYER - Enhanced with cache and process management
  final MCPService mcpService;

  // 👥 AGENT MANAGEMENT LAYER - Architecture-compliant service
  final AgentService agentService;

  // ⚙️ CONFIGURATION SERVICES LAYER
  final ConfigurationService configurationService;

  // 🐛 DEBUG SERVICES LAYER
  final DebugLogger debugLogger;

  /// Constructor - Initialize all services
  Services()
      : mcpService = MCPService(),
        agentService = AgentService(),
        configurationService = ConfigurationService(),
        debugLogger = DebugLogger() {
    // 🚀 INITIALIZATION CHAIN: Set up service dependencies
    _initializeServiceDependencies();
  }

  /// 🔗 PRIVATE: Initialize cross-service dependencies
  ///
  /// ARCHITECTURAL: Services may depend on each other for functionality
  /// This method sets up those relationships after all services are instantiated
  void _initializeServiceDependencies() {
    // 🎯 MCP SERVICE: Initialize the enhanced MCP service first
    // This provides shared MCP infrastructure for all agents and chat services
    mcpService.initialize().catchError((e) {
      // MCP initialization failure is logged internally by MCPService
      // Non-critical failure - services can continue without MCP
    });
  }

  /// Initialize all services
  ///
  /// PERF: O(1) for each service - parallel initialization where possible
  Future<void> initialize() async {
    await configurationService.initialize();
    await mcpService.initialize();
    await agentService.initialize();
    // DebugLogger doesn't need initialization
  }

  /// Cleanup all services
  ///
  /// PERF: O(1) for each service - sequential cleanup for safety
  void dispose() {
    agentService.dispose();
    mcpService.dispose();
    configurationService.dispose();
    // DebugLogger doesn't need disposal
  }
}

/// 🌐 GLOBAL SERVICES ACCESSOR WITH GETIT
///
/// ARCHITECTURAL: Global services access point following user's exact pattern
/// Provides singleton access with automatic registration and testing support
Services get services {
  if (!GetIt.instance.isRegistered<Services>()) {
    GetIt.instance.registerSingleton<Services>(Services());
  }
  return GetIt.instance.get<Services>();
}

/// 🧪 TESTING SUPPORT: Reset services for test isolation
///
/// ARCHITECTURAL: Clean test setup - removes old services and allows mock injection
void resetServices() {
  if (GetIt.instance.isRegistered<Services>()) {
    final currentServices = GetIt.instance.get<Services>();
    currentServices.dispose();
    GetIt.instance.unregister<Services>();
  }
}

/// 🧪 TESTING SUPPORT: Register mock services
///
/// ARCHITECTURAL: Test dependency injection - allows full service mocking
/// Usage: registerMockServices(MockServices());
void registerMockServices(Services mockServices) {
  resetServices();
  GetIt.instance.registerSingleton<Services>(mockServices);
}
