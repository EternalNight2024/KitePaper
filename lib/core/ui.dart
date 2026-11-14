import 'package:material_ui/material_ui.dart';

Widget glassBackground(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return Stack(
    children: [
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [
                      Color(0xFF101A33),
                      Color(0xFF261445),
                      Color(0xFF07323C),
                    ]
                  : const [
                      Color(0xFFDDEBFF),
                      Color(0xFFEBD9FF),
                      Color(0xFFFFE1D2),
                    ],
            ),
          ),
        ),
      ),
      Positioned(top: 60, left: -90, child: _orb(const Color(0x66FF8A5B), 240)),
      Positioned(
          top: 220, right: -70, child: _orb(const Color(0x558A7BFF), 210)),
      Positioned(
          bottom: 90, left: 60, child: _orb(const Color(0x5546C6FF), 180)),
    ],
  );
}

Widget _orb(Color color, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );

Widget statusMessage(String message) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13),
      ),
    );

const pagePadding = EdgeInsets.fromLTRB(16, 16, 16, 130);
