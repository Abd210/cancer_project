import 'package:flutter/material.dart';

class LogoLine extends StatelessWidget {
  const LogoLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      //      color: const Color.fromARGB(255, 255, 252, 254),
      height: 50, // Keep the total row height at 50
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Use a Center or Align to ensure the image is nicely centered
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/acuranics.png',
                  height: 150, 
                  filterQuality: FilterQuality.high, // for a sharper look
                ),
                const SizedBox(width: 5),
                const Text(
                  'CURANICS',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
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
