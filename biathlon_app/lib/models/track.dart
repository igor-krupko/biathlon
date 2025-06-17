enum ShootingPosition {
  down,
  standing,
}

enum TrackType {
  sprint,
  pursuit,
  mass,
  individual,
}

class Track {
  final String name;
  final String country;
  final int laps;
  final double lapsDistance;
  final List<ShootingPosition> shootingPositions;
  final double lapDistance; // in meters
  final TrackType type;

  const Track({
    required this.name,
    required this.country,
    required this.laps,
    required this.lapsDistance,
    required this.shootingPositions,
    required this.lapDistance,
    required this.type,
  });

  // Calculate total distance in meters
  double get totalDistance => laps * lapDistance;

  // Factory method to create a Sprint track
  factory Track.sprint({
    required String name,
    required String country,
    required double lapDistance,
  }) {
    return Track(
      name: name,
      country: country,
      laps: 3,
      lapsDistance: 0.0,
      shootingPositions: [
        ShootingPosition.down,
        ShootingPosition.standing,
      ],
      lapDistance: lapDistance,
      type: TrackType.sprint,
    );
  }

  // Factory method to create a Pursuit track
  factory Track.pursuit({
    required String name,
    required String country,
    required double lapDistance,
  }) {
    return Track(
      name: name,
      country: country,
      laps: 5,
      lapsDistance: 0.0,
      shootingPositions: [
        ShootingPosition.down,
        ShootingPosition.standing,
        ShootingPosition.down,
        ShootingPosition.standing,
      ],
      lapDistance: lapDistance,
      type: TrackType.pursuit,
    );
  }

  // Factory method to create a Mass Start track
  factory Track.mass({
    required String name,
    required String country,
    required double lapDistance,
  }) {
    return Track(
      name: name,
      country: country,
      laps: 5,
      lapsDistance: 0.0,
      shootingPositions: [
        ShootingPosition.down,
        ShootingPosition.standing,
        ShootingPosition.down,
        ShootingPosition.standing,
      ],
      lapDistance: lapDistance,
      type: TrackType.mass,
    );
  }

  // Factory method to create an Individual track
  factory Track.individual({
    required String name,
    required String country,
    required double lapDistance,
  }) {
    return Track(
      name: name,
      country: country,
      laps: 5,
      lapsDistance: 0.0,
      shootingPositions: [
        ShootingPosition.down,
        ShootingPosition.standing,
        ShootingPosition.down,
        ShootingPosition.standing,
      ],
      lapDistance: lapDistance,
      type: TrackType.individual,
    );
  }

  @override
  String toString() {
    return 'Track: $name ($country) - ${type.toString().split('.').last} - ${totalDistance}m';
  }
} 