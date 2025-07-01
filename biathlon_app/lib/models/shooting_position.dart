enum ShootingPosition {
  down,
  standing;

  String get name {
    switch (this) {
      case ShootingPosition.down:
        return 'Prone';
      case ShootingPosition.standing:
        return 'Standing';
    }
  }

  static ShootingPosition fromString(String value) {
    switch (value) {
      case 'down':
        return ShootingPosition.down;
      case 'standing':
        return ShootingPosition.standing;
      default:
        throw Exception('Unknown ShootingPosition: $value');
    }
  }

  String toJson() => toString().split('.').last;
} 