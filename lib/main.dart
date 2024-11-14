import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'supabase/supabase_config.dart';

import 'providers/mood_provider.dart';
import 'screens/InitializerScreen.dart';
import 'screens/LoginScreen.dart';
import 'screens/MenuScreen.dart';
import 'screens/RegisterScreen.dart';
import 'screens/AnxietyReportScreen.dart';
import 'screens/CommunitySupportForumScreen.dart';
import 'screens/DiaryEntriesScreen.dart';
import 'screens/DiaryScreen.dart';
import 'screens/GuidedMeditationScreen.dart';
import 'screens/ProgressTrackerScreen.dart';
import 'resource_library/ResourceLibraryScreen.dart';
import 'screens/RespirationScreen.dart';
import 'screens/SosScreen.dart';
import 'styles/app_colors.dart';
import 'styles/app_styles.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  tz.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

  try {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  } catch (e) {
    print('Falha ao inicializar notificações: $e');
  }

  if (await Permission.notification.isDenied) {
    final status = await Permission.notification.request();
    if (status.isDenied && navigatorKey.currentContext != null) {
      showDialogToRequestPermission();
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoodProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

void showDialogToRequestPermission() {
  showDialog(
    context: navigatorKey.currentContext!,
    builder: (context) => AlertDialog(
      title: const Text("Permissão de Notificação"),
      content: const Text("Para receber lembretes diários, permita notificações nas configurações do dispositivo."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Fechar"),
        ),
        TextButton(
          onPressed: () async {
            await openAppSettings();
          },
          child: const Text("Abrir Configurações"),
        ),
      ],
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'CalmaMente',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
        textTheme: TextTheme(
          titleLarge: AppStyles.titleStyle,
          bodyMedium: AppStyles.bodyTextStyle,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          titleTextStyle: AppStyles.titleStyle.copyWith(color: AppColors.textColor),
          iconTheme: const IconThemeData(color: AppColors.textColor),
        ),
        useMaterial3: true,
      ),
      home: const InitializerScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/menu': (context) => const MenuScreen(),
        '/anxietyReport': (context) => const RelatorioEmocoesScreen(),
        '/communitySupport': (context) => const CommunitySupportForumScreen(),
        '/diary': (context) => const DiaryScreen(),
        '/diaryEntries': (context) => const DiaryEntriesScreen(),
        '/guidedMeditation': (context) => GuidedMeditationScreen(),
        '/progressTracker': (context) => const ProgressTrackerScreen(),
        '/resourceLibrary': (context) => const ResourceLibraryScreen(),
        '/respiration': (context) => RespirationScreen(),
        '/sos': (context) => const SosScreen(),
      },
    );
  }
}

// Função para agendar notificação diária usando o horário selecionado pelo usuário
Future<void> scheduleDailyNotification(TimeOfDay timeOfDay) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final int? savedHour = prefs.getInt('notification_hour');
  final int? savedMinute = prefs.getInt('notification_minute');

  if (savedHour == timeOfDay.hour && savedMinute == timeOfDay.minute) {
    return; // Notificação já programada para este horário
  }

  await prefs.setInt('notification_hour', timeOfDay.hour);
  await prefs.setInt('notification_minute', timeOfDay.minute);

  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'daily_notification_channel_id',
    'Daily Notifications',
    channelDescription: 'Lembretes diários para registrar seu humor',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  final now = tz.TZDateTime.now(tz.local);
  final scheduledTime = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    timeOfDay.hour,
    timeOfDay.minute,
  );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'Lembrete Diário',
    'Não se esqueça de registrar seu humor hoje!',
    scheduledTime.isBefore(now) ? scheduledTime.add(const Duration(days: 1)) : scheduledTime,
    platformChannelSpecifics,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}
