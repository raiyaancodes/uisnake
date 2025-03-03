import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:image_picker/image_picker.dart';
import 'pallete.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
    // Filter for external/webcam cameras when on emulator
    if (Platform.isAndroid) {
      final isEmulator = await _isEmulator();
      if (isEmulator) {
        // Try to find external camera (usually laptop webcam)
        cameras = cameras
            .where((camera) =>
                camera.name.toLowerCase().contains('external') ||
                camera.name.toLowerCase().contains('webcam') ||
                camera.lensDirection == CameraLensDirection.front)
            .toList();
      }
    }
  } catch (e) {
    debugPrint('Error getting cameras: $e');
  }

  runApp(MyApp(camera: cameras.isNotEmpty ? cameras.first : null));
}

// Helper function to detect if running on emulator
Future<bool> _isEmulator() async {
  if (Platform.isAndroid) {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return !androidInfo.isPhysicalDevice;
    } catch (e) {
      debugPrint('Error checking device type: $e');
    }
  }
  return false;
}

class MyApp extends StatelessWidget {
  final CameraDescription? camera;

  const MyApp({super.key, this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: CameraPage(camera: camera),
    );
  }
}

class CameraPage extends StatefulWidget {
  final CameraDescription? camera;

  const CameraPage({super.key, this.camera});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  File? _image;
  final List<Color> _colors =
      List.filled(5, Colors.grey); // Initialize with grey
  bool _isDisposed = false;
  bool _showCapturedImage = false;
  String _imageDescription = '';
  bool _isCaptureInProgress = false;
  ui.Image? _cachedImage;

