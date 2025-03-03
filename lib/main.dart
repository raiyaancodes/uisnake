import 'package:colors_test/camera.dart';
import 'package:colors_test/category_page.dart';
import 'package:colors_test/tinder.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:colors_test/pallete.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:colors_test/category_page.dart';
import 'package:provider/provider.dart';
import 'package:colors_test/theme_provider.dart';
import 'package:device_preview/device_preview.dart';

CameraDescription? camera; // Make camera nullable

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
        '/camerapage': (context) => camera != null
            ? CameraPage(camera: camera!)
            : Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Camera not available'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (pickedFile != null && context.mounted) {
                            final File imageFile = File(pickedFile.path);
                            final paletteGenerator =
                                await PaletteGenerator.fromImageProvider(
                              FileImage(imageFile),
                              maximumColorCount: 5,
                            );
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PalettePage(
                                    colors: paletteGenerator.colors
                                        .take(5)
                                        .toList(),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Pick Image from Gallery'),
                      ),
                    ],
                  ),
                ),
              ),
        '/palettepage': (context) => PalettePage(colors: []),
        '/tinder': (context) => const TinderPage(
              palettes: [],
              inspirations: [],
              category: 'Default',
            ),
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final cameras = await availableCameras();
    camera = cameras.first;
  } catch (e) {
    debugPrint('No camera available: $e');
  }

  runApp(
    DevicePreview(
      backgroundColor: Colors.white,
      enabled: true,
      defaultDevice: Devices.ios.iPhone13ProMax,
      isToolbarVisible: true,
      availableLocales: const [Locale('en', 'US')],
      tools: const [
        DeviceSection(
          model: true,
          orientation: false,
          frameVisibility: false,
          virtualKeyboard: false,
        ),
      ],
      devices: [
        // Android Devices
        Devices.android.samsungGalaxyA50,
        Devices.android.samsungGalaxyNote20,
        Devices.android.samsungGalaxyS20,

        // iOS Devices
        Devices.ios.iPhone12,
        Devices.ios.iPhone13ProMax,
        Devices.ios.iPhoneSE,
      ],
      builder: (context) => ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Palette Generator',
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          background: Colors.white,
        ),
        primaryColor: Colors.blue,
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: Provider.of<ThemeProvider>(context).isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,
      home: const CategoryPage(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCameraPage(BuildContext context) {
    if (camera != null) {
      return CameraPage(camera: camera!);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Camera not available'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final picker = ImagePicker();
              final pickedFile =
                  await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                final File imageFile = File(pickedFile.path);
                final paletteGenerator =
                    await PaletteGenerator.fromImageProvider(
                  FileImage(imageFile),
                  maximumColorCount: 5,
                );
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PalettePage(
                        colors: paletteGenerator.colors.take(5).toList(),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Pick Image from Gallery'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildCameraPage(context),
      const TinderPage(palettes: [], inspirations: [], category: 'Default'),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.color_lens),
            label: 'Colors',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
