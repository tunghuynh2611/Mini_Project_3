import 'package:flutter/material.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/image_service.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/receipt_storage_service.dart';
import 'widgets/viewfinder_overlay.dart';

/// Live Camera Viewfinder & Receipt Capture Screen.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImageService _imageService = ImageService();
  final OcrService _ocrService = OcrService();
  final ReceiptStorageService _storageService = ReceiptStorageService.instance;

  bool _isFlashOn = false;
  bool _isProcessing = false;
  String _processingStatus = 'Initializing scanner...';

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _captureReceipt() async {
    try {
      setState(() {
        _isProcessing = true;
        _processingStatus = 'Opening camera...';
      });

      final imagePath = await _imageService.captureFromCamera();
      if (imagePath == null) {
        setState(() => _isProcessing = false);
        return;
      }

      await _processCapturedImage(imagePath);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showErrorDialog('Camera capture error: $e. You can also pick an image from gallery or select a sample receipt.');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() {
        _isProcessing = true;
        _processingStatus = 'Selecting image from gallery...';
      });

      final imagePath = await _imageService.pickFromGallery();
      if (imagePath == null) {
        setState(() => _isProcessing = false);
        return;
      }

      await _processCapturedImage(imagePath);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showErrorDialog('Gallery error: $e');
    }
  }

  Future<void> _processCapturedImage(String rawImagePath) async {
    setState(() {
      _processingStatus = 'Scanning receipt text with on-device AI...';
    });

    try {
      // 1. Process with OCR & Heuristics
      final extractedData = await _ocrService.processImage(rawImagePath);

      // 2. Persist receipt file to app documents directory
      final savedImagePath = await _storageService.saveReceiptImage(rawImagePath);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // 3. Navigate to Interactive Review Screen
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.review,
        arguments: ReviewScreenArguments(
          extractedData: extractedData,
          imagePath: savedImagePath,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showErrorDialog('OCR parsing failed: $e');
    }
  }

  /// Triggers a preset sample receipt for testing / desktop evaluation
  void _selectSampleReceipt(String name, String sampleText) async {
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Parsing sample receipt "$name"...';
    });

    await Future.delayed(const Duration(milliseconds: 300));
    final extractedData = _ocrService.processRawText(sampleText);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.review,
      arguments: ReviewScreenArguments(
        extractedData: extractedData,
        imagePath: '', // Sample text receipt
        isSample: true,
      ),
    );
  }

  void _showSampleReceiptsPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Sample Receipt',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Text(
                  'Test OCR heuristics on realistic supermarket receipts instantly:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFECE8),
                    child: Icon(Icons.shopping_cart, color: Colors.deepOrange),
                  ),
                  title: const Text('Siêu thị WinMart+'),
                  subtitle: const Text('194.400 đ • Groceries (Milk, Eggs, Bread)'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    _selectSampleReceipt('WinMart+', SampleReceipts.winmart);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF3E5F5),
                    child: Icon(Icons.coffee, color: Colors.deepPurple),
                  ),
                  title: const Text('Highlands Coffee'),
                  subtitle: const Text('194.000 VND • Cafe & Drinks'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    _selectSampleReceipt('Highlands Coffee', SampleReceipts.highlandsCoffee);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.menu_book, color: Colors.blue),
                  ),
                  title: const Text('Nhà sách Fahasa'),
                  subtitle: const Text('233.000 đ • Books & Stationery'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    _selectSampleReceipt('Fahasa Bookstore', SampleReceipts.fahasaBookstore);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.store, color: Colors.green),
                  ),
                  title: const Text('Circle K Store'),
                  subtitle: const Text('64.800 VND • Snacks & Drinks'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    _selectSampleReceipt('Circle K', SampleReceipts.circleK);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2F1),
                    child: Icon(Icons.directions_car, color: Colors.teal),
                  ),
                  title: const Text('GrabCar Ride'),
                  subtitle: const Text('70.000 đ • Commute & Travel'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    _selectSampleReceipt('GrabCar', SampleReceipts.grabRide);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notice'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Viewfinder cutout framing geometry (70% width, ~1.4 aspect ratio for receipts)
    final cutoutWidth = (size.width * 0.82).clamp(260.0, 420.0);
    final cutoutHeight = (cutoutWidth * 1.45).clamp(360.0, size.height * 0.65);
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, (size.height * 0.42)),
      width: cutoutWidth,
      height: cutoutHeight,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated camera background preview with subtle grid
          Positioned.fill(
            child: Container(
              color: const Color(0xFF131722),
              child: Center(
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 96,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),

          // Framing Guide Overlay with Animated Laser Scan
          Positioned.fill(
            child: ViewfinderOverlay(cutoutRect: cutoutRect),
          ),

          // Top Header & Controls Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Scan Receipt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isFlashOn ? Colors.amber : Colors.white,
                    ),
                    tooltip: 'Toggle Flash',
                    onPressed: () {
                      setState(() => _isFlashOn = !_isFlashOn);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isFlashOn ? 'Flash enabled' : 'Flash disabled'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Viewfinder Guidance Instruction Text
          Positioned(
            top: cutoutRect.bottom + 16,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.center_focus_strong_rounded, size: 14, color: AppColors.primaryLight),
                      SizedBox(width: 6),
                      Text(
                        'Align receipt edges inside the frame',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Control Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 20, bottom: 36, left: 24, right: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Pick from Gallery
                  IconButton(
                    icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
                    tooltip: 'Upload from Gallery',
                    onPressed: _isProcessing ? null : _pickFromGallery,
                  ),

                  // Shutter Capture Button
                  GestureDetector(
                    onTap: _isProcessing ? null : _captureReceipt,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryLight, AppColors.accent],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryLight.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),

                  // Preset Demo Receipts for Instant Desktop/Test verification
                  IconButton(
                    icon: const Icon(Icons.receipt_rounded, color: AppColors.primaryLight, size: 28),
                    tooltip: 'Try Sample Receipts',
                    onPressed: _isProcessing ? null : _showSampleReceiptsPicker,
                  ),
                ],
              ),
            ),
          ),

          // Processing Progress Overlay HUD
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _processingStatus,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'On-device AI extraction (offline)',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
