import 'package:flutter/material.dart';

/// 显示带动画的底部 Sheet
Future<T?> showAnimatedBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor ?? Colors.transparent,
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
    ),
    builder: builder,
  );
}

/// Sheet 内容包装器 - 带圆角和拖拽条
class SheetContainer extends StatelessWidget {
  final Widget child;
  final double? maxHeightFactor;

  const SheetContainer({
    super.key,
    required this.child,
    this.maxHeightFactor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽条
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );

    if (maxHeightFactor != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * maxHeightFactor!,
        ),
        child: content,
      );
    }

    return content;
  }
}
