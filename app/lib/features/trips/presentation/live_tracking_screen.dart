import 'package:flutter/material.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Track bus', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 5),
          Text(
            'Morning pickup • Tuesday, September 3',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          Container(
            height: 290,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _RoutePainter())),
                const Positioned(
                  top: 22,
                  left: 22,
                  child: _MapBadge(
                    icon: Icons.school_outlined,
                    label: 'School',
                  ),
                ),
                const Positioned(
                  bottom: 34,
                  right: 20,
                  child: _MapBadge(
                    icon: Icons.home_outlined,
                    label: 'Your stop',
                  ),
                ),
                const Positioned(
                  top: 122,
                  left: 145,
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0xFF1769E0),
                    child: Icon(
                      Icons.directions_bus_filled_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5EAE3)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.directions_bus_filled_rounded,
                  color: Color(0xFF1769E0),
                  size: 30,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus 24 is moving',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '8 minutes to your pickup stop',
                        style: TextStyle(color: Color(0xFF66736D)),
                      ),
                    ],
                  ),
                ),
                Text(
                  '7:42 AM',
                  style: TextStyle(
                    color: Color(0xFF1769E0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Route details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const _RouteStop(
            label: 'Oakwood Elementary',
            time: '7:25 AM',
            complete: true,
          ),
          const _RouteStop(
            label: 'Pine Street',
            time: '7:36 AM',
            complete: true,
          ),
          const _RouteStop(
            label: 'Your pickup stop',
            time: '7:42 AM',
            complete: false,
          ),
        ],
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF1769E0)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.label,
    required this.time,
    required this.complete,
  });
  final String label;
  final String time;
  final bool complete;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(
          complete
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: complete ? const Color(0xFF1769E0) : const Color(0xFFB8C4BB),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(time, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6C9FEA)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * .18, size.height * .18)
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .68,
        size.width * .72,
        size.height * .46,
      )
      ..quadraticBezierTo(
        size.width * .84,
        size.height * .37,
        size.width * .87,
        size.height * .78,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
