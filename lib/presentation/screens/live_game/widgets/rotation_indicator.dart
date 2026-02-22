import 'package:flutter/material.dart';

/// Compact rotation indicator showing current volleyball rotation (1-6).
/// Displays the current rotation number and server information.
class RotationIndicator extends StatelessWidget {
  final int currentRotation;
  final VoidCallback? onRotateForward;
  final VoidCallback? onRotateBackward;
  final String? serverName;
  final String? serverNumber;

  const RotationIndicator({
    super.key,
    required this.currentRotation,
    this.onRotateForward,
    this.onRotateBackward,
    this.serverName,
    this.serverNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onRotateBackward,
            child: const Icon(
              Icons.chevron_left,
              color: Colors.white54,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(26),
              border: Border.all(color: Colors.white38, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              'R$currentRotation',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRotateForward,
            child: const Icon(
              Icons.chevron_right,
              color: Colors.white54,
              size: 20,
            ),
          ),
          if (serverName != null || serverNumber != null) ...[
            const SizedBox(width: 12),
            Icon(
              Icons.sports_volleyball,
              color: Colors.white54,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              serverNumber != null && serverName != null
                  ? '#$serverNumber $serverName'
                  : serverName ?? '#$serverNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
