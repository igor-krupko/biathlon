import 'shooting_position.dart';
import 'track_type.dart';

class Track {
  final int id;
  final String name;
  final String country;
  final int laps;
  final double lapsDistance;
  final List<ShootingPosition> shootingPositions;
  final double lapDistance; // in meters
  final TrackType type;
  final String backgroundAsset;

  const Track({
    required this.id,
    required this.name,
    required this.country,
    required this.laps,
    required this.lapsDistance,
    required this.shootingPositions,
    required this.lapDistance,
    required this.type,
    required this.backgroundAsset,
  });

  // Calculate total distance in meters
  double get totalDistance => laps * lapDistance;

  // Factory method to create a Sprint track
  factory Track.sprint({
    required int id,
    required String name,
    required String country,
    required double lapDistance,
    required String backgroundAsset,
  }) {
    return Track(
      id: id,
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
      backgroundAsset: backgroundAsset,
    );
  }

  // Factory method to create a Pursuit track
  factory Track.pursuit({
    required int id,
    required String name,
    required String country,
    required double lapDistance,
    required String backgroundAsset,
  }) {
    return Track(
      id: id,
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
      backgroundAsset: backgroundAsset,
    );
  }

  // Factory method to create a Mass Start track
  factory Track.mass({
    required int id,
    required String name,
    required String country,
    required double lapDistance,
    required String backgroundAsset,
  }) {
    return Track(
      id: id,
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
      backgroundAsset: backgroundAsset,
    );
  }

  // Factory method to create an Individual track
  factory Track.individual({
    required int id,
    required String name,
    required String country,
    required double lapDistance,
    required String backgroundAsset,
  }) {
    return Track(
      id: id,
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
      backgroundAsset: backgroundAsset,
    );
  }

  @override
  String toString() {
    return 'Track: $name ($country) - ${type.toString().split('.').last} - ${totalDistance}m';
  }
} 