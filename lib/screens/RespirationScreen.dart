import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../styles/app_colors.dart'; // Importando cores do aplicativo
import '../styles/app_styles.dart'; // Importando estilos do aplicativo

class RespirationScreen extends StatefulWidget {
  const RespirationScreen({Key? key}) : super(key: key);

  @override
  _RespirationScreenState createState() => _RespirationScreenState();
}

class _RespirationScreenState extends State<RespirationScreen> with TickerProviderStateMixin {
  int inhaleTime = 5;
  int holdTime = 5;
  int exhaleTime = 4;
  bool isBreathing = false;
  String currentStep = 'Pronto para começar?';

  late AnimationController _animationController;
  late Animation<double> _animation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: inhaleTime))
      ..addListener(() {
        setState(() {});
      });
    _animation = Tween<double>(begin: 150, end: 200).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _colorAnimation = ColorTween(
      begin: Colors.orange[200],
      end: Colors.orange[400],
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Exercícios de Respiração',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor, // Usando cor do AppColors
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                AnimatedOpacity(
                  opacity: isBreathing ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 600),
                  child: const Text(
                    'Pronto para começar?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF042434),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    if (!isBreathing) _startBreathingCycle();
                  },
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        height: _animation.value,
                        width: _animation.value,
                        decoration: BoxDecoration(
                          color: _colorAnimation.value,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 15,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isBreathing ? currentStep : '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Inspire: $inhaleTime seg | Segure: $holdTime seg | Expire: $exhaleTime seg',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF5a434b),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (!isBreathing) _startBreathingCycle();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryColor, // Usando cor do AppColors
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isBreathing ? 'Respirando...' : 'Iniciar Respiração',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Configurações de Respiração',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF042434),
                  ),
                ),
                const SizedBox(height: 10),
                _buildBreathControlRow('Inalar', inhaleTime, (val) {
                  setState(() => inhaleTime = val);
                }),
                _buildBreathControlRow('Segurar', holdTime, (val) {
                  setState(() => holdTime = val);
                }),
                _buildBreathControlRow('Exalar', exhaleTime, (val) {
                  setState(() => exhaleTime = val);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathControlRow(String label, int time, Function(int) onUpdate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () {
              if (time > 1) onUpdate(time - 1);
            },
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryColor), // Usando cor do AppColors
          ),
          Text('$time s', style: const TextStyle(fontSize: 16)),
          IconButton(
            onPressed: () {
              if (time < 10) onUpdate(time + 1);
            },
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryColor), // Usando cor do AppColors
          ),
        ],
      ),
    );
  }

  void _startBreathingCycle() async {
    setState(() {
      isBreathing = true;
      currentStep = 'Inspire';
      _animationController.duration = Duration(seconds: inhaleTime);
      _animationController.forward(from: 0);
    });
    await Future.delayed(Duration(seconds: inhaleTime));
    setState(() {
      currentStep = 'Segure';
      _animationController.duration = Duration(seconds: holdTime);
      _animationController.value = 1.0;
    });
    await Future.delayed(Duration(seconds: holdTime));
    setState(() {
      currentStep = 'Expire';
      _animationController.duration = Duration(seconds: exhaleTime);
      _animationController.reverse();
    });
    await Future.delayed(Duration(seconds: exhaleTime));
    setState(() {
      isBreathing = false;
      currentStep = 'Pronto para começar?';
    });
  }
}
