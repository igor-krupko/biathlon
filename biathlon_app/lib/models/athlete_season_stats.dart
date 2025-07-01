class AthleteSeasonStats {
  final bool isActive;
  final int speed;
  final int shootingDown;
  final int shootingStanding;

  AthleteSeasonStats({
    required this.isActive,
    required this.speed,
    required this.shootingDown,
    required this.shootingStanding,
  });

  factory AthleteSeasonStats.fromJson(Map<String, dynamic> json) {
    return AthleteSeasonStats(
      isActive: json['isActive'] as bool,
      speed: json['speed'] as int,
      shootingDown: json['shootingDown'] as int,
      shootingStanding: json['shootingStanding'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'isActive': isActive,
        'speed': speed,
        'shootingDown': shootingDown,
        'shootingStanding': shootingStanding,
      };
} 