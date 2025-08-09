enum InternalTransferStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

class InternalTransfer {
  final String id;
  final String senderEmail;
  final String receiverEmail;
  final String coin;
  final String network;
  final double amount;
  final double fee;
  final double receiveAmount;
  final InternalTransferStatus status;
  final DateTime timestamp;
  final String? txId;
  final String? memo;
  final String? tag;

  const InternalTransfer({
    required this.id,
    required this.senderEmail,
    required this.receiverEmail,
    required this.coin,
    required this.network,
    required this.amount,
    required this.fee,
    required this.receiveAmount,
    required this.status,
    required this.timestamp,
    this.txId,
    this.memo,
    this.tag,
  });

  factory InternalTransfer.fromJson(Map<String, dynamic> json) {
    return InternalTransfer(
      id: json['id'] ?? '',
      senderEmail: json['senderEmail'] ?? json['sender']?['email'] ?? '',
      receiverEmail: json['receiverEmail'] ?? json['receiver']?['email'] ?? '',
      coin: json['coin'] ?? json['token']?['symbol'] ?? '',
      network: json['network'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      fee: double.tryParse(json['fee']?.toString() ?? '0') ?? 0.0,
      receiveAmount:
          double.tryParse(json['receiveAmount']?.toString() ?? '0') ?? 0.0,
      status: _parseStatus(json['status']),
      timestamp: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      txId: json['txHash'] ?? json['txId'],
      memo: json['memo'],
      tag: json['tag'],
    );
  }

  static InternalTransferStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return InternalTransferStatus.pending;
      case 'processing':
        return InternalTransferStatus.processing;
      case 'completed':
        return InternalTransferStatus.completed;
      case 'failed':
        return InternalTransferStatus.failed;
      case 'cancelled':
        return InternalTransferStatus.cancelled;
      default:
        return InternalTransferStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'coin': coin,
      'network': network,
      'amount': amount,
      'fee': fee,
      'receiveAmount': receiveAmount,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'txId': txId,
      'memo': memo,
      'tag': tag,
    };
  }

  String get statusText {
    switch (status) {
      case InternalTransferStatus.pending:
        return 'Pending';
      case InternalTransferStatus.processing:
        return 'Processing';
      case InternalTransferStatus.completed:
        return 'Completed';
      case InternalTransferStatus.failed:
        return 'Failed';
      case InternalTransferStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isCompleted => status == InternalTransferStatus.completed;
  bool get isFailed => status == InternalTransferStatus.failed;
  bool get isCancelled => status == InternalTransferStatus.cancelled;
  bool get isPending => status == InternalTransferStatus.pending;
  bool get isProcessing => status == InternalTransferStatus.processing;
}

// Demo data for testing
final List<InternalTransfer> internalTransferHistory = [
  InternalTransfer(
    id: 'IT1',
    senderEmail: 'sender@example.com',
    receiverEmail: 'receiver@example.com',
    coin: 'BTC',
    network: 'Bitcoin Network',
    amount: 0.1234,
    fee: 0.0001,
    receiveAmount: 0.1233,
    status: InternalTransferStatus.completed,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    txId: '0x1234567890abcdef',
  ),
  InternalTransfer(
    id: 'IT2',
    senderEmail: 'sender@example.com',
    receiverEmail: 'another@example.com',
    coin: 'ETH',
    network: 'Ethereum Network',
    amount: 1.5,
    fee: 0.005,
    receiveAmount: 1.495,
    status: InternalTransferStatus.pending,
    timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
  ),
];
