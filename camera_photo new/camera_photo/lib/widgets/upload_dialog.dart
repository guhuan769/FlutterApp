// lib/widgets/upload_dialog.dart
import 'package:flutter/material.dart';
import '../config/upload_options.dart';

class UploadConfigDialog extends StatefulWidget {
  final Function(UploadType type, String value) onConfirm;

  const UploadConfigDialog({
    Key? key,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<UploadConfigDialog> createState() => _UploadConfigDialogState();
}

class _UploadConfigDialogState extends State<UploadConfigDialog> {
  UploadType _selectedType = UploadType.model;  // 设置默认值
  String? _selectedValue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('上传配置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 类型选择
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<UploadType>(
                  value: UploadType.model,
                  groupValue: _selectedType,
                  onChanged: (UploadType? value) {
                    setState(() {
                      _selectedType = value!;
                      _selectedValue = null;
                    });
                  },
                ),
                const Text('模型'),
                const SizedBox(width: 20),
                Radio<UploadType>(
                  value: UploadType.craft,
                  groupValue: _selectedType,
                  onChanged: (UploadType? value) {
                    setState(() {
                      _selectedType = value!;
                      _selectedValue = null;
                    });
                  },
                ),
                const Text('工艺'),
              ],
            ),
            const SizedBox(height: 16),
            // 具体选项下拉框
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: _selectedType == UploadType.model ? '选择模型' : '选择工艺',
                border: const OutlineInputBorder(),
              ),
              value: _selectedValue,
              items: (_selectedType == UploadType.model
                  ? UploadOptions.models
                  : UploadOptions.crafts)
                  .map((value) => DropdownMenuItem(
                value: value,
                child: Text(value),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedValue = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _selectedValue != null
              ? () {
            widget.onConfirm(_selectedType, _selectedValue!);
            Navigator.pop(context);
          }
              : null,
          child: const Text('确认'),
        ),
      ],
    );
  }
}