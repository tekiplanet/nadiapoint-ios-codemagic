import 'package:flutter/material.dart';
import '../models/kyc_details.dart';
import '../models/kyc_level.dart';
import '../services/kyc_service.dart';
import 'package:flutter_idensic_mobile_sdk_plugin/flutter_idensic_mobile_sdk_plugin.dart';

class KYCProvider extends ChangeNotifier {
  final KYCService _kycService;
  KYCDetails? _kycDetails;
  List<KYCLevel>? _kycLevels;
  bool _loading = false;
  String? _error;

  KYCProvider(this._kycService);

  KYCDetails? get kycDetails => _kycDetails;
  List<KYCLevel>? get kycLevels => _kycLevels;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadKYCDetails() async {
    try {
      _loading = true;
      notifyListeners();
      
      _kycDetails = await _kycService.getUserKYCDetails();
      _loading = false;
      notifyListeners();
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadKYCLevels() async {
    try {
      _loading = true;
      notifyListeners();
      
      _kycLevels = await _kycService.getAllKYCLevels();
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> startVerification() async {
    _loading = true;
    notifyListeners();

    try {
      await _kycService.startDocumentVerification();
      await loadKYCDetails();
    } catch (e) {
      print('Error starting verification');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> retryVerification(String type) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      if (type == 'identity') {
        await _kycService.startDocumentVerification();
      } else if (type == 'address') {
        await _kycService.startAddressVerification();
      }

      await loadKYCDetails();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> submitIdentityDetails({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String address,
    required String city,
    required String state,
    required String country,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _kycService.submitIdentityDetails(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        address: address,
        city: city,
        state: state,
        country: country,
      );

      await loadKYCDetails();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, String>> startDocumentVerification() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final result = await _kycService.startDocumentVerification();
      
      await loadKYCDetails();
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> startAddressVerification() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _kycService.startAddressVerification();
      await loadKYCDetails();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> startAdvancedVerification() async {
    try {
      _loading = true;
      notifyListeners();

      final token = await _kycService.startAdvancedVerification();
      return token;
    } catch (e) {
      print('Error in advanced verification');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
} 