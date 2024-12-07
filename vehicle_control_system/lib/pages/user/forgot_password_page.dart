// pages/forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _realNameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  int _currentStep = 0;
  DateTime? _selectedDate;
  Map<String, dynamic>? _userData;
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '很弱';

  @override
  void dispose() {
    _usernameController.dispose();
    _realNameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 验证用户身份
  Future<bool> _verifyUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_${_usernameController.text}');

      if (userDataStr == null) {
        _showMessage('用户不存在', isError: true);
        return false;
      }

      _userData = json.decode(userDataStr);
      return true;
    } catch (e) {
      _showMessage('验证失败: ${e.toString()}', isError: true);
      return false;
    }
  }

  // 验证安全信息
  bool _verifySecurityInfo() {
    if (_userData == null || _selectedDate == null) return false;

    final securityInfo = _userData!['securityInfo'];
    return securityInfo['realName'] == _realNameController.text &&
        securityInfo['birthDate'] ==
            DateFormat('yyyy-MM-dd').format(_selectedDate!);
  }

  // 计算密码强度
  void _calculatePasswordStrength(String password) {
    double strength = 0;
    String strengthText = '很弱';

    if (password.isEmpty) {
      strength = 0;
      strengthText = '很弱';
    } else {
      if (password.length >= 8) strength += 0.2;
      if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
      if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
      if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

      if (strength <= 0.2)
        strengthText = '很弱';
      else if (strength <= 0.4)
        strengthText = '弱';
      else if (strength <= 0.6)
        strengthText = '中等';
      else if (strength <= 0.8)
        strengthText = '强';
      else
        strengthText = '很强';
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = strengthText;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: '选择出生日期',
      cancelText: '取消',
      confirmText: '确定',
      fieldLabelText: '出生日期',
      fieldHintText: '请选择出生日期',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 重置密码
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (!_verifySecurityInfo()) {
        _showMessage('安全验证失败', isError: true);
        return;
      }

      // 更新密码
      _userData!['password'] = _newPasswordController.text;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'user_${_usernameController.text}',
        json.encode(_userData),
      );

      _showMessage('密码重置成功！');
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => LoginPage(
        //       initialUsername: _usernameController.text,
        //       initialPassword: _newPasswordController.text,
        //     ),
        //   ),
        // );
        Get.toNamed('/login');
      }
    } catch (e) {
      _showMessage('重置密码失败: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('找回密码'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stepper(

          currentStep: _currentStep,
          onStepContinue: () async {
            if (_currentStep == 0) {
              if (await _verifyUser()) {
                setState(() => _currentStep++);
              }
            } else if (_currentStep == 1) {
              if (_verifySecurityInfo()) {
                setState(() => _currentStep++);
              } else {
                _showMessage('安全验证失败', isError: true);
              }
            } else {
              _resetPassword();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
          // 使用 controlsBuilder 修改按钮文本
          controlsBuilder: (context, details) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: const Text("下一步"),  // 自定义"继续"按钮文本
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text("返回"),  // 自定义"取消"按钮文本
                ),
              ],
            );
          },
          steps: [
            // 第一步：输入用户名
            Step(
              title: const Text('输入用户名'),
              content: TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  hintText: '请输入您的用户名',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入用户名';
                  }
                  return null;
                },
              ),
              isActive: _currentStep >= 0,
            ),
            // 第二步：安全验证
            Step(
              title: const Text('安全验证'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _realNameController,
                    decoration: const InputDecoration(
                      labelText: '真实姓名',
                      hintText: '请输入注册时填写的真实姓名',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入真实姓名';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '出生日期',
                        hintText: '请选择您的出生日期',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate == null
                                ? '请选择出生日期'
                                : DateFormat('yyyy-MM-dd')
                                    .format(_selectedDate!),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
            ),
            // 第三步：设置新密码
            Step(
              title: const Text('设置新密码'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: '新密码',
                      hintText: '请输入新密码',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    onChanged: _calculatePasswordStrength,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入新密码';
                      }
                      if (value.length < 8) {
                        return '密码长度不能小于8位';
                      }
                      if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                        return '密码必须包含大写字母';
                      }
                      if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
                        return '密码必须包含小写字母';
                      }
                      if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
                        return '密码必须包含数字';
                      }
                      if (!RegExp(r'(?=.*[@$!%*?&])').hasMatch(value)) {
                        return '密码必须包含特殊字符';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _passwordStrength,
                    backgroundColor: Colors.grey[200],
                    color: _passwordStrength <= 0.2
                        ? Colors.red
                        : _passwordStrength <= 0.4
                            ? Colors.orange
                            : _passwordStrength <= 0.6
                                ? Colors.yellow
                                : _passwordStrength <= 0.8
                                    ? Colors.blue
                                    : Colors.green,
                  ),
                  Text('密码强度: $_passwordStrengthText'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: '确认新密码',
                      hintText: '请再次输入新密码',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value != _newPasswordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }
}
