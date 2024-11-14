// lib/styles/app_styles.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  static const TextStyle titleStyle = TextStyle(
    color: AppColors.primaryColor,
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: Colors.grey,
    fontSize: 13,
  );

  static const TextStyle labelStyle = TextStyle(
    color: Colors.white70,
    fontSize: 14,
  );

  static const TextStyle headerStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle smallTextStyle = TextStyle(
    color: Colors.white70,
    fontSize: 14,
  );

  static const TextStyle linkTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    decoration: TextDecoration.underline,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryColor,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.black,
    height: 1.5,
  );

  static const TextStyle statisticValueStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.cardBackground,
  );

  static const TextStyle tooltipTextStyle = TextStyle(
    color: Colors.black,
    fontSize: 12,
  );

  static const TextStyle axisTextStyle = TextStyle(
    fontSize: 10,
    color: AppColors.primaryColor,
  );

  static const TextStyle heatMapTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 10,
  );

  static const TextStyle emojiStyle = TextStyle(
    fontSize: 30,
  );

  static const TextStyle descriptionTextStyle = TextStyle(
    fontSize: 14,
    color: Colors.blueGrey,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle highlightedTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.secondaryColor,
  );

  // Novo estilo para subtítulos que não estava definido
  static const TextStyle subtitleTextStyle = TextStyle(
    fontSize: 14,
    color: AppColors.primaryColorLight,
  );
}
