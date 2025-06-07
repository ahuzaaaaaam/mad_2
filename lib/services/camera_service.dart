import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraService {
  final ImagePicker _picker = ImagePicker();

  // Take a photo using the camera
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80,
      );
      
      if (photo != null) {
        // For web, we can't save to file system, so just return the XFile path
        if (kIsWeb) {
          return File(photo.path);
        }
        
        // Create a File object from the XFile
        final File file = File(photo.path);
        
        // Save to app documents directory for persistence
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(photo.path);
        final savedImage = await file.copy('${appDir.path}/$fileName');
        
        return savedImage;
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  // Pick an image from the gallery
  Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        // For web, we can't save to file system, so just return the XFile path
        if (kIsWeb) {
          return File(image.path);
        }
        
        // Create a File object from the XFile
        final File file = File(image.path);
        
        // Save to app documents directory for persistence
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(image.path);
        final savedImage = await file.copy('${appDir.path}/$fileName');
        
        return savedImage;
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Get all saved images
  Future<List<File>> getSavedImages() async {
    // For web, we can't access the file system, so return an empty list
    if (kIsWeb) {
      print('Running on web platform - file system access is limited');
      return [];
    }
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final files = Directory(appDir.path).listSync();
      
      // Filter for image files
      final imageFiles = files
          .whereType<File>()
          .where((file) {
            final extension = path.extension(file.path).toLowerCase();
            return extension == '.jpg' || extension == '.jpeg' || extension == '.png';
          })
          .toList();
      
      return imageFiles;
    } catch (e) {
      print('Error getting saved images: $e');
      return [];
    }
  }

  // Delete a saved image
  Future<bool> deleteImage(File image) async {
    // For web, we can't delete files, so just return true
    if (kIsWeb) {
      return true;
    }
    
    try {
      await image.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
} 