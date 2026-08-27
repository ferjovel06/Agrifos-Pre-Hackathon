import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const cream = Color(0xFFF9F0E9);
  static const green = Color(0xFF31543B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: Stack(
        children: [
          // Brown wave
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              width: double.infinity,
              height: 190,
              child: SvgPicture.asset(
                'assets/images/decorations/wave_brown.svg',
                width: double.infinity,
                height: 190,
                fit: BoxFit.fill,
              ),
            ),
          ),
          // Green wave
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: SizedBox(
              width: double.infinity,
              height: 150,
              child: SvgPicture.asset(
                'assets/images/decorations/wave_green.svg',
                width: double.infinity,
                height: 150,
                fit: BoxFit.fill,
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/branding/agrifos_splash_logo.png',
                  width: 140,
                  height: 140,
                ),
                const SizedBox(height: 12),
                SvgPicture.asset(
                  'assets/images/branding/agrifos_logotype.svg',
                  height: 32,
                  colorFilter: const ColorFilter.mode(green, BlendMode.srcIn),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
