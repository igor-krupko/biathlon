class AthleteSeasonStats {
  final bool isActive;
  final double speed;
  final double shootingDown;
  final double shootingStanding;

  AthleteSeasonStats({
    required this.isActive,
    required this.speed,
    required this.shootingDown,
    required this.shootingStanding,
  });

  factory AthleteSeasonStats.fromJson(Map<String, dynamic> json) {
    return AthleteSeasonStats(
      isActive: json['isActive'] as bool,
      speed: (json['speed'] as num).toDouble(),
      shootingDown: (json['shootingDown'] as num).toDouble(),
      shootingStanding: (json['shootingStanding'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'isActive': isActive,
        'speed': speed,
        'shootingDown': shootingDown,
        'shootingStanding': shootingStanding,
      };
} 