import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calmamente/styles/app_colors.dart'; // Importa as cores centralizadas
import 'package:calmamente/styles/app_styles.dart'; // Importa os estilos centralizados
import 'NotificationSettingsScreen.dart';
import 'AccountSettingsScreen.dart';
import 'PrivacySettingsScreen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsOptions = [
      SettingsOption(
        icon: Icons.notifications,
        title: "Configurações de Notificação",
        subtitle: "Gerencie seus lembretes diários",
        screen: const NotificationSettingsScreen(),
      ),
      SettingsOption(
        icon: Icons.person,
        title: "Configurações de Conta",
        subtitle: "Atualize suas informações de perfil",
        screen: const AccountSettingsScreen(),
      ),
      SettingsOption(
        icon: Icons.lock,
        title: "Configurações de Privacidade",
        subtitle: "Controle suas preferências de privacidade",
        screen: const PrivacySettingsScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: const Text(
          'Configurações',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: settingsOptions.length,
        itemBuilder: (context, index) {
          final option = settingsOptions[index];
          return SettingsOptionTile(option: option);
        },
      ),
    );
  }
}

class SettingsOptionTile extends StatelessWidget {
  final SettingsOption option;

  const SettingsOptionTile({Key? key, required this.option}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => option.screen,
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(option.icon, color: AppColors.primaryColor),
          title: Text(option.title, style: AppStyles.titleStyle),
          subtitle: option.subtitle != null
              ? Text(option.subtitle!, style: AppStyles.subtitleStyle)
              : null,
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}

class SettingsOption {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget screen;

  SettingsOption({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.screen,
  });
}
