class Bus {
  const Bus({
    required this.id,
    required this.route,
    required this.status,
    required this.school,
    required this.latitude,
    required this.longitude,
    required this.etaMinutes,
    this.updatedAt,
    this.locationFresh = false,
  });

  final String id;
  final String route;
  final String status;
  final String school;
  final double? latitude;
  final double? longitude;
  final int? etaMinutes;
  final DateTime? updatedAt;
  final bool locationFresh;

  bool get isMoving => status == 'on_route';
}
