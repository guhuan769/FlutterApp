// feedback_controller.dart
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:vehicle_control_system/utilities/dio_http.dart';

class FeedbackController extends GetxController {
  final ImagePicker picker = ImagePicker();
  final TextEditingController feedbackController = TextEditingController();

  final RxDouble rating = 0.0.obs;
  final RxString selectedCategory = '功能建议'.obs;
  final RxList<XFile> selectedImages = <XFile>[].obs;
  final RxBool isLoading = false.obs;

  final List<String> categories = ['功能建议', '界面设计', '性能问题', '其他'];

  @override
  void onClose() {
    feedbackController.dispose();
    super.onClose();
  }

  Future<void> pickImages() async {
    try {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        selectedImages.addAll(images);
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      Get.snackbar(
        '提示',
        '选择图片失败',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  Future<void> submitFeedback(BuildContext context) async {
    if (rating.value == 0) {
      Get.snackbar('提示', '请先进行评分');
      return;
    }

    if (feedbackController.text.trim().isEmpty) {
      Get.snackbar('提示', '请填写反馈内容');
      return;
    }

    try {
      isLoading.value = true;

      // 创建 FormData 对象
      var formData = dio.FormData.fromMap({
        'rating': rating.value,
        'category': selectedCategory.value,
        'content': feedbackController.text,
      });

      // 处理图片上传
      if (selectedImages.isNotEmpty) {
        for (var i = 0; i < selectedImages.length; i++) {
          String fileName = selectedImages[i].path.split('/').last;
          formData.files.add(
            MapEntry(
              'images',  // 字段名
              await dio.MultipartFile.fromFileSync(
                selectedImages[i].path,
                filename: fileName,
              ),
            ),
          );
        }
      }

      final response = await DioHttp.of(context).postFormData(
        '/api/feedback',
        formData as dynamic,  // 显式转换为 dynamic 类型
        // 如果需要token，从本地存储获取
        // await Storage.getString(Config.TOKEN_KEY),
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          '成功',
          '反馈提交成功，感谢您的建议！',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // 清空表单
        rating.value = 0;
        selectedCategory.value = categories[0];
        feedbackController.clear();
        selectedImages.clear();
      }
    } catch (e) {
      Get.snackbar(
        '错误',
        '提交失败，请稍后重试',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}