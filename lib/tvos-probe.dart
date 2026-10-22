import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: Color(0xFFFF0000),
        child: Center(
          child: Text(
            'TVOS OK',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 96,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}
