import 'package:get/get.dart';
import '../../../controllers/ai_chat_controller.dart';
import '../../../utils/command_executor.dart';

class AIChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CommandExecutor(), permanent: true);
    Get.put(AIChatController());
  }
} 