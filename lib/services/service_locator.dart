import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './services.dart';
import '../providers/auth_provider.dart';
import 'api_client.dart';
import 'wallet_service.dart';
import 'auth_service.dart';
import './p2p_service.dart';
import './home_service.dart';
import 'fiat_wallet_service.dart';
import 'internal_transfer_service.dart';

final getIt = GetIt.instance;

Future<void> setupServices() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<AddressService>(AddressService(prefs));

  // Register Dio
  final dio = Dio();
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
  ));

  // Register Dio with GetIt
  getIt.registerSingleton<Dio>(dio);

  // Register AuthProvider
  getIt.registerSingleton<AuthProvider>(AuthProvider());

  // Register AuthService
  getIt.registerSingleton<AuthService>(AuthService());

  // Register ApiClient with auth interceptor
  getIt.registerSingleton<ApiClient>(
    ApiClient(dio, getIt<AuthProvider>()),
  );

  // Use the ApiClient's dio instance for all services
  getIt.registerSingleton<KYCService>(
    KYCService(getIt<ApiClient>().dio),
  );

  // Register P2PSettingsService
  getIt.registerSingleton<P2PSettingsService>(P2PSettingsService());

  // Register ExchangeService
  getIt.registerSingleton<ExchangeService>(ExchangeService());

  // Register WalletService
  getIt.registerLazySingleton<WalletService>(() => WalletService());

  // Register P2PService
  getIt.registerSingleton<P2PService>(P2PService());

  // Register HomeService
  getIt.registerSingleton<HomeService>(HomeService());

  // Register FiatWalletService
  getIt.registerSingleton<FiatWalletService>(FiatWalletService());

  // Register InternalTransferService
  getIt.registerSingleton<InternalTransferService>(InternalTransferService());
}
