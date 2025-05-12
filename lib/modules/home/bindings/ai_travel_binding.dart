import 'package:get/get.dart';
import '../controllers/ai_travel_assistant_controller.dart';

class AiTravelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiTravelAssistantController>(() => AiTravelAssistantController());
  }
} 