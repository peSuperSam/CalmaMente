import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class ResourceDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const ResourceDetailScreen({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppStyles.titleStyle.copyWith(color: Colors.black)),
        backgroundColor: color,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 100.0, color: color),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: AppStyles.headerStyle.copyWith(color: color),
            ),
            const SizedBox(height: 8.0),
            Text(
              description,
              style: AppStyles.bodyTextStyle.copyWith(fontSize: 18, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
