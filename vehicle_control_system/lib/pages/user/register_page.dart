// pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _basicInfoFormKey = GlobalKey<FormState>();
  final _securityInfoFormKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _realNameController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  int _currentStep = 0;
  DateTime? _selectedDate;

  double _passwordStrength = 0.0;
  String _passwordStrengthText = '很弱';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _realNameController.dispose();
    super.dispose();
  }

  // 检查用户名是否已存在
  Future<bool> _checkUsernameExists(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('user_$username');
    } catch (e) {
      print('检查用户名失败: $e');
      return false;
    }
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

      if (strength <= 0.2) strengthText = '很弱';
      else if (strength <= 0.4) strengthText = '弱';
      else if (strength <= 0.6) strengthText = '中等';
      else if (strength <= 0.8) strengthText = '强';
      else strengthText = '很强';
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = strengthText;
    });
  }

  // 验证当前步骤
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _basicInfoFormKey.currentState?.validate() ?? false;
      case 1:
        if (!(_securityInfoFormKey.currentState?.validate() ?? false)) {
          return false;
        }
        if (_selectedDate == null) {
          _showMessage('请选择出生日期', isError: true);
          return false;
        }
        return true;
      case 2:
        return true; // 确认步骤不需要额外验证
      default:
        return false;
    }
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

  // 处理注册
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage('请填写所有必要信息', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (await _checkUsernameExists(_usernameController.text)) {
        _showMessage('用户名已存在', isError: true);
        return;
      }

      final userData = {
        'username': _usernameController.text,
        'password': _passwordController.text,
        'securityInfo': {
          'realName': _realNameController.text,
          'birthDate': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        },
        'createdAt': DateTime.now().toString(),
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'user_${_usernameController.text}',
        json.encode(userData),
      );

      _showMessage('注册成功！');
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Get.toNamed('/login');
      }
    } catch (e) {
      _showMessage('注册失败: ${e.toString()}', isError: true);
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
        title: const Text('注册账号'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (!_validateCurrentStep()) {
                return;
              }

              if (_currentStep < 2) {
                setState(() => _currentStep++);
              } else {
                _handleRegister();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                Navigator.pop(context);
              }
            },
            steps: [
              // 步骤1：基本信息
              Step(
                title: const Text('基本信息'),
                content: Form(
                  key: _basicInfoFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: '用户名',
                          hintText: '请输入3-16位用户名',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入用户名';
                          }
                          if (value.length < 3 || value.length > 16) {
                            return '用户名长度应在3-16位之间';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                            return '用户名只能包含字母、数字和下划线';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: '密码',
                          hintText: '请设置密码',
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
                            return '请输入密码';
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
                          labelText: '确认密码',
                          hintText: '请再次输入密码',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return '两次输入的密码不一致';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                isActive: _currentStep >= 0,
              ),
              // 步骤2：安全信息
              Step(
                title: const Text('安全信息'),
                content: Form(
                  key: _securityInfoFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _realNameController,
                        decoration: const InputDecoration(
                          labelText: '真实姓名',
                          hintText: '请输入您的真实姓名',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入真实姓名';
                          }
                          if (value.length < 2) {
                            return '请输入正确的姓名';
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
                                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                isActive: _currentStep >= 1,
              ),
              // 步骤3：确认信息
              Step(
                title: const Text('确认信息'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('用户名: ${_usernameController.text}'),
                    const SizedBox(height: 8),
                    const Text('密码: ********'),
                    const SizedBox(height: 8),
                    Text('真实姓名: ${_realNameController.text}'),
                    const SizedBox(height: 8),
                    Text('出生日期: ${_selectedDate?.toString().split(' ')[0] ?? '未选择'}'),
                    const SizedBox(height: 16),
                    const Text(
                      '请确认以上信息正确，注册后真实姓名和出生日期将用于密码找回，请认真填写。',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                isActive: _currentStep >= 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}