import 'package:material_ui/material_ui.dart';


/// Design tokens inspired by Claude's clean, warm, developer-focused aesthetic.
class AppColors {
  AppColors._();

  // Dark Theme Palette (Deep graphite, warm charcoal)
  static const Color darkBg = Color(0xFF18181B); // Zinc 900
  static const Color darkSidebar = Color(0xFF121215); // Deep Charcoal
  static const Color darkSurface = Color(0xFF202024); // Zinc 800
  static const Color darkElevated = Color(0xFF27272A); // Zinc 750
  static const Color darkBorder = Color(0xFF2E2E33); // Zinc 700
  static const Color darkTextPrimary = Color(0xFFF4F4F5); // Zinc 100
  static const Color darkTextSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color darkTextMuted = Color(0xFF71717A); // Zinc 500

  // Light Theme Palette (Warm paper, ivory, subtle slate)
  static const Color lightBg = Color(0xFFFAF9F6); // Warm Alabaster
  static const Color lightSidebar = Color(0xFFF3F1EC); // Soft Warm Linen
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFEBE8E1);
  static const Color lightBorder = Color(0xFFE2DFD7);
  static const Color lightTextPrimary = Color(0xFF1C1917); // Stone 900
  static const Color lightTextSecondary = Color(0xFF57534E); // Stone 600
  static const Color lightTextMuted = Color(0xFF8C867E);

  // Claude Coral / Terracotta Accent
  static const Color accentTerracotta = Color(0xFFD97706); // Warm Amber / Terracotta
  static const Color accentClaude = Color(0xFFC86544); // Claude signature terracotta
  static const Color accentCoralLight = Color(0xFFFEE2E2);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentRose = Color(0xFFF43F5E);

  // Code Block Surface (Universal Dark for Code Highlighting)
  static const Color codeBackground = Color(0xFF0F0F12);
  static const Color codeHeaderBg = Color(0xFF16161C);
  static const Color codeBorder = Color(0xFF272730);
}