  // Update model to use the latest version
  final model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: 'AIzaSyBMBDehIuvdMK3Gv16AOROt1Kxre-bWn7o',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.camera != null) {
      _initializeCamera();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImage();
      });
    }
  }

  Future<void> _initializeCamera() async {
    if (widget.camera == null || _isDisposed) return;

    try {
      _controller = CameraController(
        widget.camera!,
        ResolutionPreset.medium, // Lower resolution for better performance
        enableAudio: false, // Disable audio
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420 // Better format for Android
            : ImageFormatGroup.bgra8888,
      );

      _initializeControllerFuture = _controller?.initialize();

      if (!_isDisposed) {
        setState(() {});
      }

      // Set focus mode to auto
      if (_controller!.value.isInitialized) {
        await _controller!.setFocusMode(FocusMode.auto);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      // If camera fails, default to image picker
      if (mounted) {
        _pickImage();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _cachedImage?.dispose();
    _initializeControllerFuture = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<ui.Image> loadImage(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<(String, List<Color>)> _analyzeImageAndGetColors(
      File imageFile) async {
    int retryCount = 0;
    while (retryCount < 3) {
      try {
        debugPrint('Starting image analysis...');

        // Always resize image on Android devices to reduce memory usage
        var bytes = await imageFile.readAsBytes();
        debugPrint('Original image size: ${bytes.length} bytes');

        if (Platform.isAndroid || bytes.length > 4 * 1024 * 1024) {
          debugPrint('Resizing image for Android/large size...');
          final img.Image? image = img.decodeImage(bytes);
          if (image != null) {
            final resized =
                img.copyResize(image, width: 600); // Smaller width for Android
            bytes = Uint8List.fromList(
                img.encodeJpg(resized, quality: 70)); // Lower quality
            debugPrint('Resized image size: ${bytes.length} bytes');
          }
        }

        // Simplified prompt for better performance
        final prompt =
            'Describe this image briefly and list 5 main colors as hex codes. Format: {"description": "brief text", "colors": ["#hex1", "#hex2", "#hex3", "#hex4", "#hex5"]}';

        debugPrint('Sending request to Gemini...');
        final response = await model.generateContent(
          [
            Content.multi([TextPart(prompt), DataPart('image/jpeg', bytes)])
          ],
          generationConfig: GenerationConfig(
            temperature: 0.4,
            candidateCount: 1,
            maxOutputTokens: 200,
          ),
        ).timeout(
          const Duration(seconds: 45),
          onTimeout: () =>
              throw TimeoutException('Request timed out after 45s'),
        );

        debugPrint('Received response: ${response.text}');

        if (response.text == null) {
          throw Exception('Empty response from AI');
        }

        // Extract JSON from response using regex
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(response.text!);
        if (jsonMatch == null) {
          throw Exception('Invalid response format');
        }

        try {
          final jsonResponse = json.decode(jsonMatch.group(0)!);
          final description = jsonResponse['description'] as String? ??
              'No description available';
          final hexColors = List<String>.from(jsonResponse['colors'] ?? []);

          // Validate and convert hex colors
          final colors = hexColors.map((hex) {
            try {
              if (!hex.startsWith('#')) hex = '#$hex';
              return Color(int.parse(hex.replaceAll('#', '0xFF')));
            } catch (e) {
              debugPrint('Invalid hex color: $hex');
              return Colors.grey;
            }
          }).toList();

          // Ensure we have exactly 5 colors
          while (colors.length < 5) {
            colors.add(Colors.grey);
          }

          debugPrint('Successfully analyzed image: $description');
          return (description, colors);
        } catch (e) {
          debugPrint('JSON parsing error: $e');
          throw Exception('Failed to parse AI response');
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= 3) {
          debugPrint('Failed after 3 retries: $e');
          return ('Could not analyze image', List.filled(5, Colors.grey));
        }
        await Future.delayed(Duration(seconds: 2 * retryCount));
        debugPrint('Retrying... attempt $retryCount');
        continue;
      }
    }
    return ('Could not analyze image', List.filled(5, Colors.grey));
  }

  void _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, // Limit image size
        maxHeight: 1080,
        imageQuality: 85, // Slightly compress
      );

      if (pickedFile != null && !_isDisposed) {
        BuildContext? dialogContext;

        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            dialogContext = context;
            return WillPopScope(
              onWillPop: () async => false,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Analyzing image...',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        try {
          debugPrint('Processing picked image...');
          final imageFile = File(pickedFile.path);
          _cachedImage?.dispose();
          _cachedImage = await loadImage(imageFile);

          debugPrint('Starting image analysis...');
          final (description, colors) =
              await _analyzeImageAndGetColors(imageFile);

          if (!_isDisposed && mounted) {
            setState(() {
              _image = imageFile;
              _colors.setAll(0, colors);
              _imageDescription = description;
            });

            // Navigate to palette page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PalettePage(
                  colors: List<Color>.from(_colors),
                  description: description,
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error processing image: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } finally {
          // Close loading dialog
          if (dialogContext != null && mounted) {
            Navigator.pop(dialogContext!);
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<List<Color>> _getAISuggestedColors(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Prepare the prompt
      final prompt = '''
      Analyze this image and suggest a color palette of exactly 5 colors that represents the mood, 
      theme, and objects in the image. Return only the colors in a JSON array of hex codes.
      For example: ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF"]
      ''';

      // Create image data for Gemini
      final imageData = DataPart('image/jpeg', bytes);

      // Get response from Gemini
      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          imageData,
        ])
      ]);

      // Parse the response
      final responseText = response.text;
      if (responseText == null) throw Exception('No response from AI');

      // Extract the JSON array from the response
      final hexCodes = List<String>.from(json.decode(responseText));

      // Convert hex codes to Colors
      return hexCodes
          .map((hex) => Color(int.parse(hex.replaceAll('#', '0xFF'))))
          .toList();
    } catch (e) {
      debugPrint('Error getting AI suggestions: $e');
      return List.filled(5, Colors.grey);
    }
  }

  Future<void> _extractColors(File imageFile) async {
    if (_isDisposed) return;

    try {
      final aiColors = await _getAISuggestedColors(imageFile);

      if (!_isDisposed) {
        setState(() {
          for (var i = 0; i < 5; i++) {
            _colors[i] = aiColors[i];
          }
        });
      }
    } catch (e) {
      debugPrint('Error in _extractColors: $e');
      if (!_isDisposed) {
        setState(() {
          _colors.fillRange(0, 5, Colors.grey);
        });
      }
    }
  }

  Future<void> _captureImage() async {
    if (_isCaptureInProgress) return;

    try {
      _isCaptureInProgress = true;
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();

      if (!_isDisposed && mounted) {
        final imageFile = File(image.path);
        final (description, colors) =
            await _analyzeImageAndGetColors(imageFile);

        setState(() {
          _image = imageFile;
          _colors.setAll(0, colors);
          _showCapturedImage = true;
          _imageDescription = description;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PalettePage(
              colors: List<Color>.from(_colors),
              description: description,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    } finally {
      _isCaptureInProgress = false;
    }
  }

  Future<http.Client> _getCustomHttpClient() async {
    return http.Client();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.camera == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pick Image from Gallery'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_showCapturedImage && _image != null)
            Image.file(
              _image!,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.cover,
            )
          else
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: CameraPreview(_controller!),
                  );
                } else {
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  );
                }
              },
            ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_showCapturedImage)
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: FloatingActionButton(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        onPressed: () {
                          setState(() {
                            _showCapturedImage = false;
                          });
                        },
                        heroTag: 'newPhoto',
                        tooltip: 'Take New Photo',
                        child: const Icon(Icons.camera, color: Colors.white),
                      ),
                    )
                  else
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: FloatingActionButton(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        onPressed: _pickImage,
                        heroTag: 'upload',
                        tooltip: 'Upload Image',
                        child: const Icon(Icons.upload, color: Colors.white),
                      ),
                    ),
                  if (!_showCapturedImage)
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: FloatingActionButton(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        onPressed: _captureImage,
                        heroTag: 'shutter',
                        tooltip: 'Capture Image',
                        child:
                            const Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
