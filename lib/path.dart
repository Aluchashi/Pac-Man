import 'package:flutter/material.dart';

class MyPath extends StatelessWidget {
  const MyPath({super.key, this.innercolor, this.outercolor, this.child});
  final innercolor;
  final outercolor;
  final child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(14),
          color: outercolor,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: innercolor,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
