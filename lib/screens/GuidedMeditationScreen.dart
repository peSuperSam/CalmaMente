import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../styles/app_colors.dart';
import '../styles/app_styles.dart';

class GuidedMeditationScreen extends StatefulWidget {
  const GuidedMeditationScreen({Key? key}) : super(key: key);

  @override
  _GuidedMeditationScreenState createState() => _GuidedMeditationScreenState();
}

class _GuidedMeditationScreenState extends State<GuidedMeditationScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _selectedMeditation;
  bool _isPlaying = false, _isRepeating = false;
  double _progress = 0.0;
  Duration? _audioDuration;

  final Map<String, String> _meditationFiles = {
    'Respiração': 'lib/assets/audios/breathing1112min.mp3',
    'Sono': 'lib/assets/audios/sleep12min.mp3',
    'Gratidão': 'lib/assets/audios/gratitude6min.mp3',
  };

  @override
  void initState() {
    super.initState();
    _audioPlayer.positionStream.listen((position) {
      if (_audioDuration != null && _audioDuration!.inMilliseconds > 0) {
        setState(() => _progress = position.inMilliseconds / _audioDuration!.inMilliseconds);
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      setState(() => _isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String filePath) async {
    try {
      await _audioPlayer.setAsset(filePath);
      _audioDuration = await _audioPlayer.load(); // Obter a duração ao carregar
      _audioPlayer.setLoopMode(_isRepeating ? LoopMode.one : LoopMode.off);
      await _audioPlayer.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao reproduzir áudio: $e')),
      );
    }
  }

  void _pauseAudio() async => await _audioPlayer.pause();

  void _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _progress = 0.0;
    });
  }

  void _onMeditationSelected(String? value) {
    if (_isPlaying) {
      _stopAudio(); // Parar o áudio atual ao escolher uma nova meditação
    }
    setState(() {
      _selectedMeditation = value;
      _progress = 0.0;
      _audioDuration = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mindfulness e Meditação Guiada',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Selecione uma Meditação',
              style: AppStyles.titleStyle,
            ),
            const SizedBox(height: 10),
            const Text(
              'Escolha uma meditação guiada para iniciar seu momento de relaxamento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.shadowColor),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedMeditation,
              hint: const Text('Escolha a meditação'),
              items: _meditationFiles.keys.map((String key) {
                return DropdownMenuItem(value: key, child: Text(key));
              }).toList(),
              onChanged: _onMeditationSelected,
            ),
            const SizedBox(height: 30),
            if (_selectedMeditation != null) _buildMeditationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildMeditationControls() {
    return AnimatedOpacity(
      opacity: _selectedMeditation != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircularPercentIndicator(
                radius: 120.0,
                lineWidth: 12.0,
                percent: _progress,
                center: Text(
                  '${(_progress * 100).toInt()}%',
                  style: AppStyles.statisticValueStyle,
                ),
                backgroundColor: Colors.grey.shade300,
                progressColor: AppColors.secondaryColor,
                animation: true,
                animateFromLastPercent: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _audioDuration != null
                ? '${_audioPlayer.position.inMinutes.toString().padLeft(2, '0')}:${(_audioPlayer.position.inSeconds % 60).toString().padLeft(2, '0')} / ${_audioDuration!.inMinutes.toString().padLeft(2, '0')}:${(_audioDuration!.inSeconds % 60).toString().padLeft(2, '0')}'
                : '00:00 / --:--',
            style: const TextStyle(color: AppColors.shadowColor),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.play_arrow,
                onPressed: _isPlaying
                    ? null
                    : () => _playAudio(_meditationFiles[_selectedMeditation]!),
                color: AppColors.secondaryColor,
              ),
              _buildControlButton(
                icon: Icons.pause,
                onPressed: _isPlaying ? _pauseAudio : null,
                color: _isPlaying ? AppColors.cardBackground : Colors.grey.shade400,
              ),
              _buildControlButton(
                icon: Icons.stop,
                onPressed: _isPlaying ? _stopAudio : null,
                color: _isPlaying ? AppColors.shadowColor : Colors.grey.shade400,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSwitchControl(
                'Repetir:',
                _isRepeating,
                (value) {
                  setState(() => _isRepeating = value);
                  _audioPlayer.setLoopMode(value ? LoopMode.one : LoopMode.off);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color color = AppColors.secondaryColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(20),
        backgroundColor: color,
      ),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }

  Widget _buildSwitchControl(String label, bool value, ValueChanged<bool> onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.shadowColor)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.secondaryColor,
        ),
      ],
    );
  }
}
