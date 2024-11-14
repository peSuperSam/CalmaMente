import 'package:flutter/material.dart';

class MoodProvider extends ChangeNotifier {
  int userMood = 5;

  String getSuggestion() {
    if (userMood <= 3) return 'Respiração Profunda';
    if (userMood <= 6) return 'Meditação Mindfulness';
    return 'Prática de Gratidão';
  }

  void updateMood(int mood) {
    userMood = mood;
    notifyListeners();
  }
}
