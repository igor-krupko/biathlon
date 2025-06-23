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
} 