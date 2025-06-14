import 'package:vibe_coder/ai_agent/agent.dart';
import 'package:get_it/get_it.dart';

class CompanyDirectoryService {
  final List<Agent> agents = [];

  void addAgent(Agent agent) {
    agents.add(agent);
  }
}

CompanyDirectoryService get companyDirectory {
  if (!GetIt.I.isRegistered<CompanyDirectoryService>()) {
    GetIt.I
        .registerSingleton<CompanyDirectoryService>(CompanyDirectoryService());
  }
  return GetIt.I.get<CompanyDirectoryService>();
}
