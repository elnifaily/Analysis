import 'dart:convert';
import 'package:http/http.dart' as http;
import 'platform_api_service.dart'; // Import the abstract interface

class BinanceApiService implements PlatformApiService { // Implement the interface
  final String apiKey;
  final String apiSecret;
  final String baseUrl = 'https://api.binance.com';

  BinanceApiService({required this.apiKey, required this.apiSecret});

  @override // Add override annotation
  Future<List<String>> getAvailableSymbols() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v3/exchangeInfo'),
        headers: {'X-MBX-APIKEY': apiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final symbols = <String>[];

        for (var symbol in data['symbols']) {
          // Filter for relevant symbols, e.g., USDT pairs, and check status
          if (symbol['status'] == 'TRADING' && symbol['quoteAsset'] == 'USDT') {
             symbols.add(symbol['symbol']);
          }
        }

        symbols.sort();
        return symbols;
      } else {
         print('Binance API Error: ${response.statusCode} - ${response.body}');
        throw Exception('فشل في جلب قائمة العملات: ${response.statusCode}');
      }
    } catch (e) {
       print('Binance Connection Error: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  @override // Add override annotation
  Future<Map<String, dynamic>> getKlines(String symbol, String interval, String limit) async {
     // Map app interval to Binance interval if needed (e.g., '1m', '5m', '1h')
     // Assuming interval is already in Binance format for now
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v3/klines?symbol=$symbol&interval=$interval&limit=$limit'),
        headers: {'X-MBX-APIKEY': apiKey},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> formattedData = [];

        for (var candle in data) {
          formattedData.add({
            'timestamp': candle[0],
            'open': double.parse(candle[1]),
            'high': double.parse(candle[2]),
            'low': double.parse(candle[3]),
            'close': double.parse(candle[4]),
            'volume': double.parse(candle[5]),
          });
        }

        return {
          'symbol': symbol,
          'interval': interval,
          'data': formattedData,
        };
      } else {
         print('Binance API Error: ${response.statusCode} - ${response.body}');
        throw Exception('فشل في جلب بيانات الشموع: ${response.statusCode}');
      }
    } catch (e) {
       print('Binance Connection Error: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  @override // Add override annotation
  Future<double> getCurrentPrice(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v3/ticker/price?symbol=$symbol'),
        headers: {'X-MBX-APIKEY': apiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return double.parse(data['price']);
      } else {
         print('Binance API Error: ${response.statusCode} - ${response.body}');
        throw Exception('فشل في جلب السعر الحالي: ${response.statusCode}');
      }
    } catch (e) {
       print('Binance Connection Error: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  @override // Add override annotation
  Future<bool> validateCredentials() async { // Renamed from validateApiKeys
    // Using a simple check like getting exchange info again.
    try {
       await getAvailableSymbols(); // Try fetching symbols
       return true; // If no exception, consider it valid
    } catch (e) {
       print('Binance Credential Validation Error: $e');
       return false;
    }
  }
}

