// toast.dart
import 'package:flutter/material.dart';
import 'package:vehicle_control_system/data/enum/ToastType.dart';

class Toast {
  static final List<OverlayEntry> _entries = [];
  static const Duration _animationDuration = Duration(milliseconds: 200);
  static const Duration _displayDuration = Duration(milliseconds: 2000);

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
    final overlayState = Overlay.of(context);
    final overlay = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        offset: _entries.length * 60.0,
      ),
    );

    _entries.add(overlay);
    overlayState.insert(overlay);

    Future.delayed(duration ?? _displayDuration, () {
      if (_entries.contains(overlay)) {
        overlay.remove();
        _entries.remove(overlay);
        _updatePositions();
      }
    });
  }

  static void _updatePositions() {
    for (var entry in _entries) {
      entry.markNeedsBuild();
    }
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final double offset;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.offset,
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
      bottom: 32.0 + widget.offset,
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
    );
  }
}

// 使用示例
class ToastDemo extends StatelessWidget {
  void _showToasts(BuildContext context) {
    // 成功提示
    Toast.show(
      context,
      "操作成功",
      type: ToastType.success,
    );

    // 错误提示
    Toast.show(
      context,
      "操作失败",
      type: ToastType.error,
    );

    // 提示信息
    Toast.show(
      context,
      "这是一条提示信息",
      type: ToastType.info,
    );

    // 警告信息
    Toast.show(
      context,
      "请注意",
      type: ToastType.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => Toast.show(
              context,
              "操作成功",
              type: ToastType.success,
            ),
            child: Text('显示成功提示'),
          ),
          ElevatedButton(
            onPressed: () => Toast.show(
              context,
              "操作失败",
              type: ToastType.error,
            ),
            child: Text('显示错误提示'),
          ),
          ElevatedButton(
            onPressed: () => _showToasts(context),
            child: Text('显示多个提示'),
          ),
        ],
      ),
    );
  }
}

// 在你的代码中使用
void onButtonPressed(BuildContext context) {
  Toast.show(
    context,
    "操作已执行",
    type: ToastType.success,
  );
}