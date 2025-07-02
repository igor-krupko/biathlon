import '../../models/race.dart';
import '../../models/track.dart';

final List<Race> races2000 = [
  // Antholz-Anterselva, Italy (30 Nov–3 Dec 2000)
  Race(
    id: 101,
    date: DateTime(2000, 11, 30),
    track: Track.individual(
      id: 2101,
      name: 'Antholz',
      country: 'Italy',
      lapDistance: 2000.0,
      backgroundAsset: 'assets/backgrounds/antholz.png',
    ),
    tournament: Tournament.worldCup,
    stage: 1,
  ),
  Race(
    id: 102,
    date: DateTime(2000, 12, 2),
    track: Track.sprint(
      id: 2102,
      name: 'Antholz',
      country: 'Italy',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/antholz.png',
    ),
    tournament: Tournament.worldCup,
    stage: 1,
  ),
  Race(
    id: 103,
    date: DateTime(2000, 12, 3),
    track: Track.mass(
      id: 2103,
      name: 'Antholz',
      country: 'Italy',
      lapDistance: 1500.0,
      backgroundAsset: 'assets/backgrounds/antholz.png',
    ),
    tournament: Tournament.worldCup,
    stage: 1,
  ),

  // Hochfilzen, Austria (7–10 Dec 2000)
  Race(
    id: 104,
    date: DateTime(2000, 12, 7),
    track: Track.sprint(
      id: 2104,
      name: 'Hochfilzen',
      country: 'Austria',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/hochfilzen.png',
    ),
    tournament: Tournament.worldCup,
    stage: 2,
  ),
  Race(
    id: 105,
    date: DateTime(2000, 12, 9),
    track: Track.pursuit(
      id: 2105,
      name: 'Hochfilzen',
      country: 'Austria',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/hochfilzen.png',
    ),
    tournament: Tournament.worldCup,
    stage: 2,
  ),
  Race(
    id: 106,
    date: DateTime(2000, 12, 10),
    track: Track.mass(
      id: 2106,
      name: 'Hochfilzen',
      country: 'Austria',
      lapDistance: 1500.0,
      backgroundAsset: 'assets/backgrounds/hochfilzen.png',
    ),
    tournament: Tournament.worldCup,
    stage: 2,
  ),

  // Pokljuka, Slovenia (14–17 Dec 2000)
  Race(
    id: 107,
    date: DateTime(2000, 12, 14),
    track: Track.sprint(
      id: 2107,
      name: 'Pokljuka',
      country: 'Slovenia',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/pokljuka.png',
    ),
    tournament: Tournament.worldCup,
    stage: 3,
  ),
  Race(
    id: 108,
    date: DateTime(2000, 12, 16),
    track: Track.pursuit(
      id: 2108,
      name: 'Pokljuka',
      country: 'Slovenia',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/pokljuka.png',
    ),
    tournament: Tournament.worldCup,
    stage: 3,
  ),
  Race(
    id: 109,
    date: DateTime(2000, 12, 17),
    track: Track.mass(
      id: 2109,
      name: 'Pokljuka',
      country: 'Slovenia',
      lapDistance: 1500.0,
      backgroundAsset: 'assets/backgrounds/pokljuka.png',
    ),
    tournament: Tournament.worldCup,
    stage: 3,
  ),

  // Osrblie, Slovakia (4–7 Jan 2001)
  Race(
    id: 110,
    date: DateTime(2001, 1, 4),
    track: Track.sprint(
      id: 2110,
      name: 'Osrblie',
      country: 'Slovakia',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/osrblie.png',
    ),
    tournament: Tournament.worldCup,
    stage: 4,
  ),
  Race(
    id: 111,
    date: DateTime(2001, 1, 6),
    track: Track.pursuit(
      id: 2111,
      name: 'Osrblie',
      country: 'Slovakia',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/osrblie.png',
    ),
    tournament: Tournament.worldCup,
    stage: 4,
  ),
  Race(
    id: 112,
    date: DateTime(2001, 1, 7),
    track: Track.mass(
      id: 2112,
      name: 'Osrblie',
      country: 'Slovakia',
      lapDistance: 1500.0,
      backgroundAsset: 'assets/backgrounds/osrblie.png',
    ),
    tournament: Tournament.worldCup,
    stage: 4,
  ),

  // Oberhof, Germany (10–14 Jan 2001)
  Race(
    id: 113,
    date: DateTime(2001, 1, 10),
    track: Track.individual(
      id: 2113,
      name: 'Oberhof',
      country: 'Germany',
      lapDistance: 2000.0,
      backgroundAsset: 'assets/backgrounds/oberhof.png',
    ),
    tournament: Tournament.worldCup,
    stage: 5,
  ),
  Race(
    id: 114,
    date: DateTime(2001, 1, 12),
    track: Track.sprint(
      id: 2114,
      name: 'Oberhof',
      country: 'Germany',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/oberhof.png',
    ),
    tournament: Tournament.worldCup,
    stage: 5,
  ),
  Race(
    id: 115,
    date: DateTime(2001, 1, 14),
    track: Track.mass(
      id: 2115,
      name: 'Oberhof',
      country: 'Germany',
      lapDistance: 1500.0,
      backgroundAsset: 'assets/backgrounds/oberhof.png',
    ),
    tournament: Tournament.worldCup,
    stage: 5,
  ),

  // Ruhpolding, Germany (17–21 Jan 2001)
  Race(
    id: 116,
    date: DateTime(2001, 1, 17),
    track: Track.sprint(
      id: 2116,
      name: 'Ruhpolding',
      country: 'Germany',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/ruhpolding.png',
    ),
    tournament: Tournament.worldCup,
    stage: 6,
  ),
  Race(
    id: 117,
    date: DateTime(2001, 1, 19),
    track: Track.pursuit(
      id: 2117,
      name: 'Ruhpolding',
      country: 'Germany',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/ruhpolding.png',
    ),
    tournament: Tournament.worldCup,
    stage: 6,
  ),
  Race(
    id: 118,
    date: DateTime(2001, 1, 21),
    track: Track.mass(
      id: 2118,
      name: 'Ruhpolding',
      country: 'Germany',
      lapDistance: 1500.0,
      backgroundAsset: 'assets/backgrounds/ruhpolding.png',
    ),
    tournament: Tournament.worldCup,
    stage: 6,
  ),

  // Antholz-Anterselva, Italy (24–28 Jan 2001)
  Race(
    id: 119,
    date: DateTime(2001, 1, 24),
    track: Track.sprint(
      id: 2119,
      name: 'Antholz',
      country: 'Italy',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/antholz.png',
    ),
    tournament: Tournament.worldCup,
    stage: 7,
  ),
  Race(
    id: 120,
    date: DateTime(2001, 1, 26),
    track: Track.pursuit(
      id: 2120,
      name: 'Antholz',
      country: 'Italy',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/antholz.png',
    ),
    tournament: Tournament.worldCup,
    stage: 7,
  ),
  Race(
    id: 121,
    date: DateTime(2001, 1, 28),
    track: Track.mass(
      id: 2121,
      name: 'Antholz',
      country: 'Italy',
      lapDistance: 1500.0,
      backgroundAsset: 'assets/backgrounds/antholz.png',
    ),
    tournament: Tournament.worldCup,
    stage: 7,
  ),

  // World Championships 2001, Pokljuka, Slovenia (3–11 Feb 2001)
  Race(
    id: 122,
    date: DateTime(2001, 2, 3),
    track: Track.individual(
      id: 2122,
      name: 'Pokljuka',
      country: 'Slovenia',
      lapDistance: 2000.0,
      backgroundAsset: 'assets/backgrounds/pokljuka.png',
    ),
    tournament: Tournament.wc,
    stage: null,
  ),
  Race(
    id: 123,
    date: DateTime(2001, 2, 7),
    track: Track.sprint(
      id: 2123,
      name: 'Pokljuka',
      country: 'Slovenia',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/pokljuka.png',
    ),
    tournament: Tournament.wc,
    stage: null,
  ),
  Race(
    id: 124,
    date: DateTime(2001, 2, 8),
    track: Track.pursuit(
      id: 2124,
      name: 'Pokljuka',
      country: 'Slovenia',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/pokljuka.png',
    ),
    tournament: Tournament.wc,
    stage: null,
  ),
  Race(
    id: 125,
    date: DateTime(2001, 2, 10),
    track: Track.mass(
      id: 2125,
      name: 'Pokljuka',
      country: 'Slovenia',
      lapDistance: 1500.0,
      backgroundAsset: 'assets/backgrounds/pokljuka.png',
    ),
    tournament: Tournament.wc,
    stage: null,
  ),

  // Lahti, Finland (7–11 Feb 2001)
  Race(
    id: 127,
    date: DateTime(2001, 2, 7),
    track: Track.sprint(
      id: 2127,
      name: 'Lahti',
      country: 'Finland',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/lahti.png',
    ),
    tournament: Tournament.worldCup,
    stage: 8,
  ),
  Race(
    id: 128,
    date: DateTime(2001, 2, 9),
    track: Track.pursuit(
      id: 2128,
      name: 'Lahti',
      country: 'Finland',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/lahti.png',
    ),
    tournament: Tournament.worldCup,
    stage: 8,
  ),
  Race(
    id: 129,
    date: DateTime(2001, 2, 11),
    track: Track.mass(
      id: 2129,
      name: 'Lahti',
      country: 'Finland',
      lapDistance: 1500.0,
      backgroundAsset: 'assets/backgrounds/lahti.png',
    ),
    tournament: Tournament.worldCup,
    stage: 8,
  ),

  // Oslo Holmenkollen, Norway (1–4 Mar 2001)
  Race(
    id: 130,
    date: DateTime(2001, 3, 1),
    track: Track.sprint(
      id: 2130,
      name: 'Holmenkollen',
      country: 'Norway',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/holmenkollen.png',
    ),
    tournament: Tournament.worldCup,
    stage: 9,
  ),
  Race(
    id: 131,
    date: DateTime(2001, 3, 3),
    track: Track.pursuit(
      id: 2131,
      name: 'Holmenkollen',
      country: 'Norway',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/holmenkollen.png',
    ),
    tournament: Tournament.worldCup,
    stage: 9,
  ),
  Race(
    id: 132,
    date: DateTime(2001, 3, 4),
    track: Track.mass(
      id: 2132,
      name: 'Holmenkollen',
      country: 'Norway',
      lapDistance: 1500.0,
      backgroundAsset: 'assets/backgrounds/holmenkollen.png',
    ),
    tournament: Tournament.worldCup,
    stage: 9,
  ),

  // Khanty-Mansiysk, Russia (15–18 Mar 2001)
  Race(
    id: 133,
    date: DateTime(2001, 3, 15),
    track: Track.sprint(
      id: 2133,
      name: 'Khanty-Mansiysk',
      country: 'Russia',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/khanty_mansiysk.png',
    ),
    tournament: Tournament.worldCup,
    stage: 10,
  ),
  Race(
    id: 134,
    date: DateTime(2001, 3, 17),
    track: Track.pursuit(
      id: 2134,
      name: 'Khanty-Mansiysk',
      country: 'Russia',
      lapDistance: 1200.0,
      backgroundAsset: 'assets/backgrounds/khanty_mansiysk.png',
    ),
    tournament: Tournament.worldCup,
    stage: 10,
  ),
  Race(
    id: 135,
    date: DateTime(2001, 3, 18),
    track: Track.mass(
      id: 2135,
      name: 'Khanty-Mansiysk',
      country: 'Russia',
      lapDistance: 1500.0,
      backgroundAsset: 'assets/backgrounds/khanty_mansiysk.png',
    ),
    tournament: Tournament.worldCup,
    stage: 10,
  ),
]; 