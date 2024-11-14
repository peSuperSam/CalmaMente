import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../styles/app_colors.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({Key? key}) : super(key: key);

  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _detailsController = TextEditingController();
  int _dayRating = 5;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isButtonPressed = false;
  bool _isSaving = false;
  final List<String> _emojis = ['😭', '😔', '😕', '😐', '🙂', '😊', '😁', '😃', '😆', '😍', '😎'];
  final List<String> _moodLabels = ['Horrível', 'Muito Ruim', 'Ruim', 'Ok', 'Bom', 'Muito Bom', 'Ótimo', 'Feliz', 'Animado', 'Amando', 'Incrível'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: Curves.bounceOut));
  }

  Future<void> _saveEntry() async {
    setState(() => _isSaving = true);
    if (_detailsController.text.isEmpty) {
      _showSnackbar('Por favor, detalhe mais sobre o seu dia.');
      setState(() => _isSaving = false);
      return;
    }
    final entry = {
      'rating': _dayRating,
      'details': _detailsController.text,
      'date': DateTime.now().toIso8601String(),
    };
    await DatabaseService().insertDiaryEntry(entry);
    setState(() {
      _detailsController.clear();
      _dayRating = 5;
      _isButtonPressed = false;
      _isSaving = false;
    });
    _showSnackbar('Registro salvo com sucesso.');
    HapticFeedback.lightImpact();
  }

  void _onRatingChanged(double value) {
    setState(() {
      _dayRating = value.toInt();
      _controller.forward().then((_) => _controller.reverse());
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Relatório de Emoções',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, '/diaryEntries'),
            tooltip: 'Mini Relatório Semanal',
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_isSaving)
              const CircularProgressIndicator()
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Como foi seu dia?',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColorDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildEmojiDisplay(),
                      const SizedBox(height: 10),
                      Text(
                        _moodLabels[_dayRating],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildRatingSlider(),
                      const SizedBox(height: 20),
                      _buildDetailsTextField(),
                    ],
                  ),
                ),
              ),
            _buildSaveButton(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiDisplay() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: GestureDetector(
          onTap: () {
            _controller.forward().then((_) => _controller.reverse());
            HapticFeedback.lightImpact();
          },
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _dayRating < 5
                    ? [Colors.redAccent, Colors.orange]
                    : [Colors.orange, Colors.yellowAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.orangeAccent.withOpacity(0.3), blurRadius: 16, spreadRadius: 4)
              ],
              border: Border.all(color: AppColors.accentColor, width: 3),
            ),
            child: Text(
              _emojis[_dayRating],
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSlider() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppColors.primaryColor,
        inactiveTrackColor: AppColors.primaryColorLight.withOpacity(0.3),
        thumbColor: AppColors.accentColor,
        overlayColor: AppColors.accentColor.withOpacity(0.2),
        valueIndicatorColor: AppColors.secondaryColor,
        trackHeight: 5.0,
      ),
      child: Slider(
        value: _dayRating.toDouble(),
        min: 0,
        max: 10,
        divisions: 10,
        label: _dayRating.toString(),
        onChanged: _onRatingChanged,
      ),
    );
  }

  Widget _buildDetailsTextField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.primaryColorLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        controller: _detailsController,
        decoration: InputDecoration(
          labelText: 'Compartilhe algo que te marcou hoje...',
          labelStyle: TextStyle(color: AppColors.primaryColorDark.withOpacity(0.7)),
          border: InputBorder.none,
        ),
        maxLines: null,
        maxLength: 500,
      ),
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isButtonPressed = true),
        onTapUp: (_) {
          setState(() => _isButtonPressed = false);
          _saveEntry();
        },
        child: Transform.scale(
          scale: _isButtonPressed ? 0.95 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentColor, AppColors.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))
              ],
            ),
            child: ElevatedButton(
              onPressed: _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text(
                'Salvar',
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
