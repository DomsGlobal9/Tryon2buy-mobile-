import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../network/api_client.dart';

/// Reusable utility for saving and sharing try-on images natively.
class MediaExporter {
  const MediaExporter._();

  /// Saves a remote image URL to the user's native photo gallery / album.
  static Future<bool> saveToGallery(
    BuildContext context,
    String imageUrl, {
    String albumName = 'TryOn2Buy',
  }) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo gallery permission is required to save photos.'),
              ),
            );
          }
          return false;
        }
      }

      // Download image bytes
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(ApiClient.timeoutDuration);

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw const HttpException('Failed to download image data.');
      }

      // Write to temp file for Gal
      final tempDir = await getTemporaryDirectory();
      final fileName = 'tryon_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Save to gallery
      await Gal.putImage(tempFile.path, album: albumName);

      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to your Photos! 🎉'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save image: ${ApiClient.friendlyError(e)}'),
          ),
        );
      }
      return false;
    }
  }

  /// Downloads the remote image to a temporary file and opens the native OS share sheet.
  static Future<bool> share(
    BuildContext context,
    String imageUrl, {
    String? subject,
    String? text,
  }) async {
    try {
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(ApiClient.timeoutDuration);

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw const HttpException('Failed to download image data.');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'tryon_share_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(response.bodyBytes);

      final shareText = text ?? 'Check out my virtual try-on with TryOn2Buy!';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          text: shareText,
          subject: subject,
        ),
      );

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share image: ${ApiClient.friendlyError(e)}'),
          ),
        );
      }
      return false;
    }
  }
}
