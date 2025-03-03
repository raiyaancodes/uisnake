import 'dart:io';
import 'package:colors_test/tinder.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:image_picker/image_picker.dart';

class PalettePage extends StatelessWidget {
  final List<Color> colors;
  final String? description;

  const PalettePage({
    super.key,
    required this.colors,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Color blocks section
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                children: List.generate(colors.length, (index) {
                  return Expanded(
                    child: Container(
                      width: double.infinity,
                      color: colors[index],
                      child: Center(
                        child: Text(
                          '#${colors[index].value.toRadixString(16).substring(2).toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Description and button section
            Expanded(
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          description!,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TinderPage(
                              palettes: [colors],
                              inspirations: [],
                              category: 'Custom',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 32.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text(
                        "Go to Tinder Page",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
