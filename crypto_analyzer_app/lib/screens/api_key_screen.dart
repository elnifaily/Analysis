import 'package:flutter/material.dart';
import 'package:crypto_analyzer/services/secure_storage_service.dart';
import 'package:crypto_analyzer/services/binance_api_service.dart';
import 'package:crypto_analyzer/screens/symbol_selection_screen.dart';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({Key? key}) : super(key: key);

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';
  
  final _secureStorage = SecureStorageService();
  
  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    super.dispose();
  }
  
  Future<void> _validateAndSaveApiKeys() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final apiKey = _apiKeyController.text.trim();
      final apiSecret = _apiSecretController.text.trim();
      
      // التحقق من صحة المفاتيح
      final binanceService = BinanceApiService(
        apiKey: apiKey,
        apiSecret: apiSecret,
      );
      
      final isValid = await binanceService.validateCredentials();
      
      if (isValid) {
        // حفظ المفاتيح في التخزين الآمن
        await _secureStorage.saveApiKeys(apiKey, apiSecret);
        
        if (mounted) {
          // الانتقال إلى شاشة اختيار العملة
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const SymbolSelectionScreen(),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'مفاتيح API غير صالحة. يرجى التحقق والمحاولة مرة أخرى.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد مفاتيح API'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // شعار التطبيق أو أيقونة
              Icon(
                Icons.security,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              
              const SizedBox(height: 20),
              
              // عنوان الشاشة
              Text(
                'أدخل مفاتيح API الخاصة ببينانس',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 10),
              
              // وصف
              Text(
                'سيتم تخزين المفاتيح بشكل آمن على جهازك ولن يتم مشاركتها مع أي خادم خارجي.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 30),
              
              // حقل API Key
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'أدخل API Key الخاص بك',
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال API Key';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // حقل API Secret
              TextFormField(
                controller: _apiSecretController,
                decoration: const InputDecoration(
                  labelText: 'API Secret',
                  hintText: 'أدخل API Secret الخاص بك',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال API Secret';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // رسالة الخطأ
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // زر التحقق
              ElevatedButton(
                onPressed: _isLoading ? null : _validateAndSaveApiKeys,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('التحقق وحفظ المفاتيح'),
              ),
              
              const SizedBox(height: 16),
              
              // معلومات إضافية
              const Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'للحصول على مفاتيح API، قم بزيارة إعدادات حسابك في منصة بينانس وإنشاء مفاتيح API جديدة مع صلاحيات القراءة فقط.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
