import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

class TryOn2BuyApp extends StatelessWidget {
  const TryOn2BuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TryOn2Buy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
