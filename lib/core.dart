import 'package:appwrite/appwrite.dart';
import 'package:ppvdigital/app/login/login_controller.dart';

class Core {
  factory Core() {
    return instance;
  }
  Core._internal();

  static final Core instance = Core._internal();
  static Client client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('671f6df50033227ea6d6');

  LoginController loginController = LoginController();
}
