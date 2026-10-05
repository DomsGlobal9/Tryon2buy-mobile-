import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/tag_reference.dart';
import 'client_tryon_screen.dart';

/// Fullscreen camera QR code scanner for physical garment swing tags.
///
/// Automatically scans codes such as `https://tryon2buy.com/try/shop123/prod456?variant=red`
/// or scheme-less/relative links, matching the web frontend's physical tag flow.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;

      final tag = TagReference.parse(raw);
      if (tag != null) {
        _isProcessing = true;
        _controller.stop();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ClientTryonScreen(tag: tag),
          ),
        );
        return;
      }
    }
  }

  void _showManualInputDialog() {
    final clientController = TextEditingController();
    final productController = TextEditingController();
    final variantController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Enter Tag Code',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the details printed on the swing tag or product label:',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: clientController,
                decoration: InputDecoration(
                  labelText: 'Shop / Client ID',
                  hintText: 'e.g. CLI-890',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: productController,
                decoration: InputDecoration(
                  labelText: 'Product Code',
                  hintText: 'e.g. SAR-001',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: variantController,
                decoration: InputDecoration(
                  labelText: 'Colour / Variant (Optional)',
                  hintText: 'e.g. RED',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final c = clientController.text.trim();
              final p = productController.text.trim();
              final v = variantController.text.trim();

              if (c.isEmpty || p.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter both Shop ID and Product Code.')),
                );
                return;
              }

              Navigator.of(dialogCtx).pop();
              _controller.stop();

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ClientTryonScreen(
                    tag: TagReference(
                      clientId: c,
                      productCode: p,
                      variant: v.isNotEmpty ? v : null,
                    ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Scan Garment Tag',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Torch toggle
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
          // Camera switch
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner Camera Preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Viewfinder Overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.brandOrange,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // Bottom instruction and manual entry pill
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Point camera at the QR code on the garment tag',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _showManualInputDialog,
                  icon: const Icon(Icons.keyboard_outlined, color: Colors.white70, size: 18),
                  label: const Text(
                    'Enter code manually',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
