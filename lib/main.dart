// import 'package:flutter/material.dart';
// import 'package:konek2move/services/provider_services.dart';
// import 'package:konek2move/ui/splash_page/splash_screen.dart';
// import 'package:konek2move/utils/internet_connection.dart';
// import 'package:provider/provider.dart';
//
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   // await NetworkNotificationService.init();
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       navigatorKey: navigatorKey,
//       title: 'Konek2Move',
//       theme: ThemeData(
//         useMaterial3: true,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.white,
//           brightness: Brightness.light,
//         ),
//       ),
//       home: const SplashScreen(),
//
//       builder: (context, child) {
//         return InternetDialogListener(child: child!);
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:konek2move/services/provider_services.dart';
import 'package:konek2move/ui/splash_page/splash_screen.dart';
import 'package:konek2move/utils/internet_connection.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Konek2Move',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),

      builder: (context, child) {
        return Banner(
          message: 'BETA NGA NI!',
          location: BannerLocation.bottomEnd,
          color: Colors.green.withOpacity(0.6),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 8,
            letterSpacing: 1,
          ),
          child: InternetDialogListener(child: child!),
        );
      },
    );
  }
}
