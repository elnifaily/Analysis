import 'package:flutter/material.dart';
import 'package:crypto_analyzer/services/secure_storage_service.dart';
import 'package:crypto_analyzer/services/binance_api_service.dart';
import 'package:crypto_analyzer/screens/analysis_result_screen.dart';
import 'package:crypto_analyzer/screens/api_key_screen.dart';

class SymbolSelectionScreen extends StatefulWidget {
  const SymbolSelectionScreen({Key? key}) : super(key: key);

  @override
  State<SymbolSelectionScreen> createState() => _SymbolSelectionScreenState();
}

class _SymbolSelectionScreenState extends State<SymbolSelectionScreen> {
  final _secureStorage = SecureStorageService();
  late BinanceApiService _binanceService;
  
  List<String> _symbols = [];
  String? _selectedSymbol;
  bool _isLoading = true;
  String _errorMessage = '';
  
  TextEditingController _searchController = TextEditingController();
  List<String> _filteredSymbols = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAndLoadSymbols();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeAndLoadSymbols() async {
    try {
      final apiKey = await _secureStorage.getApiKey();
      final apiSecret = await _secureStorage.getApiSecret();
      
      if (apiKey == null || apiSecret == null) {
        // إذا لم تكن المفاتيح موجودة، انتقل إلى شاشة إدخال المفاتيح
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ApiKeyScreen(),
            ),
          );
        }
        return;
      }
      
      _binanceService = BinanceApiService(
        apiKey: apiKey,
        apiSecret: apiSecret,
      );
      
      await _loadSymbols();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ: ${e.toString()}';
      });
    }
  }
  
  Future<void> _loadSymbols() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final symbols = await _binanceService.getAvailableSymbols();
      
      setState(() {
        _symbols = symbols;
        _filteredSymbols = symbols;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'فشل في جلب قائمة العملات: ${e.toString()}';
      });
    }
  }
  
  void _filterSymbols(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSymbols = _symbols;
      } else {
        _filteredSymbols = _symbols
            .where((symbol) => symbol.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
  
  Future<void> _analyzeSymbol() async {
    if (_selectedSymbol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار عملة أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // الانتقال إلى شاشة التحليل
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnalysisResultScreen(
          symbol: _selectedSymbol!,
          binanceService: _binanceService,
        ),
      ),
    );
  }
  
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج وحذف مفاتيح API؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      await _secureStorage.deleteApiKeys();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ApiKeyScreen(),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار العملة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSymbols,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // حقل البحث
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'بحث',
                          hintText: 'ابحث عن عملة...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _filterSymbols,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // عدد العملات المتاحة
                      Text(
                        'العملات المتاحة: ${_filteredSymbols.length}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // قائمة العملات
                      Expanded(
                        child: _filteredSymbols.isEmpty
                            ? const Center(
                                child: Text('لا توجد عملات مطابقة للبحث'),
                              )
                            : ListView.builder(
                                itemCount: _filteredSymbols.length,
                                itemBuilder: (context, index) {
                                  final symbol = _filteredSymbols[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: RadioListTile<String>(
                                      title: Text(symbol),
                                      value: symbol,
                                      groupValue: _selectedSymbol,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedSymbol = value;
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // زر التحليل
                      ElevatedButton(
                        onPressed: _selectedSymbol != null ? _analyzeSymbol : null,
                        child: const Text('تحليل العملة'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
