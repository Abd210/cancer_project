import 'package:flutter/material.dart';

class LogoLine extends StatelessWidget {
  const LogoLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/acuranics.png', // Replace with the correct asset path
                  height: 70,
                ),
                const SizedBox(width: 10),
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
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Text(
              'Super Admin',
              style: TextStyle(
                color: Color.fromARGB(255, 229, 45, 134),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
