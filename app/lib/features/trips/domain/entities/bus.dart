class Bus {
  const Bus({
    required this.id,
    required this.route,
    required this.status,
    required this.school,
    required this.latitude,
    required this.longitude,
    required this.etaMinutes,
  });

  final String id;
  final String route;
  final String status;
  final String school;
  final double? latitude;
  final double? longitude;
  final int? etaMinutes;

  bool get isMoving => status == 'on_route';
}
