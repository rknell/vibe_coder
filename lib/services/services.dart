import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';

class Services {
  Logger logging(String name) => Logger(name);

  Services();
}

Services get services {
  if (GetIt.instance.isRegistered<Services>()) {
    return GetIt.instance.get<Services>();
  }
  final services = Services();
  GetIt.instance.registerSingleton<Services>(services);
  return services;
}
