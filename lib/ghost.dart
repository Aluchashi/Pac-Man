import 'package:flutter/material.dart';

class MyGhost extends StatelessWidget {
  final int ghostNumber; // 1, 2, 3, বা 4

  const MyGhost({super.key, required this.ghostNumber});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Image.asset('lib/image/ghost_$ghostNumber.png'),
    );
  }
}