import 'dart:math';

class TechnicalAnalysisService {

  // Helper function to calculate SMA for the initial EMA value
  double _calculateInitialSMA(List<double> prices, int period) {
    if (prices.length < period) {
      throw ArgumentError('Not enough data for SMA calculation');
    }
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += prices[i];
    }
    return sum / period;
  }

  // حساب المتوسط المتحرك الأسي (EMA) محليًا
  List<double?> calculateEMA(List<double> prices, int period) {
    if (prices.length < period) {
      return List.filled(prices.length, null);
    }

    List<double?> emaValues = List.filled(prices.length, null);
    double multiplier = 2 / (period + 1);
    
    // Calculate initial SMA for the first EMA value
    emaValues[period - 1] = _calculateInitialSMA(prices.sublist(0, period), period);

    // Calculate subsequent EMA values
    for (int i = period; i < prices.length; i++) {
      if (emaValues[i - 1] != null) {
         emaValues[i] = (prices[i] - emaValues[i - 1]!) * multiplier + emaValues[i - 1]!;
      } else {
         // Should not happen if logic is correct, but handle defensively
         // Recalculate SMA if previous EMA is null (error case)
         try {
            emaValues[i] = _calculateInitialSMA(prices.sublist(i - period + 1, i + 1), period);
         } catch (e) {
            emaValues[i] = null; // Not enough data
         }
      }
    }
    return emaValues;
  }

  // حساب مؤشر القوة النسبية (RSI) محليًا
  List<double?> calculateRSI(List<double> prices, int period) {
    if (prices.length <= period) {
      return List.filled(prices.length, null);
    }

    List<double?> rsiValues = List.filled(prices.length, null);
    List<double> gains = [];
    List<double> losses = [];

    // Calculate initial gains and losses
    for (int i = 1; i <= period; i++) {
      double change = prices[i] - prices[i - 1];
      if (change > 0) {
        gains.add(change);
        losses.add(0);
      } else {
        gains.add(0);
        losses.add(change.abs());
      }
    }

    double avgGain = gains.reduce((a, b) => a + b) / period;
    double avgLoss = losses.reduce((a, b) => a + b) / period;

    double rs = (avgLoss == 0) ? double.infinity : avgGain / avgLoss;
    rsiValues[period] = 100 - (100 / (1 + rs));

    // Calculate subsequent RSI values using Wilder's smoothing
    for (int i = period + 1; i < prices.length; i++) {
      double change = prices[i] - prices[i - 1];
      double gain = change > 0 ? change : 0;
      double loss = change < 0 ? change.abs() : 0;

      avgGain = (avgGain * (period - 1) + gain) / period;
      avgLoss = (avgLoss * (period - 1) + loss) / period;

      rs = (avgLoss == 0) ? double.infinity : avgGain / avgLoss;
      rsiValues[i] = 100 - (100 / (1 + rs));
    }

    return rsiValues;
  }

  // حساب مؤشر MACD محليًا
  Map<String, List<double?>> calculateMACD(List<double> prices, {int fastPeriod = 12, int slowPeriod = 26, int signalPeriod = 9}) {
    if (prices.length < slowPeriod + signalPeriod -1) {
       // Not enough data for full MACD calculation
       return {
        'macd': List.filled(prices.length, null),
        'signal': List.filled(prices.length, null),
        'histogram': List.filled(prices.length, null),
      };
    }

    List<double?> emaFast = calculateEMA(prices, fastPeriod);
    List<double?> emaSlow = calculateEMA(prices, slowPeriod);
    List<double?> macdLine = List.filled(prices.length, null);

    // Calculate MACD line
    for (int i = slowPeriod - 1; i < prices.length; i++) {
      if (emaFast[i] != null && emaSlow[i] != null) {
        macdLine[i] = emaFast[i]! - emaSlow[i]!;
      }
    }

    // Prepare list for signal line calculation (remove leading nulls)
    List<double> validMacdValues = macdLine.where((val) => val != null).cast<double>().toList();
    
    if (validMacdValues.length < signalPeriod) {
       // Not enough valid MACD values for signal line calculation
        return {
          'macd': macdLine,
          'signal': List.filled(prices.length, null),
          'histogram': List.filled(prices.length, null),
        };
    }

    List<double?> signalLineFull = List.filled(prices.length, null);
    List<double?> signalLineCalculated = calculateEMA(validMacdValues, signalPeriod);

    // Align signal line results back to the original price list length
    int signalStartIndex = prices.length - validMacdValues.length; // Index where valid MACD starts
    for(int i = 0; i < signalLineCalculated.length; i++) {
        if (signalStartIndex + i < prices.length) {
            signalLineFull[signalStartIndex + i] = signalLineCalculated[i];
        }
    }

    List<double?> histogram = List.filled(prices.length, null);
    // Calculate Histogram
    for (int i = slowPeriod + signalPeriod - 2; i < prices.length; i++) { // Start index adjusted for signal line EMA
       if (macdLine[i] != null && signalLineFull[i] != null) {
         histogram[i] = macdLine[i]! - signalLineFull[i]!;
       }
    }

    return {
      'macd': macdLine,
      'signal': signalLineFull,
      'histogram': histogram,
    };
  }

  // حساب المتوسط المتحرك البسيط (SMA) - Kept for potential use or direct calls
  List<double?> calculateSMA(List<double> prices, int period) {
     if (prices.length < period) {
      return List.filled(prices.length, null);
    }
    List<double?> smaValues = List.filled(prices.length, null);
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += prices[i];
    }
    smaValues[period - 1] = sum / period;

    for (int i = period; i < prices.length; i++) {
      sum = sum - prices[i - period] + prices[i];
      smaValues[i] = sum / period;
    }
    return smaValues;
  }


  // تحليل الاتجاه بناءً على المؤشرات الفنية (Requires calculated indicator values)
  Map<String, dynamic> analyzeTrend(
    {
      required double currentPrice,
      required double? sma20, // Nullable now
      required double? sma50, // Nullable now
      required double? ema12, // Nullable now
      required double? ema26, // Nullable now
      required double? rsi,   // Nullable now
      required double? macd,  // Nullable now
      required double? macdSignal // Nullable now
    }
  ) {
    // تحليل المتوسطات المتحركة
    String smaTrend = 'محايد';
    if (sma20 != null && sma50 != null && currentPrice > sma20 && sma20 > sma50) {
      smaTrend = 'صاعد';
    } else if (sma20 != null && sma50 != null && currentPrice < sma20 && sma20 < sma50) {
      smaTrend = 'هابط';
    }
    
    // تحليل EMA
    String emaTrend = 'محايد';
    if (ema12 != null && ema26 != null && ema12 > ema26) {
      emaTrend = 'صاعد';
    } else if (ema12 != null && ema26 != null && ema12 < ema26) {
      emaTrend = 'هابط';
    }
    
    // تحليل RSI
    String rsiTrend = 'محايد';
    if (rsi != null) {
        if (rsi > 70) {
          rsiTrend = 'ذروة شراء';
        } else if (rsi < 30) {
          rsiTrend = 'ذروة بيع';
        } else if (rsi > 50) {
          rsiTrend = 'صاعد';
        } else if (rsi < 50) {
          rsiTrend = 'هابط';
        }
    }
    
    // تحليل MACD
    String macdTrend = 'محايد';
    if (macd != null && macdSignal != null && macd > macdSignal) {
      macdTrend = 'صاعد';
    } else if (macd != null && macdSignal != null && macd < macdSignal) {
      macdTrend = 'هابط';
    }
    
    // تحديد الاتجاه العام
    List<String> trends = [smaTrend, emaTrend, rsiTrend, macdTrend];
    int upCount = trends.where((trend) => trend == 'صاعد').length;
    int downCount = trends.where((trend) => trend == 'هابط').length;
    
    String overallTrend = 'محايد';
    // Simple majority vote, can be refined
    if (upCount > downCount && upCount >= 2) { // Require at least 2 confirming signals
      overallTrend = 'صاعد';
    } else if (downCount > upCount && downCount >= 2) {
      overallTrend = 'هابط';
    }
    
    // إعداد النتيجة
    return {
      'overall': overallTrend,
      'details': {
        'sma': smaTrend,
        'ema': emaTrend,
        'rsi': rsiTrend,
        'macd': macdTrend,
      },
      'indicators': {
        'close': currentPrice,
        'sma_20': sma20,
        'sma_50': sma50,
        'ema_12': ema12,
        'ema_26': ema26,
        'rsi_14': rsi, // Assuming period 14 for RSI
        'macd': macd,
        'macd_signal': macdSignal,
      }
    };
  }

  // تحديد الإطار الزمني المتوقع للاتجاه
  String determineTimeframe(String trend1h, String trend4h, String trend1d) {
    // إذا كانت جميع الاتجاهات متطابقة، فهذا يشير إلى اتجاه قوي
    if (trend1h == trend4h && trend4h == trend1d) {
      if (trend1d != 'محايد') {
        return 'طويل المدى (أيام إلى أسابيع)';
      }
    }
    
    // إذا كان الاتجاه اليومي مختلفاً عن الاتجاهات الأقصر
    if (trend1d != trend4h && trend1d != trend1h) {
      if (trend4h == trend1h && trend4h != 'محايد') {
        return 'متوسط المدى (ساعات إلى أيام)';
      }
    }
    
    // إذا كان الاتجاه على المدى القصير فقط
    if (trend1h != 'محايد' && trend1h != trend4h && trend1h != trend1d) {
      return 'قصير المدى (ساعات)';
    }
    
    // الحالة الافتراضية
    return 'غير محدد';
  }

  // تحليل كامل للعملة على إطارات زمنية مختلفة
  Map<String, dynamic> completeAnalysis(
    {
      required String symbol,
      required Map<String, dynamic> analysis1h,
      required Map<String, dynamic> analysis4h,
      required Map<String, dynamic> analysis1d,
      required double currentPrice
    }
  ) {
    // تحديد الاتجاه العام بناءً على الاتجاهات المختلفة
    List<String> trends = [
      analysis1h['overall'],
      analysis4h['overall'],
      analysis1d['overall'],
      // إعطاء وزن أكبر للإطار الزمني الأطول
      analysis4h['overall'],
      analysis1d['overall'],
      analysis1d['overall'],
    ];
    
    int upCount = trends.where((trend) => trend == 'صاعد').length;
    int downCount = trends.where((trend) => trend == 'هابط').length;
    int neutralCount = trends.where((trend) => trend == 'محايد').length;
    
    String overallTrend = 'محايد';
    if (upCount > downCount && upCount > neutralCount) {
      overallTrend = 'صاعد';
    } else if (downCount > upCount && downCount > neutralCount) {
      overallTrend = 'هابط';
    }
    
    // تحديد الإطار الزمني المتوقع
    String timeframe = determineTimeframe(
      analysis1h['overall'],
      analysis4h['overall'],
      analysis1d['overall']
    );
    
    // إعداد النتيجة النهائية
    return {
      'symbol': symbol, // Added symbol to the final result
      'current_price': currentPrice,
      'trend': overallTrend,
      'timeframe': timeframe,
      'analysis': {
        '1h': analysis1h,
        '4h': analysis4h,
        '1d': analysis1d,
      },
      'timestamp': DateTime.now().toIso8601String(), // Use ISO format
    };
  }
}

