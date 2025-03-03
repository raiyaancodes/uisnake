import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'inspiration_page.dart';
import 'typography_page.dart';
import 'design_elements_page.dart';
import 'design_systems_page.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class DesignComponentPage extends StatelessWidget {
  final String category;

  const DesignComponentPage({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final components = [
      {
        'title': 'Color Palettes',
        'icon': Icons.palette,
        'description': 'Generate harmonious color combinations for your design',
        'type': 'colors',
      },
      {
        'title': 'Design Elements',
        'icon': Icons.widgets,
        'description': 'Explore UI components, patterns, and layout elements',
        'type': 'elements',
      },
      {
        'title': 'Typography',
        'icon': Icons.text_fields,
        'description': 'Font combinations and text styling recommendations',
        'type': 'typography',
      },
      {
        'title': 'Design Systems',
        'icon': Icons.design_services,
        'description': 'Analyze and improve your design with AI suggestions',
        'type': 'system',
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Component',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'What aspect of $category are you working on?',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: isDark ? Colors.white70 : Colors.black54,
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
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: components.length,
                itemBuilder: (context, index) {
                  final component = components[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ComponentCard(
                      title: component['title'] as String,
                      icon: component['icon'] as IconData,
                      description: component['description'] as String,
                      onTap: () {
                        if (component['type'] == 'colors') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InspirationPage(
                                category: category,
                              ),
                            ),
                          );
                        } else if (component['type'] == 'typography') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TypographyPage(
                                category: category,
                              ),
                            ),
                          );
                        } else if (component['type'] == 'elements') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DesignElementsPage(
                                category: category,
                              ),
                            ),
                          );
                        } else if (component['type'] == 'system') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DesignSystemsPage(
                                category: category,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${component['title']} coming soon!',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComponentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const ComponentCard({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[200]!,
            width: 1,
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
        child: Row(
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ],
        ),
      ),
    );
  }
}
