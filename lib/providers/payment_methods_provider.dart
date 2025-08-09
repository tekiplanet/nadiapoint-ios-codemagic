import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/payment_methods_service.dart';
import '../models/payment_method.dart';
import '../models/payment_method_type.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:io';
import '../widgets/two_factor_dialog.dart';

class PaymentMethodsProvider with ChangeNotifier {
  final PaymentMethodsService _service;
  List<PaymentMethod> _paymentMethods = [];
  List<PaymentMethodType> _paymentMethodTypes = [];
  bool _isLoading = false;
  String? _error;
  BuildContext? _context;

  PaymentMethodsProvider(this._service);

  void setContext(BuildContext context) {
    _context = context;
  }

  List<PaymentMethod> get paymentMethods => _paymentMethods;
  List<PaymentMethodType> get paymentMethodTypes => _paymentMethodTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPaymentMethodTypes() async {
    try {
      _isLoading = true;
      notifyListeners();

      _paymentMethodTypes = await _service.getPaymentMethodTypes(_context!);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPaymentMethods() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_context == null) {
        throw 'Context not set';
      }

      if (_context!.mounted) {
        _paymentMethods = await _service.getPaymentMethods(_context!);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();

      if (e.toString().contains('Session expired') && _context != null && _context!.mounted) {
        await Provider.of<AuthProvider>(_context!, listen: false)
            .handleUnauthorized(_context!);
      }
      rethrow;
    }
  }

  Future<void> createPaymentMethod(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_context == null || !_context!.mounted) {
        throw 'Context not set or widget disposed';
      }

      // Check if user has 2FA enabled
      final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
      String? twoFactorCode;
      
      if (authProvider.user?.twoFactorEnabled == true) {
        if (_context!.mounted) {
          final verified = await showDialog<bool>(
            context: _context!,
            barrierDismissible: false,
            builder: (context) => const TwoFactorDialog(
              action: 'createPaymentMethod',
              title: 'Verify 2FA',
              message: 'Enter the 6-digit code to add payment method',
            ),
          );
          
          if (verified != true) {
            throw 'Two-factor authentication required';
          }
          
          twoFactorCode = authProvider.getLastVerificationToken();
        }
      }

      await _service.createPaymentMethod(
        data,
        _context!,
        twoFactorCode: twoFactorCode,
      );
      
      if (_context!.mounted) {
        await loadPaymentMethods();
      }

      if (_context!.mounted) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (_context?.mounted ?? false) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> updatePaymentMethod(String id, Map<String, dynamic> data) async {
    try {
      if (_context == null || !_context!.mounted) {
        throw 'Context not set or widget disposed';
      }

      final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
      String? twoFactorCode;
      
      if (authProvider.user?.twoFactorEnabled == true) {
        if (_context!.mounted) {
          final verified = await showDialog<bool>(
            context: _context!,
            barrierDismissible: false,
            builder: (context) => const TwoFactorDialog(
              action: 'updatePaymentMethod',
              title: 'Verify 2FA',
              message: 'Enter the 6-digit code to update payment method',
            ),
          );
          
          if (verified != true) {
            throw 'Two-factor authentication required';
          }
          
          twoFactorCode = authProvider.getLastVerificationToken();
        }
      }

      await _service.updatePaymentMethod(
        id, 
        data, 
        _context!,
        twoFactorCode: twoFactorCode,
      );
      
      if (_context!.mounted) {
        await loadPaymentMethods();
      }
    } catch (e) {
      print('Provider error updating payment method');
      rethrow;
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    try {
      if (_context == null || !_context!.mounted) {
        throw 'Context not set or widget disposed';
      }

      final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
      String? twoFactorCode;
      
      if (authProvider.user?.twoFactorEnabled == true) {
        if (_context!.mounted) {
          final verified = await showDialog<bool>(
            context: _context!,
            barrierDismissible: false,
            builder: (context) => const TwoFactorDialog(
              action: 'deletePaymentMethod',
              title: 'Verify 2FA',
              message: 'Enter the 6-digit code to delete payment method',
            ),
          );
          
          if (verified != true) {
            throw 'Two-factor authentication required';
          }
          
          twoFactorCode = authProvider.getLastVerificationToken();
        }
      }

      await _service.deletePaymentMethod(
        id, 
        _context!,
        twoFactorCode: twoFactorCode,
      );
      
      if (_context!.mounted) {
        _paymentMethods.removeWhere((method) => method.id == id);
        notifyListeners();
        
        await loadPaymentMethods();
      }
    } catch (e) {
      if (_context?.mounted ?? false) {
        await loadPaymentMethods();
      }
      rethrow;
    }
  }

  Future<String> getImageUrl(String filename) async {
    try {
      if (_context == null) {
        throw 'Context not set';
      }

      final response = await _service.getImageUrl(filename, _context!);
      return response;
    } catch (e) {
      if (e.toString().contains('Session expired') && _context != null && _context!.mounted) {
        await Provider.of<AuthProvider>(_context!, listen: false)
            .handleUnauthorized(_context!);
      }
      rethrow;
    }
  }
} 