import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../domain/models/play_event.dart';
import '../../../../domain/models/player.dart';

/// Undo notification bar that auto-dismisses after 5 seconds.
class UndoBar extends StatefulWidget {
  final PlayEvent lastEvent;
  final List<Player> players;
  final VoidCallback onUndo;

  const UndoBar({
    super.key,
    required this.lastEvent,
    required this.players,
    required this.onUndo,
  });

  @override
  State<UndoBar> createState() => _UndoBarState();
}

class _UndoBarState extends State<UndoBar> with SingleTickerProviderStateMixin {
  bool _visible = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(UndoBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lastEvent.id != widget.lastEvent.id) {
      _timer?.cancel();
      setState(() => _visible = true);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getPlayerName(String playerId) {
    final player = widget.players.where((p) => p.id == playerId);
    return player.isNotEmpty ? player.first.shortName : '#??';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: _visible ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _visible ? 1.0 : 0.0,
        child: Material(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recorded: ${_getPlayerName(widget.lastEvent.playerId)} - ${widget.lastEvent.eventType} (${widget.lastEvent.result})',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: widget.onUndo,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(48, 36),
                  ),
                  child: const Text('UNDO'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
