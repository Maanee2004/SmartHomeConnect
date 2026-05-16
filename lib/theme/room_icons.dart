import 'package:flutter/material.dart';

/// Icône Material adaptée au nom de pièce (heuristique FR / EN).
IconData roomIconFromName(String name) {
  final n = name.toLowerCase().trim();
  final compact = n.replaceAll(RegExp(r'\s+'), ' ');

  bool has(String token) => compact.contains(token);

  if (has('salon') || has('living') || has('séjour') || has('sejour')) {
    return Icons.weekend_outlined;
  }
  if (has('chambre') || has('bedroom') || has('dortoir')) {
    return Icons.bed_outlined;
  }
  if (has('cuisine') || has('kitchen')) {
    return Icons.kitchen_outlined;
  }
  if (has('bain') || has('douche') || has('toilet') || has('wc ')) {
    return Icons.bathtub_outlined;
  }
  if (has('bureau') || has('office') || has('study')) {
    return Icons.work_outline_rounded;
  }
  if (has('garage')) {
    return Icons.directions_car_outlined;
  }
  if (has('entrée') || has('entree') || has('hall') || has('vestibule')) {
    return Icons.door_front_door_outlined;
  }
  if (has('couloir') || has('corridor')) {
    return Icons.view_week_outlined;
  }
  if (has('dressing') || has('placard')) {
    return Icons.checkroom_outlined;
  }
  if (has('buanderie') || has('linge') || has('laundry')) {
    return Icons.local_laundry_service_outlined;
  }
  if (has('terrasse') || has('balcon') || has('balcony') || has('deck')) {
    return Icons.deck_outlined;
  }
  if (has('jardin') || has('garden') || has('extérieur') || has('exterieur')) {
    return Icons.yard_outlined;
  }
  if (has('cave') || has('cellar') || has('sous-sol')) {
    return Icons.inventory_2_outlined;
  }
  if (has('atelier') || has('workshop')) {
    return Icons.build_outlined;
  }
  if (has('enfant') || has('bébé') || has('bebe') || has('nursery')) {
    return Icons.child_friendly_outlined;
  }

  return Icons.meeting_room_outlined;
}
