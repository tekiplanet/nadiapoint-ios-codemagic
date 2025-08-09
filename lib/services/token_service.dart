import 'package:dio/dio.dart';
import 'dart:convert';
import '../config/env/env_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenInfo {
  final String id;
  final String symbol;
  final String name;
  final String blockchain;
  final String? contractAddress;
  final int decimals;
  final bool isActive;
  final String baseSymbol;
  final String networkVersion;
  final double currentPrice;
  final double price24h;
  final double changePercent24h;
  final Map<String, dynamic> metadata;
  final String? icon;

  TokenInfo({
    required this.id,
    required this.symbol,
    required this.name,
    required this.blockchain,
    this.contractAddress,
    required this.decimals,
    required this.isActive,
    required this.baseSymbol,
    required this.networkVersion,
    required this.currentPrice,
    required this.price24h,
    required this.changePercent24h,
    required this.metadata,
    this.icon,
  });

  factory TokenInfo.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] is String 
        ? jsonDecode(json['metadata']) 
        : (json['metadata'] ?? {});
    
    return TokenInfo(
      id: json['id'],
      symbol: json['symbol'],
      name: json['name'],
      blockchain: json['blockchain'],
      contractAddress: json['contractAddress'],
      decimals: json['decimals'],
      isActive: json['isActive'] ?? true,
      baseSymbol: json['baseSymbol'] ?? json['symbol'],
      networkVersion: json['networkVersion'] ?? 'NATIVE',
      currentPrice: double.tryParse(json['currentPrice']?.toString() ?? '0') ?? 0,
      price24h: double.tryParse(json['price24h']?.toString() ?? '0') ?? 0,
      changePercent24h: double.tryParse(json['changePercent24h']?.toString() ?? '0') ?? 0,
      metadata: metadata,
      icon: metadata['icon'],
    );
  }
}

class UnifiedToken {
  final String baseSymbol;
  final String name;
  final String? icon;
  final double currentPrice;
  final double price24h;
  final double changePercent24h;
  final List<TokenInfo> variants;

  UnifiedToken({
    required this.baseSymbol,
    required this.name,
    this.icon,
    required this.currentPrice,
    required this.price24h,
    required this.changePercent24h,
    required this.variants,
  });

  // Get primary token from all variants (usually first one)
  TokenInfo get primaryToken => variants.first;
}

class TokenService {
  late final Dio _dio;
  final storage = const FlutterSecureStorage();

  TokenService({Dio? dio}) {
    final baseUrl = EnvConfig.apiUrl;
    
    _dio = dio ?? Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'accessToken');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          print('Error Response: ${error.response?.data}');
          print('Error Status Code: ${error.response?.statusCode}');
          return handler.next(error);
        },
      ),
    );
  }

  Future<List<UnifiedToken>> getMarketTokens() async {
    try {
      final response = await _dio.get('/tokens/market');
      
      if (response.statusCode == 200) {
        final List<dynamic> tokensJson = response.data['tokens'];
        final List<TokenInfo> tokens = tokensJson
            .map((tokenJson) => TokenInfo.fromJson(tokenJson))
            .toList();

        // Group tokens by baseSymbol
        final Map<String, List<TokenInfo>> tokenGroups = {};
        for (var token in tokens) {
          final key = token.baseSymbol;
          if (!tokenGroups.containsKey(key)) {
            tokenGroups[key] = [];
          }
          tokenGroups[key]!.add(token);
        }

        // Create unified tokens
        final List<UnifiedToken> unifiedTokens = tokenGroups.entries.map((entry) {
          final variants = entry.value;
          final primaryToken = variants.first;

          return UnifiedToken(
            baseSymbol: entry.key,
            name: primaryToken.name.split(' (').first, // Remove network info from name
            icon: primaryToken.icon,
            currentPrice: primaryToken.currentPrice,
            price24h: primaryToken.price24h,
            changePercent24h: primaryToken.changePercent24h,
            variants: variants,
          );
        }).toList();

        // Sort by market cap or volume if available, otherwise alphabetically
        unifiedTokens.sort((a, b) => a.baseSymbol.compareTo(b.baseSymbol));
        
        return unifiedTokens;
      } else {
        throw Exception('Failed to load tokens: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching market tokens');
      throw Exception('Failed to load tokens');
    }
  }

  // Fallback method if no API endpoint exists yet - use tokens table directly
  Future<List<UnifiedToken>> getAllTokens() async {
    try {
      final response = await _dio.get('/admin/deposits/tokens');
      
      if (response.statusCode == 200) {
        final List<dynamic> tokensJson = response.data['data'];
        final List<TokenInfo> tokens = tokensJson
            .map((tokenJson) => TokenInfo.fromJson(tokenJson))
            .toList();

        // Group tokens by baseSymbol
        final Map<String, List<TokenInfo>> tokenGroups = {};
        for (var token in tokens) {
          if (!token.isActive) continue; // Skip inactive tokens
          
          final key = token.baseSymbol;
          if (!tokenGroups.containsKey(key)) {
            tokenGroups[key] = [];
          }
          tokenGroups[key]!.add(token);
        }

        // Create unified tokens
        final List<UnifiedToken> unifiedTokens = tokenGroups.entries.map((entry) {
          final variants = entry.value;
          final primaryToken = variants.first;

          return UnifiedToken(
            baseSymbol: entry.key,
            name: primaryToken.name.split(' (').first, // Remove network info from name
            icon: primaryToken.icon,
            currentPrice: primaryToken.currentPrice,
            price24h: primaryToken.price24h,
            changePercent24h: primaryToken.changePercent24h,
            variants: variants,
          );
        }).toList();

        // Sort by market cap or volume if available, otherwise alphabetically
        unifiedTokens.sort((a, b) => a.baseSymbol.compareTo(b.baseSymbol));
        
        return unifiedTokens;
      } else {
        throw Exception('Failed to load tokens: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tokens');
      throw Exception('Failed to load tokens');
    }
  }
} 