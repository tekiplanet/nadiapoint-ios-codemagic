class Coin {
  final String id;
  final String symbol;
  final String name;
  final List<Network> networks;
  final String? iconUrl;

  const Coin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.networks,
    this.iconUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'iconUrl': iconUrl,
      'networks': networks.map((n) => n.toJson()).toList(),
      'token': {
        'id': id,
        'symbol': symbol,
        'name': name,
        'metadata': {
          'icon': iconUrl,
          'networks': networks.map((n) => n.network).toList(),
        },
      },
    };
  }
}

class Network {
  final String name;
  final String blockchain;
  final String version;
  final String network;
  final String? arrivalTime;
  final bool isActive;
  final bool requiresMemo;
  final bool requiresTag;

  Network({
    required this.name,
    required this.blockchain,
    required this.version,
    required this.network,
    this.arrivalTime,
    this.isActive = true,
    this.requiresMemo = false,
    this.requiresTag = false,
  });

  factory Network.fromJson(Map<String, dynamic> json) {
    return Network(
      name: json['name'] ?? '',
      blockchain: json['blockchain'] ?? '',
      version: json['version'] ?? '',
      network: json['network'] ?? '',
      arrivalTime: json['arrivalTime'],
      requiresMemo: json['requiredFields']?['memo'] ?? false,
      requiresTag: json['requiredFields']?['tag'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'blockchain': blockchain,
      'version': version,
      'network': network,
      'arrivalTime': arrivalTime,
      'isActive': isActive,
      'requiresMemo': requiresMemo,
      'requiresTag': requiresTag,
    };
  }
}

// Demo coins list
final List<Coin> coins = [
  Coin(
    id: 'btc-native-mainnet',
    name: 'Bitcoin',
    symbol: 'BTC',
    iconUrl: 'bitcoin',
    networks: [
      Network(
        name: 'Bitcoin',
        blockchain: 'bitcoin',
        version: 'NATIVE',
        network: 'mainnet',
        arrivalTime: '~30 minutes',
      ),
      Network(
        name: 'Bitcoin Lightning',
        blockchain: 'bitcoin',
        version: 'LIGHTNING',
        network: 'mainnet',
        arrivalTime: '~1 minute',
        isActive: false
      ),
    ],
  ),
  Coin(
    id: 'eth-native-mainnet',
    name: 'Ethereum',
    symbol: 'ETH',
    iconUrl: 'ethereum',
    networks: [
      Network(
        name: 'Ethereum',
        blockchain: 'ethereum',
        version: 'NATIVE',
        network: 'mainnet',
        arrivalTime: '~5 minutes',
      ),
    ],
  ),
  Coin(
    id: 'usdt-multi-chain',
    name: 'Tether',
    symbol: 'USDT',
    iconUrl: 'tether',
    networks: [
      Network(
        name: 'Ethereum',
        blockchain: 'ethereum',
        version: 'ERC20',
        network: 'mainnet',
        arrivalTime: '~5 minutes',
      ),
      Network(
        name: 'TRON',
        blockchain: 'trx',
        version: 'TRC20',
        network: 'mainnet',
        arrivalTime: '~3 minutes',
      ),
      Network(
        name: 'BSC',
        blockchain: 'bsc',
        version: 'BEP20',
        network: 'mainnet',
        arrivalTime: '~3 minutes',
      ),
    ],
  ),
  Coin(
    id: 'bnb-native-mainnet',
    name: 'BNB',
    symbol: 'BNB',
    iconUrl: 'bnb',
    networks: [
      Network(
        name: 'BSC',
        blockchain: 'bsc',
        version: 'NATIVE',
        network: 'mainnet',
        arrivalTime: '~3 minutes',
      ),
    ],
  ),
  Coin(
    id: 'sol-native-mainnet',
    name: 'Solana',
    symbol: 'SOL',
    iconUrl: 'solana',
    networks: [
      Network(
        name: 'Solana',
        blockchain: 'solana',
        version: 'NATIVE',
        network: 'mainnet',
        arrivalTime: '~1 minute',
      ),
    ],
  ),
  // Add more coins as needed
]; 