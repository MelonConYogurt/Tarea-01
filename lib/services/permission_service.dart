import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      
      if (status == PermissionStatus.granted) {
        return true;
      } else if (status == PermissionStatus.permanentlyDenied) {
        await openAppSettings();
      }
      
      return false;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return false;
    }
  }

  Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await openAppSettings();
        return false;
      }

      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  Future<XFile?> takePicture() async {
    try {
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        return null;
      }

      return await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    }
  }

  Future<bool> requestGalleryPermission() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.storage,
      ].request();
      
      bool hasPermission = statuses.values.any((status) => status == PermissionStatus.granted);
      
      if (hasPermission) {
        return true;
      } else if (statuses.values.any((status) => status == PermissionStatus.permanentlyDenied)) {
        await openAppSettings();
      }
      
      return false;
    } catch (e) {
      debugPrint('Error requesting gallery permission: $e');
      return false;
    }
  }

  Future<XFile?> pickImageFromGallery() async {
    try {
      final hasPermission = await requestGalleryPermission();
      if (!hasPermission) {
        return null;
      }

      return await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status == PermissionStatus.granted;
  }

  Future<bool> hasGalleryPermission() async {
    final photoStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;
    return photoStatus == PermissionStatus.granted || storageStatus == PermissionStatus.granted;
  }

  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  Future<void> showPermissionDialog() async {
    await openAppSettings();
  }
}