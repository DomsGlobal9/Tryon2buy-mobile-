import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_exporter.dart';
import '../../data/models/scanned_garment.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../domain/tag_reference.dart';
import '../widgets/color_variant_sheet.dart';

/// Screen displayed after scanning an in-store garment swing tag.
///
/// Direct parity with the React frontend's `ClientTryon.jsx`.
class ClientTryonScreen extends StatefulWidget {
  final TagReference tag;

  const ClientTryonScreen({
    super.key,
    required this.tag,
  });

  @override
  State<ClientTryonScreen> createState() => _ClientTryonScreenState();
}

class _ClientTryonScreenState extends State<ClientTryonScreen> {
  final InventoryRepository _inventoryRepo = InventoryRepository();
  final ImagePicker _picker = ImagePicker();

  bool _isLoadingGarment = true;
  String? _garmentError;
  ScannedGarment? _garment;
  String? _chosenVariantCode;
  String? _currentGarmentImageUrl;

  File? _selfieFile;
  String? _uploadedSelfieUrl;

  bool _isGenerating = false;
  double _generationProgress = 0.0;
  Timer? _progressTimer;

  String? _resultImageUrl;
  String? _generationError;

  @override
  void initState() {
    super.initState();
    _chosenVariantCode = widget.tag.variant;
    _fetchGarmentDetails();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchGarmentDetails() async {
    setState(() {
      _isLoadingGarment = true;
      _garmentError = null;
    });

    final res = await _inventoryRepo.fetchGarment(
      clientId: widget.tag.clientId,
      productCode: widget.tag.productCode,
      variant: _chosenVariantCode,
    );

    if (!mounted) return;

    if (res.success && res.data != null) {
      final g = res.data!;
      setState(() {
        _garment = g;
        _chosenVariantCode = g.variantCode ?? _chosenVariantCode;
        _currentGarmentImageUrl = g.imageUrl;
        _isLoadingGarment = false;
      });

      // Parity with frontend: if product has multiple colour variants and none
      // was pre-selected on the physical tag, promptly ask which colour the shopper holds.
      if (widget.tag.variant == null && g.colours.length > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _promptColorVariantSelection();
        });
      }
    } else {
      setState(() {
        _garmentError = res.error ?? 'Garment not found.';
        _isLoadingGarment = false;
      });
    }
  }

  Future<void> _promptColorVariantSelection() async {
    if (_garment == null || _garment!.colours.isEmpty) return;

    final chosen = await ColorVariantSheet.show(
      context,
      colours: _garment!.colours,
      initialCode: _chosenVariantCode,
      garmentTitle: _garment!.title,
    );

    if (chosen != null && mounted) {
      setState(() {
        _chosenVariantCode = chosen.code;
        if (chosen.imageUrl != null && chosen.imageUrl!.isNotEmpty) {
          _currentGarmentImageUrl = chosen.imageUrl;
        }
      });
    }
  }

  Future<void> _pickSelfie(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 2400,
      );

      if (picked != null && mounted) {
        setState(() {
          _selfieFile = File(picked.path);
          _uploadedSelfieUrl = null;
          _resultImageUrl = null;
          _generationError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadSelfieFile(File file) async {
    final uri = Uri.parse(ApiEndpoints.uploadImage).replace(
      queryParameters: {'folder': ApiEndpoints.folderUserUploads},
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(await ApiClient.headers(isMultipart: true))
      ..files.add(await ApiClient.multipartFile(file));

    final streamed = await ApiClient.client
        .send(request)
        .timeout(ApiClient.timeoutDuration);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['url'] as String?;
    }
    return null;
  }

  void _startGeneration() async {
    if (_selfieFile == null && _uploadedSelfieUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take or choose a photo first.')),
      );
      return;
    }

    final garmentUrl = _currentGarmentImageUrl ?? _garment?.imageUrl;
    if (garmentUrl == null || garmentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Garment photo is missing.')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationProgress = 0.05;
      _generationError = null;
    });

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_generationProgress < 0.90) {
          _generationProgress += 0.04;
        }
      });
    });

    try {
      // 1. Upload photo if not already uploaded
      var humanUrl = _uploadedSelfieUrl;
      if (humanUrl == null && _selfieFile != null) {
        humanUrl = await _uploadSelfieFile(_selfieFile!);
        _uploadedSelfieUrl = humanUrl;
      }

      if (humanUrl == null || humanUrl.isEmpty) {
        throw Exception('Failed to upload photo. Please check your connection.');
      }

      // 2. Call Scaleezy Inventory generate endpoint
      final genRes = await _inventoryRepo.generateTryon(
        clientId: widget.tag.clientId,
        productCode: widget.tag.productCode,
        humanImageUrl: humanUrl,
        garmentImageUrl: garmentUrl,
        category: _garment?.category,
        variant: _chosenVariantCode,
      );

      _progressTimer?.cancel();

      if (!mounted) return;

      if (genRes.success && genRes.data != null) {
        setState(() {
          _generationProgress = 1.0;
          _resultImageUrl = genRes.data;
          _isGenerating = false;
        });
      } else {
        setState(() {
          _generationError = genRes.error ?? 'Generation could not be completed.';
          _isGenerating = false;
        });
      }
    } catch (e) {
      _progressTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _generationError = ApiClient.friendlyError(e);
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _garment?.title ?? 'Tag Try-On',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_garment != null && _garment!.colours.length > 1)
            TextButton.icon(
              onPressed: _promptColorVariantSelection,
              icon: const Icon(Icons.palette_outlined, size: 18, color: AppColors.brandOrange),
              label: Text(
                _chosenVariantCode ?? 'Colour',
                style: const TextStyle(
                  color: AppColors.brandOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingGarment) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.brandOrange),
            SizedBox(height: 16),
            Text(
              'Looking up garment tag...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_garmentError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _garmentError!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchGarmentDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // If result is generated, show the result view
    if (_resultImageUrl != null) {
      return _buildResultView();
    }

    // Default: Show Garment Info & Selfie Picker
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Garment Card
          _buildGarmentHeaderCard(),
          const SizedBox(height: 20),

          // Selfie Selection Card
          _buildSelfiePickerCard(),
          const SizedBox(height: 24),

          // Error banner if any
          if (_generationError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _generationError!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Generate CTA Button
          ElevatedButton(
            onPressed: _isGenerating ? null : _startGeneration,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isGenerating
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Generating virtual try-on... (${(_generationProgress * 100).toInt()}%)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _generationProgress,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.brandOrange,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.brandOrange, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Try On This Garment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGarmentHeaderCard() {
    final g = _garment!;
    final imgUrl = _currentGarmentImageUrl ?? g.imageUrl;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.creamBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Garment thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 90,
              height: 120,
              color: AppColors.backgroundLight,
              child: imgUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imgUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.checkroom,
                        color: AppColors.textMuted,
                        size: 32,
                      ),
                    )
                  : const Icon(
                      Icons.checkroom,
                      color: AppColors.textMuted,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Garment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (g.category != null && g.category!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandOrangeLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      g.category!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandOrange,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                Text(
                  g.displayTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tag Code: ${widget.tag.productCode}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                if (g.colours.length > 1) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _promptColorVariantSelection,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.palette_outlined, size: 14, color: AppColors.brandOrange),
                          const SizedBox(width: 6),
                          Text(
                            _chosenVariantCode != null
                                ? 'Colour: $_chosenVariantCode'
                                : 'Select colour (${g.colours.length} available)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfiePickerCard() {
    final hasPhoto = _selfieFile != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.creamBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_outlined, color: AppColors.brandOrange, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Step 2: Add Your Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (hasPhoto)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selfieFile = null;
                      _uploadedSelfieUrl = null;
                    });
                  },
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (hasPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _selfieFile!,
                height: 240,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: AppColors.brandOrange,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Take a selfie or pick from your gallery',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Stand facing the camera for best draping accuracy',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickSelfie(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _pickSelfie(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 16),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Generated Result Card
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CachedNetworkImage(
                imageUrl: _resultImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  height: 380,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.brandOrange),
                  ),
                ),
                errorWidget: (context, url, error) => const SizedBox(
                  height: 380,
                  child: Center(
                    child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Garment Title & Status
          Text(
            _garment?.displayTitle ?? 'Virtual Try-On',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Primary Actions: Save Image & Share
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => MediaExporter.saveToGallery(context, _resultImageUrl!),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Save to Photos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => MediaExporter.share(context, _resultImageUrl!),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share Look'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Secondary Action: Try Another Look
          TextButton(
            onPressed: () {
              setState(() {
                _resultImageUrl = null;
              });
            },
            child: const Text(
              'Try with another photo or colour',
              style: TextStyle(
                color: AppColors.brandOrange,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
