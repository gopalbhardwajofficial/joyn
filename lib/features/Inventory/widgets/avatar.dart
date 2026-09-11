import 'package:flutter/material.dart';

class PartyAvatarOption {
  const PartyAvatarOption({required this.emoji, required this.gradient});

  final String emoji;
  final List<Color> gradient;
}

const List<PartyAvatarOption> kPartyAvatarOptions = [
  PartyAvatarOption(emoji: '👨‍💼', gradient: [Color(0xFFFFB88C), Color(0xFFFF7E5F)]),
  PartyAvatarOption(emoji: '👩‍💼', gradient: [Color(0xFFCFD9DF), Color(0xFF8B9FA8)]),
  PartyAvatarOption(emoji: '🎌', gradient: [Color(0xFFFFE29F), Color(0xFFFFA751)]),
  PartyAvatarOption(emoji: '💼', gradient: [Color(0xFFA1C4FD), Color(0xFF6E9BD9)]),
  PartyAvatarOption(emoji: '🦸', gradient: [Color(0xFFB3E5FC), Color(0xFF4FA3D1)]),
  PartyAvatarOption(emoji: '🧑‍💼', gradient: [Color(0xFFF8C6D8), Color(0xFFE187A6)]),
  PartyAvatarOption(emoji: '🐯', gradient: [Color(0xFFFFCB8E), Color(0xFFF57C3C)]),
  PartyAvatarOption(emoji: '🦉', gradient: [Color(0xFFD9C2FF), Color(0xFF8E6FCE)]),
  PartyAvatarOption(emoji: '🐰', gradient: [Color(0xFFFFD6E8), Color(0xFFF599C2)]),
];