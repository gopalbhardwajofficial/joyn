import 'package:flutter/material.dart';
import '../theme/joyn_colors.dart';

class JoynLogo extends StatelessWidget {
  final Color color;
  final double size;
  final bool showImageLogo;

  const JoynLogo({
    super.key,
    this.color = JoynColors.primary,
    this.size = 28.0,
    this.showImageLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showImageLogo) {
      return Image.asset(
        'assets/joynsplashlogo.jpeg',
        height: size * 2.5,
        fit: BoxFit.contain,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'j',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -1,
            height: 1.0,
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'o',
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -1,
                height: 1.0,
              ),
            ),
            Icon(
              Icons.link_rounded,
              size: size * 0.55,
              color: color,
            ),
          ],
        ),
        Text(
          'yn',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -1,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
