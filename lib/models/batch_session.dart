class BatchSession {
  final String batchId;
  final String farmerName;
  final double maturePrice;
  final double prematurePrice;
  final double rejectPrice;
  final String createdAt;
  final bool isClosed;

  BatchSession({
    required this.batchId,
    required this.farmerName,
    this.maturePrice = 12.0,
    this.prematurePrice = 7.0,
    this.rejectPrice = 0.0,
    required this.createdAt,
    this.isClosed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'batch_id': batchId,
      'farmer_name': farmerName,
      'mature_price': maturePrice,
      'premature_price': prematurePrice,
      'reject_price': rejectPrice,
      'created_at': createdAt,
      'is_closed': isClosed ? 1 : 0,
    };
  }

  factory BatchSession.fromMap(Map<String, dynamic> map) {
    return BatchSession(
      batchId: map['batch_id'],
      farmerName: map['farmer_name'],
      maturePrice: (map['mature_price'] as num?)?.toDouble() ?? 12.0,
      prematurePrice: (map['premature_price'] as num?)?.toDouble() ?? 7.0,
      rejectPrice: (map['reject_price'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'],
      isClosed: (map['is_closed'] as int?) == 1,
    );
  }
}

class BatchSummary {
  final BatchSession session;
  final int totalScans;
  final int matureCount;
  final int prematureCount;
  final int rejectCount;
  final double totalPayout;

  BatchSummary({
    required this.session,
    required this.totalScans,
    required this.matureCount,
    required this.prematureCount,
    required this.rejectCount,
    required this.totalPayout,
  });

  double get maturePercent => totalScans > 0 ? (matureCount / totalScans) * 100 : 0.0;
  double get prematurePercent => totalScans > 0 ? (prematureCount / totalScans) * 100 : 0.0;
  double get rejectPercent => totalScans > 0 ? (rejectCount / totalScans) * 100 : 0.0;
}
