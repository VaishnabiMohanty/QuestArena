import 'package:flutter/material.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/colors.dart';

class AnimatedCoinCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;

  const AnimatedCoinCounter({
    super.key,
    required this.value,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(seconds: 2),
      curve: Curves.easeOutCirc,
      builder: (context, val, child) {
        return Text(
          '$val',
          style: style ?? AppTextStyles.headline.copyWith(color: AppColors.gold),
        );
      },
    );
  }
}
