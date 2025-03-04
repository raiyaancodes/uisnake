import 'package:flutter/material.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'constants.dart';

class TinderPage extends StatefulWidget {
  final List<List<Color>> palettes;
  final List<String> inspirations;
  final String category;

  const TinderPage({
    super.key,
    required this.palettes,
    required this.inspirations,
    required this.category,
  });

  @override
  State<TinderPage> createState() => _TinderPageState();
}

class _TinderPageState extends State<TinderPage> {
  final controller = SwipableStackController();
  final List<List<Color>> favorites = [];
  final Map<int, Color> lockedColors = {};
  late List<List<Color>> displayPalettes = [];
  late List<Color> currentPalette;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateInitialPalettes();
  }

  Future<void> _generateInitialPalettes() async {
    setState(() => isLoading = true);

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: Constants.GEMINI_API_KEY,
      );

      final prompt = '''
        Task: Generate 5 color palettes for ${widget.category} design inspired by: ${widget.inspirations.join(', ')}.

        Requirements:
        - Each palette must have exactly 5 hex color codes
        - Colors should match ${widget.inspirations.join(', ')} style
        - Colors must be suitable for ${widget.category}

        Format:
        - Return 5 lines
        - Each line: 5 hex codes without #, separated by commas
        - Example: 1A237E,42A5F5,90CAF9,BBDEFB,0D47A1

        Return only hex codes, no explanations or other text.
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response');
      }

      final palettes = response.text!
          .trim()
          .split('\n')
          .map((line) => line.replaceAll(' ', ''))
          .where((line) => line.isNotEmpty)
          .toList();

      displayPalettes = palettes.map((paletteStr) {
        return paletteStr
            .split(',')
            .map((hex) => Color(int.parse('FF${hex.trim()}', radix: 16)))
            .toList();
      }).toList();

      if (displayPalettes.isEmpty) {
        throw Exception('No palettes generated');
      }

      currentPalette = List.from(displayPalettes.first);
    } catch (e) {
      print('Error details: $e'); // For debugging
      rethrow; // Let the error propagate to trigger a retry
    }

    setState(() => isLoading = false);
  }

  Future<List<Color>> _generateNewPalette(
      List<Color> basePalette, bool similar) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: Constants.GEMINI_API_KEY,
      );

      final baseColors = basePalette
          .map((c) => c.value.toRadixString(16).toUpperCase().substring(2))
          .join(',');

      final prompt = '''
        Task: Generate a ${similar ? 'similar' : 'different'} color palette for ${widget.category}.
        
        Base palette: $baseColors
        Style inspiration: ${widget.inspirations.join(', ')}
        
        Rules for ${similar ? 'similar' : 'different'} palette:
        ${similar ? '''
        - Keep the same overall mood and feeling
        - Use similar hues and saturation levels
        - Maintain similar contrast ratios
        - Make subtle variations of the original colors
        ''' : '''
        - Create a distinctly different mood while keeping the style
        - Use complementary or triadic color relationships
        - Maintain accessibility standards
        - Ensure colors work well for ${widget.category}
        '''}
        
        Requirements:
        - Return exactly 5 hex codes without #
        - Colors must work together harmoniously
        - Follow color theory principles
        - Maintain ${widget.category} design standards
        
        Format: Return only 5 hex codes separated by commas
        Example: 1A237E,42A5F5,90CAF9,BBDEFB,0D47A1
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response');
      }

      final hexCodes = response.text!
          .trim()
          .split(',')
          .map((hex) => hex.trim())
          .where((hex) => hex.length == 6) // Ensure valid hex codes
          .take(5) // Ensure exactly 5 colors
          .toList();

      if (hexCodes.length != 5) {
        throw Exception('Invalid number of colors');
      }

      return hexCodes
          .map((hex) => Color(int.parse('FF$hex', radix: 16)))
          .toList();
    } catch (e) {
      debugPrint('Error generating palette: $e');
      // Use the fallback algorithm as backup
      return generateFallbackPalette(basePalette, similar);
    }
  }

  List<List<Color>> _generateFallbackPalettes() {
    // Generate default palettes based on category
    switch (widget.category) {
      case 'Mobile App':
        return [
          [
            const Color(0xFF2196F3), // Blue
            const Color(0xFF1976D2), // Darker Blue
            const Color(0xFFBBDEFB), // Light Blue
            const Color(0xFF212121), // Almost Black
            const Color(0xFFFFFFFF), // White
          ],
          // Add more mobile app specific palettes...
        ];
      case 'Web Design':
        return [
          [
            const Color(0xFF424242), // Dark Grey
            const Color(0xFFFAFAFA), // Almost White
            const Color(0xFF2196F3), // Blue
            const Color(0xFF757575), // Medium Grey
            const Color(0xFFE0E0E0), // Light Grey
          ],
          // Add more web specific palettes...
        ];
      // Add cases for other categories...
      default:
        return [
          [
            const Color(0xFF1A237E),
            const Color(0xFF42A5F5),
            const Color(0xFF90CAF9),
            const Color(0xFFBBDEFB),
            const Color(0xFF0D47A1),
          ],
        ];
    }
  }

  List<Color> generateFallbackPalette(List<Color> basePalette, bool similar) {
    List<Color> newPalette = List.from(basePalette);

    for (int i = 0; i < newPalette.length; i++) {
      if (lockedColors.containsKey(i)) continue;

      final HSLColor hsl = HSLColor.fromColor(basePalette[i]);
      double newHue, newSaturation, newLightness;

      if (similar) {
        // Similar colors - stay within a closer range
        newHue = (hsl.hue + (Random().nextDouble() * 20 - 10)).clamp(0, 360);
        newSaturation = (hsl.saturation + Random().nextDouble() * 0.15 - 0.075)
            .clamp(0.1, 0.9);
        newLightness = (hsl.lightness + Random().nextDouble() * 0.15 - 0.075)
            .clamp(0.1, 0.9);
      } else {
        // Different colors - use complementary or triadic harmony
        final random = Random().nextDouble();
        if (random < 0.5) {
          newHue = (hsl.hue + 180) % 360; // Complementary
        } else {
          newHue = (hsl.hue + (random < 0.75 ? 120 : 240)) % 360; // Triadic
        }
        newSaturation = (0.3 + Random().nextDouble() * 0.5).clamp(0.3, 0.8);
        newLightness = (1 - hsl.lightness).clamp(0.2, 0.8);
      }

      newPalette[i] =
          HSLColor.fromAHSL(1.0, newHue, newSaturation, newLightness).toColor();
    }

    return newPalette;
  }

  void _showShareDialog(List<Color> palette) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Share Color Codes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('HEX Codes'),
                onTap: () {
                  String hexCodes = palette
                      .map((c) =>
                          '#${c.value.toRadixString(16).toUpperCase().substring(2)}')
                      .join(', ');
                  Clipboard.setData(ClipboardData(text: hexCodes));
                  Navigator.pop(context);
                  showNotification('HEX codes copied to clipboard!');
                },
              ),
              ListTile(
                title: const Text('ARGB Codes'),
                onTap: () {
                  String argbCodes = palette
                      .map((c) =>
                          'ARGB(${c.alpha}, ${c.red}, ${c.green}, ${c.blue})')
                      .join(', ');
                  Clipboard.setData(ClipboardData(text: argbCodes));
                  Navigator.pop(context);
                  showNotification('ARGB codes copied to clipboard!');
                },
              ),
              ListTile(
                title: const Text('Flutter Color Code'),
                onTap: () {
                  String flutterCodes = palette
                      .map((c) =>
                          'Color(0x${c.value.toRadixString(16).toUpperCase()})')
                      .join(', ');
                  Clipboard.setData(ClipboardData(text: flutterCodes));
                  Navigator.pop(context);
                  showNotification('Flutter color codes copied to clipboard!');
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void onSwipeCompleted(int index, SwipeDirection direction) {
    // Get the current palette
    final currentIndex = index % displayPalettes.length;
    currentPalette = List.from(displayPalettes[currentIndex]);

    // Generate new palette based on swipe direction
    List<Color> newPalette;
    switch (direction) {
      case SwipeDirection.right:
        newPalette = generateFallbackPalette(currentPalette, true);
        showNotification('Finding similar palettes!');
        break;
      case SwipeDirection.left:
        newPalette = generateFallbackPalette(currentPalette, false);
        showNotification('Finding different palettes!');
        break;
      case SwipeDirection.up:
        if (!favorites.contains(currentPalette)) {
          favorites.add(List.from(currentPalette));
          showNotification('Added to favorites!');
        }
        newPalette =
            generateFallbackPalette(currentPalette, Random().nextBool());
        break;
      default:
        return;
    }

    // Double-check locked colors are preserved
    lockedColors.forEach((index, color) {
      if (index < newPalette.length) {
        newPalette[index] = color;
      }
    });

    setState(() {
      displayPalettes.removeAt(currentIndex);
      displayPalettes.add(newPalette);
      currentPalette = List.from(newPalette);
    });
  }

  Widget _buildCard(List<Color> palette) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Row(
                  children: palette.asMap().entries.map((entry) {
                    final index = entry.key;
                    final color = entry.value;
                    final isLocked = lockedColors.containsKey(index);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isLocked) {
                              lockedColors.remove(index);
                            } else {
                              lockedColors[index] = color;
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            border: index > 0
                                ? Border(
                                    left: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '#${color.value.toRadixString(16).toUpperCase().substring(2)}',
                                style: GoogleFonts.inter(
                                  color: color.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Icon(
                                isLocked ? Icons.lock : Icons.lock_open,
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black54
                                    : Colors.white54,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showShareDialog(palette),
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Share Colors'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showNotification(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (displayPalettes.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No palettes available'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Palettes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Favorite Palettes'),
                  content: favorites.isEmpty
                      ? const Text('No favorites yet!')
                      : SizedBox(
                          width: double.maxFinite,
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: favorites.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: GestureDetector(
                                  onTap: () =>
                                      _showShareDialog(favorites[index]),
                                  child: Card(
                                    elevation: 4,
                                    child: Row(
                                      children: favorites[index]
                                          .map((color) => Expanded(
                                                child: Container(
                                                  height: 80,
                                                  color: color,
                                                  child: Center(
                                                    child: Text(
                                                      '#${color.value.toRadixString(16).toUpperCase().substring(2)}',
                                                      style: TextStyle(
                                                        color:
                                                            color.computeLuminance() >
                                                                    0.5
                                                                ? Colors.black
                                                                : Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width * 0.9,
          child: SwipableStack(
            controller: controller,
            itemCount: null,
            onSwipeCompleted: onSwipeCompleted,
            builder: (context, properties) {
              final index = properties.index % displayPalettes.length;
              return _buildCard(displayPalettes[index]);
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
