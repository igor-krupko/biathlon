enum TrackType {
  sprint,
  pursuit,
  mass,
  individual;

  static TrackType fromString(String value) {
    switch (value) {
      case 'sprint':
        return TrackType.sprint;
      case 'pursuit':
        return TrackType.pursuit;
      case 'mass':
        return TrackType.mass;
      case 'individual':
        return TrackType.individual;
      default:
        throw Exception('Unknown TrackType: $value');
    }
  }

  String toJson() => toString().split('.').last;
} 