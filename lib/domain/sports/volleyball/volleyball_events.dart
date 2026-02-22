import 'package:flutter/material.dart';

import '../sport_plugin.dart';

/// Constants defining all volleyball event types organized by category.
class VolleyballEvents {
  VolleyballEvents._();

  // ── Attack ────────────────────────────────────────────────────────────
  static const kill = EventType(
    id: 'kill',
    label: 'Kill',
    category: 'attack',
    defaultResult: 'point_us',
    availableInQuickMode: true,
    icon: Icons.sports_volleyball,
  );

  static const attackError = EventType(
    id: 'attack_error',
    label: 'Attack Error',
    shortLabel: 'Error',
    category: 'attack',
    defaultResult: 'point_them',
    availableInQuickMode: true,
    icon: Icons.error_outline,
  );

  static const blocked = EventType(
    id: 'blocked',
    label: 'Blocked',
    shortLabel: 'Atk Blk',
    category: 'attack',
    defaultResult: 'point_them',
  );

  static const zeroAttack = EventType(
    id: 'zero_attack',
    label: 'Zero Attack',
    shortLabel: '0 Atk',
    category: 'attack',
    defaultResult: 'rally_continues',
  );

  // ── Serve ─────────────────────────────────────────────────────────────
  static const ace = EventType(
    id: 'ace',
    label: 'Ace',
    category: 'serve',
    defaultResult: 'point_us',
    availableInQuickMode: true,
    icon: Icons.flash_on,
  );

  static const serveError = EventType(
    id: 'serve_error',
    label: 'Serve Error',
    shortLabel: 'Srv Err',
    category: 'serve',
    defaultResult: 'point_them',
    availableInQuickMode: true,
    icon: Icons.cancel_outlined,
  );

  static const serveInPlay = EventType(
    id: 'serve_in_play',
    label: 'Serve In Play',
    shortLabel: 'Srv In',
    category: 'serve',
    defaultResult: 'rally_continues',
  );

  // ── Block ─────────────────────────────────────────────────────────────
  static const blockSolo = EventType(
    id: 'block_solo',
    label: 'Block Solo',
    shortLabel: 'Block',
    category: 'block',
    defaultResult: 'point_us',
    availableInQuickMode: true,
    icon: Icons.front_hand,
  );

  static const blockAssist = EventType(
    id: 'block_assist',
    label: 'Block Assist',
    shortLabel: 'Blk Ast',
    category: 'block',
    defaultResult: 'point_us',
  );

  static const blockError = EventType(
    id: 'block_error',
    label: 'Block Error',
    shortLabel: 'Blk Err',
    category: 'block',
    defaultResult: 'point_them',
  );

  // ── Dig ───────────────────────────────────────────────────────────────
  static const dig = EventType(
    id: 'dig',
    label: 'Dig',
    category: 'dig',
    defaultResult: 'rally_continues',
    availableInQuickMode: true,
    icon: Icons.arrow_downward,
  );

  static const digError = EventType(
    id: 'dig_error',
    label: 'Dig Error',
    shortLabel: 'Dig Err',
    category: 'dig',
    defaultResult: 'point_them',
  );

  // ── Pass (Reception) ─────────────────────────────────────────────────
  static const passQuality3 = EventType(
    id: 'pass_3',
    label: 'Pass - 3 (Perfect)',
    shortLabel: 'Pass 3',
    category: 'pass',
    defaultResult: 'rally_continues',
  );

  static const passQuality2 = EventType(
    id: 'pass_2',
    label: 'Pass - 2 (Good)',
    shortLabel: 'Pass 2',
    category: 'pass',
    defaultResult: 'rally_continues',
  );

  static const passQuality1 = EventType(
    id: 'pass_1',
    label: 'Pass - 1 (Playable)',
    shortLabel: 'Pass 1',
    category: 'pass',
    defaultResult: 'rally_continues',
  );

  static const passQuality0 = EventType(
    id: 'pass_0',
    label: 'Pass - 0 (Shank)',
    shortLabel: 'Shank',
    category: 'pass',
    defaultResult: 'rally_continues',
  );

  static const overpass = EventType(
    id: 'overpass',
    label: 'Overpass',
    category: 'pass',
    defaultResult: 'rally_continues',
  );

  static const passError = EventType(
    id: 'pass_error',
    label: 'Pass Error',
    shortLabel: 'Rec Err',
    category: 'pass',
    defaultResult: 'point_them',
  );

  // ── Set ───────────────────────────────────────────────────────────────
  static const setAssist = EventType(
    id: 'set_assist',
    label: 'Assist',
    shortLabel: 'Assist',
    category: 'set',
    defaultResult: 'rally_continues',
    availableInQuickMode: true,
    icon: Icons.swap_horiz,
  );

  static const setError = EventType(
    id: 'set_error',
    label: 'Set Error',
    shortLabel: 'Set Err',
    category: 'set',
    defaultResult: 'point_them',
  );

  // ── Opponent ──────────────────────────────────────────────────────────
  static const oppKill = EventType(
    id: 'opp_kill',
    label: 'Opp Kill',
    category: 'opponent',
    defaultResult: 'point_them',
  );

  static const oppError = EventType(
    id: 'opp_error',
    label: 'Opp Error',
    shortLabel: 'Opp Err',
    category: 'opponent',
    defaultResult: 'point_us',
    availableInQuickMode: true,
    icon: Icons.thumb_up_outlined,
  );

  static const oppAttempt = EventType(
    id: 'opp_attempt',
    label: 'Opp Attempt',
    shortLabel: 'Opp Atk',
    category: 'opponent',
    defaultResult: 'rally_continues',
  );

  // ── Category groupings ────────────────────────────────────────────────
  static const attackCategory = EventCategory(
    id: 'attack',
    label: 'Attack',
    eventTypes: [kill, attackError, blocked, zeroAttack],
  );

  static const serveCategory = EventCategory(
    id: 'serve',
    label: 'Serve',
    eventTypes: [ace, serveError, serveInPlay],
  );

  static const blockCategory = EventCategory(
    id: 'block',
    label: 'Block',
    eventTypes: [blockSolo, blockAssist, blockError],
  );

  static const digCategory = EventCategory(
    id: 'dig',
    label: 'Dig',
    eventTypes: [dig, digError],
  );

  static const passCategory = EventCategory(
    id: 'pass',
    label: 'Pass',
    eventTypes: [passQuality3, passQuality2, passQuality1, passQuality0, overpass, passError],
  );

  static const setCategory = EventCategory(
    id: 'set',
    label: 'Set',
    eventTypes: [setAssist, setError],
  );

  static const opponentCategory = EventCategory(
    id: 'opponent',
    label: 'Opponent',
    eventTypes: [oppKill, oppError, oppAttempt],
  );

  static List<EventCategory> get allCategories => [
        attackCategory,
        serveCategory,
        blockCategory,
        digCategory,
        passCategory,
        setCategory,
        opponentCategory,
      ];

  /// Quick-mode event categories with only events marked for quick mode.
  static List<EventCategory> get quickModeCategories {
    final quickEvents = [
      kill,
      attackError,
      ace,
      serveError,
      blockSolo,
      dig,
      setAssist,
      oppError,
    ];
    return [
      EventCategory(
        id: 'quick',
        label: 'Quick Actions',
        eventTypes: quickEvents,
      ),
    ];
  }
}
