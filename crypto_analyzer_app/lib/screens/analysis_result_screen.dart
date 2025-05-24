import 'package:flutter/material.dart';
import 'package:crypto_analyzer/services/binance_api_service.dart';
import 'package:crypto_analyzer/services/technical_analysis_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalysisResultScreen extends StatefulWidget {
  final String symbol;
  final BinanceApiService binanceService;

  const AnalysisResultScreen({
    Key? key,
    required this.symbol,
    required this.binanceService,
  }) : super(key: key);

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  final TechnicalAnalysisService _analysisService = TechnicalAnalysisService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _analysisResult;
  
  // بيانات الرسم البياني
  List<FlSpot> _priceSpots = [];
  List<FlSpot> _smaSpots = [];
  double _minY = 0;
  double _maxY = 0;
  
  @override
  void initState() {
    super.initState();
    _loadAndAnalyzeData();
  }
  
  Future<void> _loadAndAnalyzeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      // جلب بيانات الشموع اليابانية للإطارات الزمنية المختلفة
      // Limit the number of klines to avoid excessive data processing
      final klines1h = await widget.binanceService.getKlines(widget.symbol, '1h', '100'); // ~4 days
      final klines4h = await widget.binanceService.getKlines(widget.symbol, '4h', '100'); // ~16 days
      final klines1d = await widget.binanceService.getKlines(widget.symbol, '1d', '100'); // ~3 months
      
      // جلب السعر الحالي
      final currentPrice = await widget.binanceService.getCurrentPrice(widget.symbol);
      
      // استخراج أسعار الإغلاق
      final prices1h = _extractClosePrices(klines1h['data']);
      final prices4h = _extractClosePrices(klines4h['data']);
      final prices1d = _extractClosePrices(klines1d['data']);

      // --- حساب المؤشرات الفنية --- 
      // Helper function to safely get the last non-null value or null
      T? _getLast<T>(List<T?> list) => list.lastWhere((e) => e != null, orElse: () => null);

      // 1 Hour Indicators
      final sma201h = _getLast(_analysisService.calculateSMA(prices1h, 20));
      final sma501h = _getLast(_analysisService.calculateSMA(prices1h, 50));
      final ema121h = _getLast(_analysisService.calculateEMA(prices1h, 12));
      final ema261h = _getLast(_analysisService.calculateEMA(prices1h, 26));
      final rsi1h = _getLast(_analysisService.calculateRSI(prices1h, 14));
      final macdResult1h = _analysisService.calculateMACD(prices1h);
      final macd1h = _getLast(macdResult1h['macd'] ?? []); 
      final macdSignal1h = _getLast(macdResult1h['signal'] ?? []);

      // 4 Hour Indicators
      final sma204h = _getLast(_analysisService.calculateSMA(prices4h, 20));
      final sma504h = _getLast(_analysisService.calculateSMA(prices4h, 50));
      final ema124h = _getLast(_analysisService.calculateEMA(prices4h, 12));
      final ema264h = _getLast(_analysisService.calculateEMA(prices4h, 26));
      final rsi4h = _getLast(_analysisService.calculateRSI(prices4h, 14));
      final macdResult4h = _analysisService.calculateMACD(prices4h);
      final macd4h = _getLast(macdResult4h['macd'] ?? []);
      final macdSignal4h = _getLast(macdResult4h['signal'] ?? []);

      // 1 Day Indicators
      final sma201d = _getLast(_analysisService.calculateSMA(prices1d, 20));
      final sma501d = _getLast(_analysisService.calculateSMA(prices1d, 50));
      final ema121d = _getLast(_analysisService.calculateEMA(prices1d, 12));
      final ema261d = _getLast(_analysisService.calculateEMA(prices1d, 26));
      final rsi1d = _getLast(_analysisService.calculateRSI(prices1d, 14));
      final macdResult1d = _analysisService.calculateMACD(prices1d);
      final macd1d = _getLast(macdResult1d['macd'] ?? []);
      final macdSignal1d = _getLast(macdResult1d['signal'] ?? []);
      
      // --- تحليل الاتجاه لكل إطار زمني (Using Named Parameters & Type Casting) ---
      final analysis1h = _analysisService.analyzeTrend(
        currentPrice: currentPrice,
        sma20: sma201h,
        sma50: sma501h,
        ema12: ema121h,
        ema26: ema261h,
        rsi: rsi1h,
        macd: macd1h as double?, // Fix: Cast to double?
        macdSignal: macdSignal1h as double?, // Fix: Cast to double?
      );
      
      final analysis4h = _analysisService.analyzeTrend(
        currentPrice: currentPrice,
        sma20: sma204h,
        sma50: sma504h,
        ema12: ema124h,
        ema26: ema264h,
        rsi: rsi4h,
        macd: macd4h as double?, // Fix: Cast to double?
        macdSignal: macdSignal4h as double?, // Fix: Cast to double?
      );
      
      final analysis1d = _analysisService.analyzeTrend(
        currentPrice: currentPrice,
        sma20: sma201d,
        sma50: sma501d,
        ema12: ema121d,
        ema26: ema261d,
        rsi: rsi1d,
        macd: macd1d as double?, // Fix: Cast to double?
        macdSignal: macdSignal1d as double?, // Fix: Cast to double?
      );
      
      // --- التحليل الكامل (Using Named Parameters) ---
      final completeAnalysis = _analysisService.completeAnalysis(
        symbol: widget.symbol, // Pass symbol here
        analysis1h: analysis1h,
        analysis4h: analysis4h,
        analysis1d: analysis1d,
        currentPrice: currentPrice,
      );
      
      // إعداد بيانات الرسم البياني (Using daily data for chart)
      _prepareChartData(prices1d, _analysisService.calculateSMA(prices1d, 20));
      
      setState(() {
        _analysisResult = completeAnalysis;
        _isLoading = false;
      });
    } catch (e, stacktrace) { // Catch stacktrace for better debugging
      print('Error loading/analyzing data: $e');
      print('Stacktrace: $stacktrace');
      setState(() {
        _isLoading = false;
        _errorMessage = 'فشل في تحليل العملة: ${e.toString()}';
      });
    }
  }
  
  List<double> _extractClosePrices(List<dynamic> klines) {
    // Ensure klines is a list and candles are maps with 'close'
    return klines
        .where((candle) => candle is Map && candle.containsKey('close'))
        .map<double>((candle) => double.tryParse(candle['close'].toString()) ?? 0.0)
        .toList();
  }
  
  void _prepareChartData(List<double> prices, List<double?> smaValues) {
    _priceSpots = [];
    _smaSpots = [];
    
    if (prices.isEmpty) return; // Handle empty price list

    for (int i = 0; i < prices.length; i++) {
      _priceSpots.add(FlSpot(i.toDouble(), prices[i]));
      
      // Ensure smaValues index is valid and value is not null
      if (i < smaValues.length && smaValues[i] != null) {
        _smaSpots.add(FlSpot(i.toDouble(), smaValues[i]!));
      }
    }
    
    // Calculate min/max only if spots were added
    if (_priceSpots.isNotEmpty) {
      double minPrice = _priceSpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      double maxPrice = _priceSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      _minY = minPrice * 0.99; // Adjust padding slightly
      _maxY = maxPrice * 1.01;
    } else {
      _minY = 0;
      _maxY = 1;
    }
  }
  
  Color _getTrendColor(String trend) {
    final appTheme = Theme.of(context).extension<AppTheme>();
    switch (trend) {
      case 'صاعد':
        return appTheme?.upTrendColor ?? Colors.green;
      case 'هابط':
        return appTheme?.downTrendColor ?? Colors.red;
      default:
        return appTheme?.neutralTrendColor ?? Colors.amber;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تحليل ${widget.symbol}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                          onPressed: _loadAndAnalyzeData,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildAnalysisContent(),
    );
  }
  
  Widget _buildAnalysisContent() {
    if (_analysisResult == null) {
      return const Center(child: Text('لا توجد بيانات للتحليل'));
    }
    
    // Safely access nested map values
    final currentPrice = _analysisResult!['current_price'] as double? ?? 0.0;
    final trend = _analysisResult!['trend'] as String? ?? 'محايد';
    final timeframe = _analysisResult!['timeframe'] as String? ?? 'غير محدد';
    final analysisMap = _analysisResult!['analysis'] as Map<String, dynamic>? ?? {};
    final analysis1h = analysisMap['1h'] as Map<String, dynamic>? ?? {};
    final analysis4h = analysisMap['4h'] as Map<String, dynamic>? ?? {};
    final analysis1d = analysisMap['1d'] as Map<String, dynamic>? ?? {};
    final indicators1d = (analysis1d['indicators'] as Map<String, dynamic>?) ?? {};
    final details1d = (analysis1d['details'] as Map<String, dynamic>?) ?? {};

    // Format timestamp safely
    String formattedTimestamp = 'غير متاح';
    try {
      if (_analysisResult!['timestamp'] != null) {
        formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(_analysisResult!['timestamp']));
      }
    } catch (_) { /* Ignore formatting errors */ }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // بطاقة الملخص
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'السعر الحالي',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    // Extract currency from symbol if possible, default to USDT
                    '${currentPrice.toStringAsFixed(widget.symbol.endsWith('BTC') ? 8 : 4)} ${widget.symbol.substring(widget.symbol.length - (widget.symbol.endsWith('USDT') ? 4 : 3))}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('الاتجاه المتوقع: '),
                      Text(
                        trend,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getTrendColor(trend),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الإطار الزمني: $timeframe',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // الرسم البياني
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الرسم البياني (يومي)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _priceSpots.isEmpty
                        ? const Center(child: Text('لا توجد بيانات كافية للرسم البياني'))
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Consider adding date labels later
                              ),
                              borderData: FlBorderData(show: true),
                              minX: 0,
                              maxX: _priceSpots.length.toDouble() - 1,
                              minY: _minY,
                              maxY: _maxY,
                              lineBarsData: [
                                // خط السعر
                                LineChartBarData(
                                  spots: _priceSpots,
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 2,
                                  dotData: FlDotData(show: false),
                                ),
                                // خط المتوسط المتحرك
                                if (_smaSpots.isNotEmpty) // Only show SMA line if data exists
                                  LineChartBarData(
                                    spots: _smaSpots,
                                    isCurved: true,
                                    color: Colors.red,
                                    barWidth: 2,
                                    dotData: FlDotData(show: false),
                                  ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 12, height: 12, color: Colors.blue),
                      const SizedBox(width: 4), const Text('السعر'),
                      if (_smaSpots.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Container(width: 12, height: 12, color: Colors.red),
                        const SizedBox(width: 4), const Text('SMA 20'),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // تفاصيل المؤشرات
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل المؤشرات (يومي)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildIndicatorRow(
                    'SMA (20)',
                    (indicators1d['sma_20'] as double?)?.toStringAsFixed(4) ?? 'N/A',
                    'SMA (50)',
                    (indicators1d['sma_50'] as double?)?.toStringAsFixed(4) ?? 'N/A',
                  ),
                  const Divider(),
                  _buildIndicatorRow(
                    'EMA (12)',
                    (indicators1d['ema_12'] as double?)?.toStringAsFixed(4) ?? 'N/A',
                    'EMA (26)',
                    (indicators1d['ema_26'] as double?)?.toStringAsFixed(4) ?? 'N/A',
                  ),
                  const Divider(),
                  _buildIndicatorRow(
                    'RSI (14)',
                    (indicators1d['rsi_14'] as double?)?.toStringAsFixed(2) ?? 'N/A',
                    'MACD Trend',
                    details1d['macd'] as String? ?? 'N/A',
                    isSecondValueTrend: true,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // تحليل الإطارات الزمنية
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تحليل الإطارات الزمنية',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeframeAnalysis('ساعة', analysis1h['overall'] as String? ?? 'N/A'),
                      ),
                      Expanded(
                        child: _buildTimeframeAnalysis('4 ساعات', analysis4h['overall'] as String? ?? 'N/A'),
                      ),
                      Expanded(
                        child: _buildTimeframeAnalysis('يومي', analysis1d['overall'] as String? ?? 'N/A'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // وقت التحليل
          Text(
            'تم التحليل في: $formattedTimestamp',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // تنبيه
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'تنبيه: هذا التحليل لأغراض تعليمية فقط ولا يعتبر نصيحة استثمارية. استخدم المعلومات على مسؤوليتك الخاصة.',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIndicatorRow(String label1, String value1, String label2, String value2, {bool isSecondValueTrend = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label1, style: Theme.of(context).textTheme.bodySmall),
                Text(value1, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(label2, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value2,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isSecondValueTrend ? _getTrendColor(value2) : null,
                        fontWeight: isSecondValueTrend ? FontWeight.bold : null,
                      ),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeAnalysis(String timeframe, String trend) {
    return Column(
      children: [
        Text(timeframe, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          trend,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getTrendColor(trend),
          ),
        ),
      ],
    );
  }
}

// Dummy AppTheme extension for color access (replace with actual implementation if exists)
class AppTheme extends ThemeExtension<AppTheme> {
  final Color? upTrendColor;
  final Color? downTrendColor;
  final Color? neutralTrendColor;

  const AppTheme({
    this.upTrendColor,
    this.downTrendColor,
    this.neutralTrendColor,
  });

  @override
  AppTheme copyWith({
    Color? upTrendColor,
    Color? downTrendColor,
    Color? neutralTrendColor,
  }) {
    return AppTheme(
      upTrendColor: upTrendColor ?? this.upTrendColor,
      downTrendColor: downTrendColor ?? this.downTrendColor,
      neutralTrendColor: neutralTrendColor ?? this.neutralTrendColor,
    );
  }

  @override
  AppTheme lerp(ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) {
      return this;
    }
    return AppTheme(
      upTrendColor: Color.lerp(upTrendColor, other.upTrendColor, t),
      downTrendColor: Color.lerp(downTrendColor, other.downTrendColor, t),
      neutralTrendColor: Color.lerp(neutralTrendColor, other.neutralTrendColor, t),
    );
  }
}

