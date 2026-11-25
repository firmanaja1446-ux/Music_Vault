import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.music_off,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Column(
        children: [
          Icon(icon, color: Colors.white24, size: 54),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
