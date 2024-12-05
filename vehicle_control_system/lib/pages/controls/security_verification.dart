// security_verification.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SecurityVerificationWidget extends StatefulWidget {
  final bool isRegistration; // 是否为注册页面
  final Function(String realName, String birthDate) onVerified;

  const SecurityVerificationWidget({
    Key? key,
    this.isRegistration = true,
    required this.onVerified,
  }) : super(key: key);

  @override
  _SecurityVerificationWidgetState createState() => _SecurityVerificationWidgetState();
}

class _SecurityVerificationWidgetState extends State<SecurityVerificationWidget> {
  final _realNameController = TextEditingController();
  DateTime? _selectedDate;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _realNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: '选择出生日期',
      cancelText: '取消',
      confirmText: '确定',
      errorFormatText: '日期格式错误',
      errorInvalidText: '日期无效',
      fieldLabelText: '出生日期',
      fieldHintText: '请选择出生日期',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _verify() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final birthDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      widget.onVerified(_realNameController.text, birthDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _realNameController,
            decoration: InputDecoration(
              labelText: '真实姓名',
              hintText: '请输入您的真实姓名',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入真实姓名';
              }
              if (value.length < 2) {
                return '姓名长度不正确';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '出生日期',
                hintText: '请选择您的出生日期',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate == null
                        ? '请选择出生日期'
                        : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          if (_selectedDate == null)
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 12),
              child: Text(
                '请选择出生日期',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _verify,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(widget.isRegistration ? '下一步' : '验证'),
          ),
        ],
      ),
    );
  }
}