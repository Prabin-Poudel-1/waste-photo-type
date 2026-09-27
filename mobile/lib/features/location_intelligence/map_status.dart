import 'package:flutter/material.dart';

String mapStatusLabel(String group) {
  return switch (group) {
    'HANDLING' => 'Being handled',
    'RESOLVED' => 'Resolved',
    _ => 'Needs attention',
  };
}

Color mapStatusColor(String group) {
  return switch (group) {
    'HANDLING' => const Color(0xFFB87516),
    'RESOLVED' => const Color(0xFF28744A),
    _ => const Color(0xFFB34339),
  };
}// Placeholder: paste the contents of mobile/lib/features/location_intelligence/map_status.dart from your app here.
