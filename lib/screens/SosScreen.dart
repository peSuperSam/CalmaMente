import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calmamente/styles/app_colors.dart';
import 'package:calmamente/styles/app_styles.dart';
import 'dart:convert';

class SosScreen extends StatefulWidget {
  const SosScreen({Key? key}) : super(key: key);

  @override
  _SosScreenState createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  double _progress = 0.0;
  int _sessionTime = 5;
  List<String> _supportMessages = [
    "Respire fundo, tudo vai ficar bem.",
    "Você é mais forte do que pensa.",
    "A calma está ao seu alcance.",
    "Você vai superar isso.",
  ];
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer.positionStream.listen((position) {
      final totalDuration = _audioPlayer.duration ?? Duration.zero;
      if (totalDuration.inMilliseconds > 0) {
        setState(() {
          _progress = position.inMilliseconds / totalDuration.inMilliseconds;
        });
      }
    });
    _loadMessages();
    _showCrisisAlertDialog();
    _showSupportMessages();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getStringList('supportMessages');
    if (savedMessages != null) {
      setState(() {
        _supportMessages = savedMessages;
      });
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('supportMessages', _supportMessages);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String filePath) async {
    try {
      await _audioPlayer.setAsset(filePath);
      _audioPlayer.play();
      setState(() => _isPlaying = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao reproduzir áudio: $e')),
      );
    }
  }

  void _pauseAudio() {
    _audioPlayer.pause();
    setState(() => _isPlaying = false);
  }

  void _stopAudio() {
    _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _progress = 0.0;
    });
  }

  void _showSupportMessages() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _supportMessages.length;
        });
        _showSupportMessages();
      }
    });
  }

  void _showCrisisAlertDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Avisar sobre crise?"),
          content: const Text("Deseja avisar alguém sobre sua crise?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Não"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendCrisisAlert();
              },
              child: const Text("Sim"),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _sendCrisisAlert() async {
    String message = Uri.encodeComponent("Estou passando por uma crise e preciso de ajuda.");
    String url = "https://wa.me/?text=$message";

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível abrir o WhatsApp")),
      );
    }
  }

  void _addNewMessage() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text("Adicionar Mensagem"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Digite sua mensagem"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _supportMessages.add(controller.text);
                  _saveMessages();
                });
                Navigator.of(context).pop();
              },
              child: const Text("Adicionar"),
            ),
          ],
        );
      },
    );
  }

  void _editMessage(int index) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController(text: _supportMessages[index]);
        return AlertDialog(
          title: const Text("Editar Mensagem"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Editar mensagem"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _supportMessages[index] = controller.text;
                  _saveMessages();
                });
                Navigator.of(context).pop();
              },
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }

  void _deleteMessage(int index) {
    setState(() {
      _supportMessages.removeAt(index);
      _saveMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Modo SOS',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewMessage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Modo SOS Ativo",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF042434),
              ),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _supportMessages.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                  _supportMessages[index],
                  style: const TextStyle(color: Color(0xFF5a434b), fontSize: 18),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF1d7c8d)),
                      onPressed: () => _editMessage(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteMessage(index),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                CircularPercentIndicator(
                  radius: 120.0,
                  lineWidth: 12.0,
                  percent: _progress,
                  center: const Icon(
                    Icons.spa,
                    color: Color(0xFF35a5ab),
                    size: 50,
                  ),
                  backgroundColor: Colors.grey.shade300,
                  progressColor: const Color(0xFF35a5ab),
                  animation: true,
                  animateFromLastPercent: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _audioPlayer.duration != null
                  ? '${_audioPlayer.position.inMinutes.toString().padLeft(2, '0')}:${(_audioPlayer.position.inSeconds % 60).toString().padLeft(2, '0')} / ${_audioPlayer.duration!.inMinutes.toString().padLeft(2, '0')}:${(_audioPlayer.duration!.inSeconds % 60).toString().padLeft(2, '0')}'
                  : '00:00 / --:--',
              style: const TextStyle(color: Color(0xFF5a434b)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.play_arrow,
                  onPressed: _isPlaying
                      ? null
                      : () => _playAudio('lib/assets/audios/breathing1112min.mp3'),
                  color: const Color(0xFF35a5ab),
                ),
                _buildControlButton(
                  icon: Icons.pause,
                  onPressed: _isPlaying ? _pauseAudio : null,
                  color: _isPlaying ? const Color(0xFFE1766B) : Colors.grey.shade400,
                ),
                _buildControlButton(
                  icon: Icons.stop,
                  onPressed: _isPlaying ? _stopAudio : null,
                  color: _isPlaying ? const Color(0xFF5A434B) : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Escolha o Tempo de Sessão:',
              style: TextStyle(color: Color(0xFF042434)),
            ),
            DropdownButton<int>(
              value: _sessionTime,
              items: [3, 5, 10].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text("$value minutos"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _sessionTime = value ?? 5);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
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
}
