class GradingLog {
  final String uuid;
  final int userId;
  final String imagePath;
  final String audioPath;
  final String visualPred;
  final String audioPred;
  final String finalStage;
  final double confidence;
  final bool isSynced;
  final String createdAt;

  GradingLog({
    required this.uuid,
    required this.userId,
    required this.imagePath,
    required this.audioPath,
    required this.visualPred,
    required this.audioPred,
    required this.finalStage,
    required this.confidence,
    this.isSynced = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'user_id': userId,
      'image_path': imagePath,
      'audio_path': audioPath,
      'visual_pred': visualPred,
      'audio_pred': audioPred,
      'final_stage': finalStage,
      'confidence': confidence,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory GradingLog.fromMap(Map<String, dynamic> map) {
    return GradingLog(
      uuid: map['uuid'],
      userId: map['user_id'],
      imagePath: map['image_path'],
      audioPath: map['audio_path'],
      visualPred: map['visual_pred'],
      audioPred: map['audio_pred'],
      finalStage: map['final_stage'],
      confidence: (map['confidence'] as num).toDouble(),
      isSynced: map['is_synced'] == 1,
      createdAt: map['created_at'],
    );
  }
}