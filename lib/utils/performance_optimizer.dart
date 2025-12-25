import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Performance optimization utilities for images and ML processing
class PerformanceOptimizer {
  /// Maximum image dimensions for ML processing
  static const int maxImageWidth = 640;
  static const int maxImageHeight = 640;
  
  /// Image quality for compression (0-100)
  static const int imageQuality = 85;
  
  /// Resize and compress image for ML processing
  /// Returns optimized image path
  static Future<String?> optimizeImageForML(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;
      
      // Read image
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;
      
      // Calculate resize dimensions
      final width = image.width;
      final height = image.height;
      
      int newWidth = width;
      int newHeight = height;
      
      if (width > maxImageWidth || height > maxImageHeight) {
        final ratio = (width / height).clamp(0.5, 2.0);
        
        if (width > height) {
          newWidth = maxImageWidth;
          newHeight = (maxImageWidth / ratio).round();
        } else {
          newHeight = maxImageHeight;
          newWidth = (maxImageHeight * ratio).round();
        }
      }
      
      // Resize if needed
      img.Image? resizedImage = image;
      if (newWidth != width || newHeight != height) {
        resizedImage = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }
      
      // Compress JPEG
      final optimizedBytes = img.encodeJpg(
        resizedImage,
        quality: imageQuality,
      );
      
      // Save optimized image
      final optimizedPath = '${imagePath}_optimized.jpg';
      final optimizedFile = File(optimizedPath);
      await optimizedFile.writeAsBytes(optimizedBytes);
      
      print('[PerformanceOptimizer] Optimized image: ${bytes.length} -> ${optimizedBytes.length} bytes');
      
      return optimizedPath;
    } catch (e) {
      print('[PerformanceOptimizer] Error optimizing image: $e');
      return imagePath; // Return original on error
    }
  }
  
  /// Process image in isolate for better performance
  static Future<String?> optimizeImageInIsolate(String imagePath) async {
    return await compute(_optimizeImageIsolate, imagePath);
  }
  
  /// Isolate function for image optimization
  static Future<String?> _optimizeImageIsolate(String imagePath) async {
    return await optimizeImageForML(imagePath);
  }
  
  /// Get image file size in MB
  static Future<double> getImageSizeMB(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final size = await file.length();
        return size / (1024 * 1024);
      }
    } catch (e) {
      print('[PerformanceOptimizer] Error getting image size: $e');
    }
    return 0.0;
  }
  
  /// Clear optimized images cache
  static Future<void> clearOptimizedCache(String basePath) async {
    try {
      final optimizedPath = '${basePath}_optimized.jpg';
      final file = File(optimizedPath);
      if (await file.exists()) {
        await file.delete();
        print('[PerformanceOptimizer] Cleared optimized cache: $optimizedPath');
      }
    } catch (e) {
      print('[PerformanceOptimizer] Error clearing cache: $e');
    }
  }
}

