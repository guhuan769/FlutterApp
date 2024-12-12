// feedback_page.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:vehicle_control_system/pages/feedback/feedback_controller.dart';

class FeedbackPage extends GetView<FeedbackController> {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 确保controller已注册
    Get.put(FeedbackController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('意见反馈',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Obx(() => Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRatingSection(),
                  const SizedBox(height: 16),
                  _buildCategorySection(),
                  const SizedBox(height: 16),
                  _buildFeedbackSection(),
                  const SizedBox(height: 16),
                  _buildImageUploadSection(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(context),
                ],
              ),
            ),
          ),
          if (controller.isLoading.value)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      )),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '满意度评分',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                5,
                    (index) => GestureDetector(
                  onTap: () => controller.rating.value = index + 1,
                  child: Icon(
                    index < controller.rating.value
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: index < controller.rating.value
                        ? Colors.amber
                        : Colors.grey[400],
                    size: 36,
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '反馈类型',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedCategory.value,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: controller.categories.map((String category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  controller.selectedCategory.value = newValue;
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '详细描述',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '请详细描述您的问题或建议...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '上传图片',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Obx(() => Text(
                  '${controller.selectedImages.length}/9',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                )),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: controller.selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == controller.selectedImages.length && index < 9) {
                  return _buildAddImageButton();
                }
                return _buildImagePreview(index);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: controller.pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(
          Icons.add_photo_alternate_outlined,
          color: Colors.grey[600],
          size: 32,
        ),
      ),
    );
  }

  Widget _buildImagePreview(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(File(controller.selectedImages[index].path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => controller.removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () => controller.submitFeedback(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          '提交反馈',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white
          ),
        ),
      ),
    );
  }
}