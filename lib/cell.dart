import 'package:flutter/material.dart';

class MyCell extends StatelessWidget {
  const MyCell({super.key, this.innercolor, this.outercolor, this.child});
  final innercolor;
  final outercolor;
  final child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(4),
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
