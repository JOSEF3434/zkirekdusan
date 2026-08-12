// lib/features/live/domain/stream_health_model.dart
// Maps to the `stream:health` Socket.IO event payload from LiveGateway.

enum StreamHealthLevel { good, fair, poor, unknown }

class StreamHealthDto {
  final String streamId;
  final StreamHealthLevel health;
  final double avgBandwidth;
  final double p50;
  final double p95;
  final int reportsCount;
  final DateTime timestamp;

  const StreamHealthDto({
    required this.streamId,
    required this.health,
    required this.avgBandwidth,
    required this.p50,
    required this.p95,
    required this.reportsCount,
    required this.timestamp,
  });

  factory StreamHealthDto.fromJson(Map<String, dynamic> json) {
    final healthStr = (json['health'] as String?)?.toUpperCase();
    final health = switch (healthStr) {
      'GOOD' => StreamHealthLevel.good,
      'FAIR' => StreamHealthLevel.fair,
      'POOR' => StreamHealthLevel.poor,
      _ => StreamHealthLevel.unknown,
    };
    return StreamHealthDto(
      streamId: json['streamId'] as String? ?? '',
      health: health,
      avgBandwidth: (json['avgBandwidth'] as num?)?.toDouble() ?? 0,
      p50: (json['p50'] as num?)?.toDouble() ?? 0,
      p95: (json['p95'] as num?)?.toDouble() ?? 0,
      reportsCount: json['reportsCount'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
    );
  }
}
