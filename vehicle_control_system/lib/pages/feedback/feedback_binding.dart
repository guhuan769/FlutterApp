
// feedback_binding.dart
import 'package:get/get.dart';
import 'package:vehicle_control_system/pages/feedback/feedback_controller.dart';

class FeedbackBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FeedbackController());
  }
}