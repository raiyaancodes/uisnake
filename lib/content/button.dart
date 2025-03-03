import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final double num_size;
  final VoidCallback onPressed;
  final double left;
  final double right;
  final Color iconcolor;

  const CustomButton(
      {super.key,
      required this.text,
      required this.iconcolor,
      required this.left,
      required this.right,
      required this.icon,
      required this.num_size,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 40, 64, 185),
        fixedSize: const Size(360, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          // <-- Radius
        ),
      ),
      child: Row(
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(left, 0, right, 0),
              child: Text(
                text,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
            child: Icon(
              icon,
              color: iconcolor,
              size: num_size,
            ),
          ),
        ],
      ),
    );
  }
}
