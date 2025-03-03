import 'package:colors_test/ux_suggestions_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'theme_provider.dart';
import 'constants.dart';
import 'tinder.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'color_suggestions_page.dart';

class DesignSystemsPage extends StatefulWidget {
  final String category;

  const DesignSystemsPage({
    super.key,
    required this.category,
  });

  @override
  State<DesignSystemsPage> createState() => _DesignSystemsPageState();
}

class _DesignSystemsPageState extends State<DesignSystemsPage> {
  File? _image;
  bool isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _image = File(image.path));
    }
  }

  void _analyzeColors(BuildContext context) async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image first')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: Constants.GEMINI_API_KEY,
      );

      final List<int> imageBytes = await _image!.readAsBytes();
      final Uint8List uint8Bytes = Uint8List.fromList(imageBytes);
      final imagePart = DataPart('image/jpeg', uint8Bytes);

      final colorPrompt = '''
        Task: Analyze this design image and suggest a better color palette.
        
        Requirements:
        1. Provide a brief explanation of suggested improvements
        2. List exactly 5 hex color codes (without #)
        
        Format your response exactly like this example:
        This warmer palette improves contrast and readability while maintaining brand consistency|FF5722,FFA000,FFB300,FF7043,FF8A65
      ''';

      final colorContent = [
        Content.multi([imagePart, TextPart(colorPrompt)]),
      ];

      final response = await model.generateContent(colorContent);

      if (!mounted) return;

      if (response.text != null) {
        final parts = response.text!.trim().split('|');
        if (parts.length == 2) {
          final explanation = parts[0].trim();
          final hexCodes = parts[1]
              .trim()
              .split(',')
              .map((hex) => hex.trim().replaceAll('#', ''))
              .where((hex) => hex.length == 6)
              .toList();

          if (hexCodes.length == 5) {
            final suggestedPalette = hexCodes
                .map((hex) => Color(int.parse('FF$hex', radix: 16)))
                .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ColorSuggestionsPage(
                  suggestedPalette: suggestedPalette,
                  explanation: explanation,
                ),
              ),
            );
          } else {
            throw Exception('Expected 5 colors, got ${hexCodes.length}');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing colors: ${e.toString()}')),
        );
      }
    }

    setState(() => isLoading = false);
  }

  void _analyzeUX(BuildContext context) async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image first')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: Constants.GEMINI_API_KEY,
      );

      final List<int> imageBytes = await _image!.readAsBytes();
      final Uint8List uint8Bytes = Uint8List.fromList(imageBytes);
      final imagePart = DataPart('image/jpeg', uint8Bytes);

      final uxPrompt = '''
        Analyze this ${widget.category} design image and provide UX improvement suggestions.
        Consider:
        - User flow and navigation
        - Visual hierarchy
        - Content organization
        - Interactive elements
        - Accessibility
        
        Format: Return 2-3 suggestions, each with:
        suggestion|explanation|article_url
        (one per line)
      ''';

      final uxContent = [
        Content.multi([imagePart, TextPart(uxPrompt)]),
      ];

      final response = await model.generateContent(uxContent);

      if (!mounted) return;

      if (response.text != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UXSuggestionsPage(
              suggestions: response.text!.split('\n').map((suggestion) {
                final parts = suggestion.split('|');
                return {
                  'suggestion': parts[0].trim(),
                  'explanation': parts.length > 1 ? parts[1].trim() : '',
                  'article': parts.length > 2 ? parts[2].trim() : '',
                };
              }).toList(),
              category: widget.category,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error analyzing UX')),
        );
      }
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Design Analysis',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Image upload card
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey[200]!,
                          ),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.grey[200]!,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: _image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_image!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.upload_file,
                                      size: 32,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Upload Design',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Choose an image to analyze',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Analysis buttons
                    Row(
                      children: [
                        Expanded(
                          child: _AnalysisButton(
                            icon: Icons.palette,
                            title: 'Analyze Colors',
                            description: 'Get color suggestions',
                            onTap: isLoading
                                ? null
                                : () => _analyzeColors(context),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _AnalysisButton(
                            icon: Icons.design_services,
                            title: 'Analyze UX',
                            description: 'Get UX improvements',
                            onTap: isLoading ? null : () => _analyzeUX(context),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 32),
                      const Center(child: CircularProgressIndicator()),
                    ],
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

class _AnalysisButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool isDark;

  const _AnalysisButton({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[200]!,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey[200]!,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
