import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme_provider.dart';

class DesignElementsPage extends StatefulWidget {
  final String category;

  const DesignElementsPage({
    super.key,
    required this.category,
  });

  @override
  State<DesignElementsPage> createState() => _DesignElementsPageState();
}

class _DesignElementsPageState extends State<DesignElementsPage> {
  late List<Map<String, dynamic>> resources;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    resources = getResourcesByCategory(widget.category);
  }

  List<Map<String, dynamic>> getResourcesByCategory(String category) {
    switch (category) {
      case 'Mobile App':
        return [
          {
            'title': 'Material Design Components',
            'description':
                'Official Material Design UI components and guidelines',
            'url': 'https://m3.material.io/components',
            'type': 'Components',
            'icon': Icons.widgets,
          },
          {
            'title': 'iOS Design Resources',
            'description':
                'Apple\'s Human Interface Guidelines and UI elements',
            'url': 'https://developer.apple.com/design/resources/',
            'type': 'Components',
            'icon': Icons.phone_iphone,
          },
          {
            'title': 'Mobile UI Patterns',
            'description':
                'Collection of common mobile UI patterns and solutions',
            'url': 'https://mobbin.com',
            'type': 'Inspiration',
            'icon': Icons.grid_view,
          },
          {
            'title': 'Flutter Widget Catalog',
            'description': 'Comprehensive guide to Flutter widgets',
            'url': 'https://docs.flutter.dev/ui/widgets',
            'type': 'Components',
            'icon': Icons.flutter_dash,
          },
          {
            'title': 'Nielsen Norman Group',
            'description': 'Mobile UX research and best practices',
            'url': 'https://www.nngroup.com/articles/mobile-ux/',
            'type': 'Articles',
            'icon': Icons.article,
          },
          // Add more mobile app resources...
        ];

      case 'Web Design':
        return [
          {
            'title': 'Web.dev',
            'description': 'Google\'s guidance for modern web development',
            'url': 'https://web.dev',
            'type': 'Articles',
            'icon': Icons.web,
          },
          {
            'title': 'Tailwind Components',
            'description': 'Ready-to-use Tailwind CSS components',
            'url': 'https://tailwindui.com',
            'type': 'Components',
            'icon': Icons.code,
          },
          {
            'title': 'Awwwards',
            'description': 'Best web design inspiration and trends',
            'url': 'https://www.awwwards.com',
            'type': 'Inspiration',
            'icon': Icons.star,
          },
          {
            'title': 'Smashing Magazine',
            'description': 'In-depth web design and development articles',
            'url': 'https://www.smashingmagazine.com',
            'type': 'Articles',
            'icon': Icons.article,
          },
          // Add more web design resources...
        ];

      case 'UI/UX Design':
        return [
          {
            'title': 'Design Systems Examples',
            'description': 'Collection of public design systems',
            'url': 'https://designsystems.com',
            'type': 'Components',
            'icon': Icons.style,
          },
          {
            'title': 'UI Design Daily',
            'description': 'Daily UI design inspiration and resources',
            'url': 'https://uidesigndaily.com',
            'type': 'Inspiration',
            'icon': Icons.palette,
          },
          {
            'title': 'UX Collective',
            'description': 'Curated UX design articles and case studies',
            'url': 'https://uxdesign.cc',
            'type': 'Articles',
            'icon': Icons.article,
          },
          // Add more UI/UX resources...
        ];
      case 'Print Design':
        return [
          {
            'title': 'Design Systems Examples',
            'description': 'Collection of public design systems',
            'url': 'https://designsystems.com',
            'type': 'Components',
            'icon': Icons.style,
          },
        ];

      default:
        return [];
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final filters = ['All', 'Components', 'Inspiration', 'Articles'];
    final filteredResources = selectedFilter == 'All'
        ? resources
        : resources.where((r) => r['type'] == selectedFilter).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Design Resources',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
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
                  const SizedBox(height: 8),
                  Text(
                    'Best components and resources for ${widget.category}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: filters.map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(filter),
                      onSelected: (bool selected) {
                        setState(() => selectedFilter = filter);
                      },
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[100],
                      selectedColor: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.blue[100],
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredResources.length,
                itemBuilder: (context, index) {
                  final resource = filteredResources[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color:
                        isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          resource['icon'] as IconData,
                          color: isDark ? Colors.white : Colors.blue,
                        ),
                      ),
                      title: Text(
                        resource['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            resource['description'] as String,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            resource['type'] as String,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.open_in_new,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      onTap: () => _launchUrl(resource['url'] as String),
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
