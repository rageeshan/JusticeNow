import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Incident Category Definitions
// ─────────────────────────────────────────────────────────────────────────────

class IncidentCategory {
  final String id;
  final String label;
  final String description;
  final IconData icon;

  const IncidentCategory({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const List<IncidentCategory> kIncidentCategories = [
  IncidentCategory(
    id: 'police_brutality',
    label: 'Police Brutality',
    description: 'Excessive force or abuse by law enforcement',
    icon: Icons.shield_outlined,
  ),
  IncidentCategory(
    id: 'arbitrary_detention',
    label: 'Unlawful Detention',
    description: 'Arrest or detention without proper legal process',
    icon: Icons.lock_outline,
  ),
  IncidentCategory(
    id: 'forced_displacement',
    label: 'Forced Displacement',
    description: 'Forced removal or eviction from home or community',
    icon: Icons.home_outlined,
  ),
  IncidentCategory(
    id: 'freedom_of_expression',
    label: 'Freedom of Expression',
    description: 'Suppression of speech, press, or peaceful protest',
    icon: Icons.campaign_outlined,
  ),
  IncidentCategory(
    id: 'gender_based_violence',
    label: 'Gender-Based Violence',
    description: 'Harassment, assault, or discrimination based on gender',
    icon: Icons.favorite_outline,
  ),
  IncidentCategory(
    id: 'labor_rights',
    label: 'Labour Rights Violation',
    description: 'Exploitation or unsafe conditions at work',
    icon: Icons.work_outline,
  ),
  IncidentCategory(
    id: 'discrimination',
    label: 'Discrimination',
    description: 'Unfair treatment based on race, religion, or ethnicity',
    icon: Icons.people_outline,
  ),
  IncidentCategory(
    id: 'other',
    label: 'Other Violation',
    description: 'Any other human rights concern not listed above',
    icon: Icons.help_outline,
  ),
];
