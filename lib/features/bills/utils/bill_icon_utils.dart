import 'package:flutter/material.dart';

class BillIconUtils {
  static Widget getIconWidget(
    String name,
    ColorScheme colorScheme, {
    double size = 12,
  }) {
    final lower = name.toLowerCase();
    if (lower.contains('youtube')) {
      return Icon(Icons.play_circle_filled, color: Colors.red, size: size);
    } else if (lower.contains('netflix')) {
      return Icon(Icons.movie, color: Colors.red, size: size);
    } else if (lower.contains('spotify')) {
      return Icon(Icons.music_note, color: Colors.green, size: size);
    } else if (lower.contains('icloud') ||
        lower.contains('cloud') ||
        lower.contains('drive') ||
        lower.contains('google one')) {
      return Icon(Icons.cloud, color: Colors.blue, size: size);
    } else if (lower.contains('điện') || lower.contains('electricity')) {
      return Icon(Icons.bolt, color: Colors.amber, size: size);
    } else if (lower.contains('nước') || lower.contains('water')) {
      return Icon(Icons.water_drop, color: Colors.blueAccent, size: size);
    } else if (lower.contains('internet') ||
        lower.contains('wifi') ||
        lower.contains('mạng')) {
      return Icon(Icons.wifi, color: Colors.indigo, size: size);
    } else if (lower.contains('điện thoại') ||
        lower.contains('phone') ||
        lower.contains('cước')) {
      return Icon(Icons.phone_android, color: Colors.teal, size: size);
    } else if (lower.contains('gym') || lower.contains('fitness')) {
      return Icon(Icons.fitness_center, color: Colors.orange, size: size);
    } else if (lower.contains('amazon') || lower.contains('prime')) {
      return Icon(Icons.shopping_cart, color: Colors.orange, size: size);
    } else if (lower.contains('disney')) {
      return Icon(Icons.castle, color: Colors.blue, size: size);
    } else if (lower.contains('apple') || lower.contains('itunes')) {
      return Icon(Icons.apple, color: Colors.grey, size: size);
    }
    return Icon(
      Icons.receipt_long,
      color: colorScheme.onSecondaryContainer,
      size: size,
    );
  }
}
