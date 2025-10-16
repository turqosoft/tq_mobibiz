import 'package:flutter/material.dart';

class HomeTile extends StatelessWidget {
  const HomeTile(
      {super.key,
      required this.title,
      required this.icon,
      required this.onTap});
  final String title;
  final Icon icon;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class HomeTileNew extends StatelessWidget {
  const HomeTileNew(
      {super.key,
      required this.title,
      required this.icon,
      required this.onTap});
  final String title;
  final Icon icon;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return
    //  GestureDetector(
    //   onTap: (){
    //       onTap.call();
    //   },
    //   child: Container(
    //     decoration: BoxDecoration(
    //       color: Colors.white,
    //       borderRadius: BorderRadius.circular(12),
    //       boxShadow: [
    //         BoxShadow(
    //           color: Colors.grey.withOpacity(0.3),
    //           spreadRadius: 2,
    //           blurRadius: 5,
    //         ),
    //       ],
    //     ),
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         icon,
    //       //  Icon(icon, size: 50, color: Colors.blue),
    //         SizedBox(height: 10),
    //         Text(
    //           title,
    //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
    Container(
      child: GestureDetector(
        onTap: () {
          onTap.call();
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class DashboardIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Function onTap;
  

  DashboardIcon({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
          onTap.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.blue),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class SemicirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.purple, Colors.blue],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 2, size.height, size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}