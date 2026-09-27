import 'package:flutter/material.dart';

String mapStatusLabel(String group) => switch (group) {
  'HANDLING' => 'Being handled',
  'RESOLVED' => 'Resolved',
  _ => 'Needs attention',
};
Color mapStatusColor(String group) => switch (group) {
  'HANDLING' => const Color(0xFFB87516),
  'RESOLVED' => const Color(0xFF28744A),
  _ => const Color(0xFFB34339),
};
