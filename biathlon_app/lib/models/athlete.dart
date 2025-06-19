class Athlete {
  final String name;
  final String surname;
  final String country;
  final int speed; // 1-100
  final int shootingDown; // 1-100 (prone)
  final int shootingStanding; // 1-100 (standing)
  final int money; // Player's money (default 0 for player)

  const Athlete({
    required this.name,
    required this.surname,
    required this.country,
    required this.speed,
    required this.shootingDown,
    required this.shootingStanding,
    this.money = 0,
  });
} 