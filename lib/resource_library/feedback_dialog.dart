import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../styles/app_colors.dart';

class FeedbackDialog extends StatefulWidget {
  @override
  _FeedbackDialogState createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> with SingleTickerProviderStateMixin {
  String feedbackText = '';
  bool isSubmitting = false;
  final int maxFeedbackLength = 300; // Aumentado para 300 caracteres
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (feedbackText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, insira seu feedback.')),
      );
      return;
    }

    setState(() => isSubmitting = true);
    await Future.delayed(Duration(seconds: 2));
    setState(() => isSubmitting = false);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feedback enviado com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = feedbackText.length / maxFeedbackLength;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
              child: Icon(Icons.feedback, color: AppColors.primaryColor, size: 40),
            ),
            const SizedBox(height: 8),
            Text(
              "Envie seu Feedback",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.black87,
                shadows: [Shadow(color: Colors.grey, blurRadius: 2)],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Ajude-nos a melhorar o aplicativo com sua opinião.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: "Escreva seu feedback...",
                filled: true,
                fillColor: Colors.grey[200]?.withOpacity(0.8),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 4,
              maxLength: maxFeedbackLength,
              onChanged: (text) => setState(() => feedbackText = text),
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  height: 4,
                  width: MediaQuery.of(context).size.width * 0.6 * progress,
                  decoration: BoxDecoration(
                    color: progress >= 1.0 ? Colors.redAccent : AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${feedbackText.length}/$maxFeedbackLength",
                style: TextStyle(
                  color: feedbackText.length >= maxFeedbackLength * 0.8
                      ? Colors.red
                      : Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                  child: const Text("Cancelar"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shadowColor: Colors.black45,
                    elevation: 3,
                  ),
                  onPressed: isSubmitting ? null : _submitFeedback,
                  child: isSubmitting
                      ? SpinKitThreeBounce(
                          color: Colors.white,
                          size: 18,
                        )
                      : Text(
                          "Enviar",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
