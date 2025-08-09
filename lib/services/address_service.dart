import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recent_address.dart';

class AddressService {
  static const String _recentKey = 'recent_addresses';
  static const String _whitelistKey = 'whitelist_addresses';
  final SharedPreferences _prefs;

  AddressService(this._prefs);

  // Get recent addresses
  List<RecentAddress> getRecentAddresses() {
    final String? data = _prefs.getString(_recentKey);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((json) => RecentAddress.fromJson(json)).toList();
  }

  // Add recent address
  Future<void> addRecentAddress(RecentAddress address) async {
    final addresses = getRecentAddresses();
    
    // Remove if already exists
    addresses.removeWhere((a) => a.address == address.address);
    
    // Add to beginning of list
    addresses.insert(0, address);
    
    // Keep only last 5 addresses
    if (addresses.length > 5) {
      addresses.removeLast();
    }

    await _prefs.setString(_recentKey, json.encode(addresses.map((a) => a.toJson()).toList()));
  }

  // Get whitelisted addresses
  List<RecentAddress> getWhitelistedAddresses() {
    final String? data = _prefs.getString(_whitelistKey);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((json) => RecentAddress.fromJson(json)).toList();
  }

  // Add to whitelist
  Future<void> addToWhitelist(RecentAddress address) async {
    final addresses = getWhitelistedAddresses();
    
    // Don't add if already exists
    if (addresses.any((a) => a.address == address.address)) {
      return;
    }

    addresses.add(address);
    await _prefs.setString(_whitelistKey, json.encode(addresses.map((a) => a.toJson()).toList()));
  }

  // Remove from whitelist
  Future<void> removeFromWhitelist(String address) async {
    final addresses = getWhitelistedAddresses();
    addresses.removeWhere((a) => a.address == address);
    await _prefs.setString(_whitelistKey, json.encode(addresses.map((a) => a.toJson()).toList()));
  }

  // Verify if address is whitelisted
  bool isWhitelisted(String address) {
    return getWhitelistedAddresses().any((a) => a.address == address);
  }
} 