import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../features/diabetes_prediction/models/diabetes_risk_prediction_model.dart';
import '../../../features/diabetes_prediction/models/meal_photo_record_model.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class DiabetesPredictionRepository extends GetxController {
  static DiabetesPredictionRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  /// Get diabetes predictions collection reference
  CollectionReference<Map<String, dynamic>> _getDiabetesPredictionsCollection(String userId) {
    return _db
        .collection(FirebaseCollectionNames.diabetesPredictions)
        .doc(userId)
        .collection('predictionResults');
  }

  /// Upload meal photos to Firebase Storage
  Future<List<String>> _uploadMealPhotos(List<File> mealPhotos) async {
    List<String> downloadUrls = [];

    for (File file in mealPhotos) {
      try {
        final filePath = file.path;
        final fileExtension = path.extension(filePath).toLowerCase();
        final fileName = const Uuid().v4();

        // Upload to diabetes_risk/images folder
        final imagePath = 'diabetes_risk/images/$fileName$fileExtension';
        final imageRef = _storage.ref().child(imagePath);
        final imageUpload = await imageRef.putFile(file);
        final imageUrl = await imageUpload.ref.getDownloadURL();

        downloadUrls.add(imageUrl);

        print('✅ Meal photo uploaded successfully: $imagePath');
      } catch (e) {
        print('❌ Failed to upload meal photo: $e');
        // Continue with other files even if one fails
      }
    }

    return downloadUrls;
  }

  /// Helper method to delete meal photos from storage
  Future<void> _deleteMealPhotos(List<String> photoUrls) async {
    try {
      for (String photoUrl in photoUrls) {
        try {
          final ref = _storage.refFromURL(photoUrl);
          await ref.delete();
          print('✅ Deleted meal photo: $photoUrl');
        } catch (e) {
          print('❌ Failed to delete meal photo: $photoUrl, error: $e');
        }
      }
    } catch (e) {
      print('❌ Error in _deleteMealPhotos: $e');
    }
  }

  /// Extract filename from Firebase Storage URL
  String? _extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      final oIndex = pathSegments.indexOf('o');
      if (oIndex != -1 && oIndex + 1 < pathSegments.length) {
        final encodedPath = pathSegments[oIndex + 1];
        final decodedPath = Uri.decodeComponent(encodedPath);
        return path.basename(decodedPath);
      }

      return null;
    } catch (e) {
      print('❌ Error extracting filename: $e');
      return null;
    }
  }

  /// Get diabetes predictions stream for a user within date range
  Stream<List<DiabetesRiskPredictionModel>> getDiabetesPredictionsStream(
      String userId,
      DateTime startDate,
      DateTime endDate,
      ) {
    try {
      return _getDiabetesPredictionsCollection(userId)
          .where(
        FirebaseFieldNames.predictionDateTime,
        isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
      )
          .where(
        FirebaseFieldNames.predictionDateTime,
        isLessThanOrEqualTo: endDate.millisecondsSinceEpoch,
      )
          .orderBy(FirebaseFieldNames.predictionDateTime, descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => DiabetesRiskPredictionModel.fromJson(doc.data()))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error fetching diabetes predictions: ${e.toString()}';
    }
  }

  /// Get single diabetes prediction by ID
  Future<DiabetesRiskPredictionModel?> getDiabetesPrediction(
      String userId,
      String predictionId,
      ) async {
    try {
      final doc = await _getDiabetesPredictionsCollection(userId)
          .doc(predictionId)
          .get();

      if (doc.exists && doc.data() != null) {
        return DiabetesRiskPredictionModel.fromJson(doc.data()!);
      }
      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error fetching diabetes prediction: ${e.toString()}';
    }
  }

  /// Save diabetes prediction with meal photos
  Future<void> saveDiabetesPrediction(
      String userId,
      DiabetesRiskPredictionModel prediction, {
        List<File>? newMealPhotos,
      }) async {
    try {
      // Generate UUID for prediction if not provided
      final String predictionId = prediction.predictionId.isEmpty
          ? const Uuid().v4()
          : prediction.predictionId;

      print('🔄 Saving diabetes prediction: $predictionId');

      // Upload new meal photos if any
      List<String> newMealPhotoUrls = [];
      if (newMealPhotos != null && newMealPhotos.isNotEmpty) {
        print('📤 Uploading ${newMealPhotos.length} meal photos...');
        newMealPhotoUrls = await _uploadMealPhotos(newMealPhotos);
        print('✅ Meal photos uploaded: ${newMealPhotoUrls.length} files');
      }

      // Update prediction with new photo URLs if needed
      final predictionToSave = newMealPhotoUrls.isNotEmpty
          ? _updatePredictionWithPhotoUrls(prediction, newMealPhotoUrls)
          : prediction;

      // Ensure the prediction has the correct ID
      final finalPrediction = predictionToSave.copyWith(predictionId: predictionId);

      await _getDiabetesPredictionsCollection(userId)
          .doc(predictionId)
          .set(finalPrediction.toJson());

      print('✅ Diabetes prediction saved successfully');
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error saving diabetes prediction: ${e.toString()}';
    }
  }

  /// Update prediction with new photo URLs
  DiabetesRiskPredictionModel _updatePredictionWithPhotoUrls(
      DiabetesRiskPredictionModel prediction,
      List<String> newPhotoUrls,
      ) {
    final existingPhotos = prediction.inputs.mealPhotos ?? [];
    final updatedPhotos = <MealPhotoRecord>[];

    // 按顺序匹配：第一个照片用第一个URL，第二个用第二个URL...
    for (int i = 0; i < existingPhotos.length && i < newPhotoUrls.length; i++) {
      final existingPhoto = existingPhotos[i];
      final newUrl = newPhotoUrls[i];

      updatedPhotos.add(existingPhoto.copyWith(imagePath: newUrl));
      print('✅ Replaced photo ${i+1}: ${existingPhoto.imagePath} -> $newUrl');
    }

    final updatedInputs = prediction.inputs.copyWith(
      mealPhotos: updatedPhotos,
    );

    return prediction.copyWith(inputs: updatedInputs);
  }

  /// Delete diabetes prediction and associated meal photos
  Future<void> deleteDiabetesPrediction(
      String userId,
      String predictionId,
      ) async {
    try {
      print('🗑️ Deleting diabetes prediction: $predictionId');

      // Get prediction to retrieve meal photo URLs
      final prediction = await getDiabetesPrediction(userId, predictionId);
      if (prediction != null) {
        // Extract all meal photo URLs
        final mealPhotoUrls = prediction.inputs.mealPhotos
            ?.map((photo) => photo.imagePath)
            .where((url) => url.isNotEmpty)
            .toList() ??
            [];

        if (mealPhotoUrls.isNotEmpty) {
          print('🗑️ Deleting ${mealPhotoUrls.length} meal photos...');
          await _deleteMealPhotos(mealPhotoUrls);
          print('✅ Meal photos deleted');
        }
      }

      // Delete prediction document
      await _getDiabetesPredictionsCollection(userId)
          .doc(predictionId)
          .delete();

      print('✅ Diabetes prediction deleted successfully');
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error deleting diabetes prediction: ${e.toString()}';
    }
  }

  /// Get latest diabetes prediction
  Future<DiabetesRiskPredictionModel?> getLatestPrediction(String userId) async {
    try {
      final snapshot = await _getDiabetesPredictionsCollection(userId)
          .orderBy(FirebaseFieldNames.predictionDateTime, descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return DiabetesRiskPredictionModel.fromJson(snapshot.docs.first.data());
      }
      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error fetching latest prediction: ${e.toString()}';
    }
  }

  /// Get predictions count for a date range
  Future<int> getPredictionsCount(
      String userId,
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final snapshot = await _getDiabetesPredictionsCollection(userId)
          .where(
        FirebaseFieldNames.predictionDateTime,
        isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
      )
          .where(
        FirebaseFieldNames.predictionDateTime,
        isLessThanOrEqualTo: endDate.millisecondsSinceEpoch,
      )
          .get();

      return snapshot.docs.length;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error fetching predictions count: ${e.toString()}';
    }
  }

  /// Get predictions by risk level
  Future<List<DiabetesRiskPredictionModel>> getPredictionsByRiskLevel(
      String userId,
      String riskLevel,
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final snapshot = await _getDiabetesPredictionsCollection(userId)
          .where(FirebaseFieldNames.riskLevel, isEqualTo: riskLevel)
          .where(
        FirebaseFieldNames.predictionDateTime,
        isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
      )
          .where(
        FirebaseFieldNames.predictionDateTime,
        isLessThanOrEqualTo: endDate.millisecondsSinceEpoch,
      )
          .orderBy(FirebaseFieldNames.predictionDateTime, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DiabetesRiskPredictionModel.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error fetching predictions by risk level: ${e.toString()}';
    }
  }

  /// Get user's diabetes prediction statistics
  Future<Map<String, dynamic>> getUserPredictionStats(String userId) async {
    try {
      final snapshot = await _getDiabetesPredictionsCollection(userId).get();

      int totalPredictions = snapshot.size;
      int lowRiskCount = 0;
      int mediumRiskCount = 0;
      int highRiskCount = 0;
      double averageRiskScore = 0.0;

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          final prediction = DiabetesRiskPredictionModel.fromJson(doc.data());
          switch (prediction.riskLevel) {
            case 'low':
              lowRiskCount++;
              break;
            case 'medium':
              mediumRiskCount++;
              break;
            case 'high':
              highRiskCount++;
              break;
          }
          averageRiskScore += prediction.riskScore;
        }
        averageRiskScore /= totalPredictions;
      }

      return {
        'totalPredictions': totalPredictions,
        'lowRiskCount': lowRiskCount,
        'mediumRiskCount': mediumRiskCount,
        'highRiskCount': highRiskCount,
        'averageRiskScore': averageRiskScore,
      };
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error fetching prediction stats: ${e.toString()}';
    }
  }

  /// Get predictions for dashboard (last 30 days)
  Stream<List<DiabetesRiskPredictionModel>> getDashboardPredictionsStream(
      String userId,
      ) {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

      return _getDiabetesPredictionsCollection(userId)
          .where(
        FirebaseFieldNames.predictionDateTime,
        isGreaterThanOrEqualTo: thirtyDaysAgo.millisecondsSinceEpoch,
      )
          .orderBy(FirebaseFieldNames.predictionDateTime, descending: true)
          .limit(50) // Limit for dashboard
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => DiabetesRiskPredictionModel.fromJson(doc.data()))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error fetching dashboard predictions: ${e.toString()}';
    }
  }
}