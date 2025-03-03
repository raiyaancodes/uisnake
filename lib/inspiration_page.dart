import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'tinder.dart';

class InspirationPage extends StatefulWidget {
  final String category;

  const InspirationPage({
    super.key,
    required this.category,
  });

  @override
  State<InspirationPage> createState() => _InspirationPageState();
}

class _InspirationPageState extends State<InspirationPage> {
  final List<String> selectedItems = [];
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // Example suggestions to help users get started
  Map<String, List<String>> categorySuggestions = {
    'Mobile App': [
      'Minimalist',
      'Retro',
      'Modern',
      'Snapchat-like',
      'Pinterest-style',
      'Instagram',
      'Spotify',
      'Playful',
      'Professional',
      'Elegant',
      'Material Design',
      'iOS Style',
      'Dark Theme',
      'Colorful',
      'Monochrome',
      'Glassmorphic',
      'Neumorphic',
      'Gradient-based',
      'Flat Design',
      'Animated UI',
      'Gaming Style',
      'Social Media',
      'E-commerce',
      'Fitness App',
      'Banking App',
    ],
    'Web Design': [
      'Modern Portfolio',
      'E-commerce',
      'Blog',
      'Dashboard',
      'Landing Page',
      'Magazine Style',
      'Minimalist',
      'Creative Agency',
      'Tech Startup',
      'Social Platform',
      'Web App',
      'SaaS Platform',
      'Educational',
      'News Portal',
      'Corporate',
      'Portfolio',
      'Single Page',
      'Multi Page',
      'Responsive',
      'Interactive',
    ],
    'Logo Design': [
      'Minimalist',
      'Vintage',
      'Modern',
      'Abstract',
      'Geometric',
      'Mascot',
      'Lettermark',
      'Emblem',
      'Pictorial',
      'Wordmark',
      'Combination Mark',
      'Dynamic',
      'Flat',
      '3D Style',
      'Hand Drawn',
      'Negative Space',
      'Symmetrical',
      'Asymmetrical',
      'Iconic',
      'Versatile',
    ],
    'UI/UX Design': [
      'Clean',
      'Brutalist',
      'Neumorphic',
      'Glassmorphism',
      'Skeuomorphic',
      'Flat Design',
      'Material You',
      'iOS Style',
      'Dark Mode',
      'Colorful',
      'Minimalist',
      'Maximalist',
      'Experimental',
      'Futuristic',
      'Retro',
      'Organic',
      'Geometric',
      'Playful',
      'Corporate',
      'Luxury',
    ],
  };

  List<String> getSuggestions() {
    if (searchQuery.isEmpty) {
      return categorySuggestions[widget.category] ?? [];
    }
    final suggestions = (categorySuggestions[widget.category] ?? [])
        .where((item) => item.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
    // Add the search query if it's not in suggestions
    if (searchQuery.isNotEmpty && !suggestions.contains(searchQuery)) {
      suggestions.insert(0, searchQuery);
    }
    return suggestions;
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
                        'Draw Inspiration',
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
                      const SizedBox(height: 4),
                      Text(
                        'Type anything or choose from suggestions',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white60 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () {
                      themeProvider.toggleTheme();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar with cleaner light mode
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey[300]!,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.grey[200]!,
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
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
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
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

              // Selected Items with cleaner light mode
              if (selectedItems.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedItems
                      .map((item) => Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.grey[300]!,
                              ),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.grey[200]!,
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedItems.remove(item);
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Suggestions
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: getSuggestions().length,
                  itemBuilder: (context, index) {
                    final suggestion = getSuggestions()[index];
                    final isSelected = selectedItems.contains(suggestion);

                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          setState(() {
                            selectedItems.remove(suggestion);
                          });
                        } else if (selectedItems.length < 5) {
                          setState(() {
                            selectedItems.add(suggestion);
                          });
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

              // Continue Button
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedItems.length == 5
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TinderPage(
                                palettes: const [
                                  [
                                    Color(0xFF1A237E),
                                    Color(0xFF42A5F5),
                                    Color(0xFF90CAF9),
                                    Color(0xFFBBDEFB),
                                    Color(0xFF0D47A1),
                                  ]
                                ],
                                inspirations: selectedItems,
                                category: widget.category,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.white.withOpacity(0.1) : Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Continue (${selectedItems.length}/5)',
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
}
