import 'package:flutter/material.dart';

// --- COLORS ---
const Color kPixelDarkBlue = Color(0xFF141020);
const Color kPixelCardBg = Color(0xFF2A2636);
const Color kPixelStoneGray = Color(0xFF4E4A4E);
const Color kPixelGold = Color(0xFFFFD541);
const Color kPixelRed = Color(0xFFD53C3C);
const Color kPixelGreen = Color(0xFF5DE76F);
const Color kPixelLightText = Color(0xFFEFEFEF);

// --- HELPER: SCALING ---
double scale(BuildContext context, double value) {
  double screenWidth = MediaQuery.of(context).size.width;
  double scaleFactor = (screenWidth / 375.0).clamp(0.8, 1.2);
  return value * scaleFactor;
}

// --- HELPER: DECORATION ---
BoxDecoration pixelDecoration({
  required Color bgColor,
  required Color borderColor,
  double borderWidth = 3.0,
  bool hasShadow = false,
}) {
  return BoxDecoration(
    color: bgColor,
    border: Border(
      top: BorderSide(color: borderColor, width: borderWidth),
      left: BorderSide(color: borderColor, width: borderWidth),
      right: BorderSide(color: Colors.black.withOpacity(0.5), width: borderWidth),
      bottom: BorderSide(color: Colors.black.withOpacity(0.5), width: borderWidth),
    ),
    boxShadow: hasShadow
        ? [const BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)]
        : null,
  );
}