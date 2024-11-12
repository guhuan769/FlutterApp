// toast.dart
import 'package:flutter/material.dart';
import 'package:vehicle_control_system/data/enum/ToastType.dart';
import 'dart:async';  // 确保添加这个导入

class Toast {
  static OverlayEntry? _currentToast;
  static const Duration _animationDuration = Duration(milliseconds: 200);
  static const Duration _displayDuration = Duration(milliseconds: 2000);
  static Timer? _timer;

  static Color _getBackgroundColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const Color(0xFF4CAF50);
      case ToastType.error:
        return const Color(0xFFEF5350);
      case ToastType.info:
        return const Color(0xFF2196F3);
      case ToastType.warning:
        return const Color(0xFFFF9800);
    }
  }

  static IconData _getIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.info:
        return Icons.info_outline;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
    }
  }

  static void show(
      BuildContext context,
      String message, {
        ToastType type = ToastType.info,
        Duration? duration,
      }) {
    // 取消当前的定时器
    _timer?.cancel();

    // 移除当前显示的 Toast
    _currentToast?.remove();

    final overlay = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
      ),
    );

    _currentToast = overlay;
    Overlay.of(context).insert(overlay);

    // 设置新的定时器
    _timer = Timer(duration ?? _displayDuration, () {
      _currentToast?.remove();
      _currentToast = null;
    });
  }

  // 手动关闭当前 Toast
  static void dismiss() {
    _timer?.cancel();
    _currentToast?.remove();
    _currentToast = null;
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;

  const _ToastWidget({
    required this.message,
    required this.type,
  });

  @override
  _ToastWidgetState createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Toast._animationDuration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16.0,
      left: 16.0,
      right: 16.0,
      child: FadeTransition(
        opacity: _animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(_animation),
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Toast._getBackgroundColor(widget.type),
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Toast._getIcon(widget.type),
                      color: Colors.white,
                      size: 24.0,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 使用示例
void showToastExample(BuildContext context) {
  // 显示第一条消息
  Toast.show(context, "第一条消息", type: ToastType.success);

  // 100ms 后显示第二条消息，会立即覆盖第一条
  Future.delayed(Duration(milliseconds: 100), () {
    Toast.show(context, "第二条消息", type: ToastType.error);
  });

  // 如果需要手动关闭
  // Toast.dismiss();
}