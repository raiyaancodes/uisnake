import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme_provider.dart';
import 'constants.dart';

class TypographyPage extends StatefulWidget {
  final String category;

  const TypographyPage({
    super.key,
    required this.category,
  });

  @override
  State<TypographyPage> createState() => _TypographyPageState();
}

class _TypographyPageState extends State<TypographyPage> {
  final List<String> selectedItems = [];
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  bool isLoading = false;
  List<Map<String, String>> suggestedFonts = [];

  Map<String, List<String>> categorySuggestions = {
    'Mobile App': [
      'Clean and Modern',
      'Playful Sans-serif',
      'Professional',
      'Minimalist',
      'Bold Headlines',
      'Readable Body Text',
      'Instagram Style',
      'Spotify Typography',
      'iOS Native Look',
      'Material Design',
    ],
    'Web Design': [
      'Modern Editorial',
      'Tech Blog',
      'E-commerce',
      'Portfolio Style',
      'Landing Page',
      'Magazine Layout',
      'Documentation',
      'Dashboard UI',
      'News Portal',
      'Corporate Site',
    ],
    'Logo Design': [
      'Elegant Serif',
      'Modern Sans',
      'Geometric',
      'Handwritten',
      'Vintage Style',
      'Tech Brand',
      'Luxury Brand',
      'Friendly Brand',
      'Sports Brand',
      'Fashion Label',
    ],
  };

  Future<void> _generateFontSuggestions() async {
    setState(() => isLoading = true);

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: Constants.GEMINI_API_KEY,
      );

      final prompt = '''
        As a typography expert, suggest Google Fonts combinations for a ${widget.category} project.
        The client wants a style that incorporates these preferences: ${selectedItems.join(', ')}.
        
        Consider:
        - The project type (${widget.category})
        - The desired style elements
        - Readability and accessibility
        - Modern font availability
        
        For each combination, provide:
        1. A display/heading font that captures the main style
        2. A complementary body text font that ensures readability
        3. A brief explanation of why they work together
        
        Format: Return exactly 5 lines in this format:
        Heading Font|Body Font|Brief explanation
        
        Use only Google Fonts that are popular and widely available.
        Verify each font exists on Google Fonts before suggesting it.
        Focus on proven, reliable nb font combinations.
        ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final suggestions = response.text!.split('\n');

      suggestedFonts = suggestions.map((suggestion) {
        final parts = suggestion.split('|');
        if (parts.length >= 3) {
          return {
            'primary': parts[0].trim(),
            'secondary': parts[1].trim(),
            'explanation': parts[2].trim(),
          };
        }
        // Fallback to reliable fonts if parsing fails
        return {
          'primary': 'Inter',
          'secondary': 'Roboto',
          'explanation':
              'Modern and versatile combination suitable for digital interfaces',
        };
      }).toList();

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        isLoading = false;
        suggestedFonts = [
          {
            'primary': 'Inter',
            'secondary': 'Roboto',
            'explanation': 'Modern and versatile combination',
          },
          {
            'primary': 'Poppins',
            'secondary': 'Open Sans',
            'explanation': 'Clean and professional pairing',
          },
          {
            'primary': 'Montserrat',
            'secondary': 'Source Sans Pro',
            'explanation': 'Contemporary and readable combination',
          },
        ];
      });
      showNotification('Error generating fonts. Using reliable defaults.');
    }
  }

  void showNotification(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _launchFontUrl(String fontName) async {
    final url = Uri.parse('https://fonts.google.com/specimen/$fontName');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      showNotification('Could not open font page');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Typography Style',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share 5 styles you love',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: isDark ? Colors.white70 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey[300]!,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type any style or select below...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black45,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? Colors.white70 : Colors.black45,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty && selectedItems.length < 5) {
                      setState(() {
                        selectedItems.add(value);
                        _searchController.clear();
                        searchQuery = '';
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Selected Items
              if (selectedItems.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedItems
                      .map((item) => Chip(
                            label: Text(item),
                            onDeleted: () {
                              setState(() => selectedItems.remove(item));
                            },
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey[100],
                            labelStyle: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Suggestions Grid
              if (suggestedFonts.isEmpty) ...[
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount:
                        (categorySuggestions[widget.category] ?? []).length,
                    itemBuilder: (context, index) {
                      final suggestion =
                          categorySuggestions[widget.category]![index];
                      final isSelected = selectedItems.contains(suggestion);

                      return GestureDetector(
                        onTap: () {
                          if (isSelected) {
                            setState(() => selectedItems.remove(suggestion));
                          } else if (selectedItems.length < 5) {
                            setState(() => selectedItems.add(suggestion));
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.blue.withOpacity(0.1))
                                : (isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[50]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.blue.withOpacity(0.3))
                                  : (isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey[200]!),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              suggestion,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                // Font Suggestions
                Expanded(
                  child: ListView.builder(
                    itemCount: suggestedFonts.length,
                    itemBuilder: (context, index) {
                      final font = suggestedFonts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () =>
                                          _launchFontUrl(font['primary']!),
                                      child: Text(
                                        font['primary']!,
                                        style: _getFontStyle(
                                          font['primary']!,
                                          24,
                                          isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.open_in_new,
                                    size: 16,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () =>
                                          _launchFontUrl(font['secondary']!),
                                      child: Text(
                                        font['secondary']!,
                                        style: _getFontStyle(
                                          font['secondary']!,
                                          16,
                                          isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.open_in_new,
                                    size: 16,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                font['explanation']!,
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Generate Button
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedItems.isNotEmpty
                      ? () => _generateFontSuggestions()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.white.withOpacity(0.1) : Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          suggestedFonts.isEmpty
                              ? 'Generate Suggestions (${selectedItems.length} selected)'
                              : 'Generate New Suggestions',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _getFontStyle(String fontFamily, double fontSize, Color color) {
    try {
      return GoogleFonts.getFont(
        fontFamily,
        fontSize: fontSize,
        color: color,
      );
    } catch (e) {
      // Fallback to a reliable font if the requested one fails to load
      return GoogleFonts.inter(
        fontSize: fontSize,
        color: color,
      );
    }
  }
}
