class ExampleUserService  {

}

class ExampleProductService {

}

class ExampleDatabaseService {

}

class ExampleServices {

  final ExampleUserService userService;
  final ExampleProductService productService;
  final ExampleDatabaseService databaseService;

ExampleServices(){
  userService = ExampleUserService();
  productService = ExampleProductService();
  databaseService = ExampleDatabaseService();
};

}

ExampleServices get services {
  if(GetIt.instance.isRegistered<ExampleServices>() == false) {
    GetIt.instance.registerSingleton<ExampleServices>(ExampleServices());
  }
  return GetIt.instance.get<ExampleServices>();
}

void main() {
  services.userService.getUser();
}
