import 'package:flutter/foundation.dart';
import '../services/p2p_settings_service.dart';

class AutoResponseProvider with ChangeNotifier {
  final P2PSettingsService _service;
  List<Map<String, dynamic>> _responses = [];
  bool _isLoading = false;
  String? _error;

  AutoResponseProvider(this._service);

  List<Map<String, dynamic>> get responses => _responses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadResponses() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _responses = await _service.getAutoResponses();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateResponses(List<Map<String, dynamic>> responses) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final cleanedResponses = responses.map((response) => {
        'id': response['id'],
        'message': response['message'],
        'type': response['type'],
      }).toList();

      await _service.updateAutoResponses(cleanedResponses);
      _responses = responses;
    } catch (e) {
      print('Error updating responses');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addResponse(Map<String, dynamic> response) async {
    final cleanedResponse = {
      'id': response['id'],
      'message': response['message'],
      'type': response['type'],
    };
    final newResponses = [..._responses, cleanedResponse];
    await updateResponses(newResponses);
  }

  Future<void> updateResponse(String id, Map<String, dynamic> updatedResponse) async {
    final cleanedResponse = {
      'id': updatedResponse['id'],
      'message': updatedResponse['message'],
      'type': updatedResponse['type'],
    };
    final index = _responses.indexWhere((r) => r['id'] == id);
    if (index != -1) {
      final newResponses = List<Map<String, dynamic>>.from(_responses);
      newResponses[index] = cleanedResponse;
      await updateResponses(newResponses);
    }
  }

  Future<void> deleteResponse(String id) async {
    final newResponses = _responses.where((r) => r['id'] != id).toList();
    await updateResponses(newResponses);
  }
} 