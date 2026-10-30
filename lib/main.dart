import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/kartu_digital_screen.dart';
import 'screens/mutasi_screen.dart';
import 'screens/notifikasi_screen.dart';
import 'screens/blokir_rekening_screen.dart';
import 'screens/saving_goals_screen.dart';
import 'screens/badges_screen.dart';
import 'screens/session_log_screen.dart';
import 'screens/help_center_screen.dart';
import 'screens/financial_chart_screen.dart';
import 'screens/pin_authorization_screen.dart';

import 'screens/admin/admin_main_screen.dart';
import 'screens/supervisor/supervisor_main_screen.dart';
import 'screens/teller/teller_main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for Modern Institutional Banking theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const LkmBankMiniApp());
}

class LkmBankMiniApp extends StatelessWidget {
  const LkmBankMiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LKM Mitra Siswa Abadi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigation(),
        '/kartu': (context) => const KartuDigitalScreen(),
        '/mutasi': (context) => const MutasiScreen(),
        '/notifikasi': (context) => const NotifikasiScreen(),
        '/blokir': (context) => const BlokirRekeningScreen(),
        '/goals': (context) => const SavingGoalsScreen(),
        '/badges': (context) => const BadgesScreen(),
        '/session': (context) => const SessionLogScreen(),
        '/help': (context) => const HelpCenterScreen(),
        '/chart': (context) => const FinancialChartScreen(),
        '/pin_auth': (context) => const PinAuthorizationScreen(),
        '/teller': (context) => const TellerMainScreen(),
        '/supervisor': (context) => const SupervisorMainScreen(),
        '/admin': (context) => const AdminMainScreen(),
      },
    );
  }
}
