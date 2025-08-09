enum WithdrawalStatus {
  pending,
  processing,
  completed,
  failed,
}

class Withdrawal {
  final String id;
  final String coin;
  final String network;
  final double amount;
  final String address;
  final WithdrawalStatus status;
  final DateTime timestamp;
  final String txId;

  const Withdrawal({
    required this.id,
    required this.coin,
    required this.network,
    required this.amount,
    required this.address,
    required this.status,
    required this.timestamp,
    required this.txId,
  });
}

// Demo data
final List<Withdrawal> withdrawalHistory = [
  Withdrawal(
    id: 'W1',
    coin: 'BTC',
    network: 'Bitcoin Network (BTC)',
    amount: 0.1234,
    address: 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
    status: WithdrawalStatus.completed,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    txId: '0x1234567890abcdef',
  ),
  // Add more demo withdrawals...
]; 