import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:crypto_analyzer/screens/api_key_screen.dart';
import 'package:crypto_analyzer/screens/symbol_selection_screen.dart';
// import 'package:crypto_analyzer/screens/analysis_result_screen.dart';
import 'package:crypto_analyzer/services/secure_storage_service.dart';
import 'package:crypto_analyzer/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // التحقق من وجود مفاتيح API مخزنة
  final secureStorage = SecureStorageService();
  final hasApiKeys = await secureStorage.hasApiKeys();
  
  runApp(MyApp(hasApiKeys: hasApiKeys));
}

class MyApp extends StatelessWidget {
  final bool hasApiKeys;
  
  const MyApp({Key? key, required this.hasApiKeys}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'محلل العملات الرقمية',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''), // العربية
        Locale('en', ''), // الإنجليزية
      ],
      locale: const Locale('ar', ''),
      debugShowCheckedModeBanner: false,
      home: hasApiKeys ? const SymbolSelectionScreen() : const ApiKeyScreen(),
    );
  }
}
