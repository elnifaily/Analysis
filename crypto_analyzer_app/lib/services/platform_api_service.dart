// الواجهة المجردة لخدمات واجهة برمجة التطبيقات للمنصات
abstract class PlatformApiService {
  // جلب قائمة الرموز المتاحة
  Future<List<String>> getAvailableSymbols();

  // جلب بيانات الشموع اليابانية (Klines)
  Future<Map<String, dynamic>> getKlines(String symbol, String interval, String limit);

  // جلب السعر الحالي
  Future<double> getCurrentPrice(String symbol);

  // التحقق من صحة بيانات الاعتماد (مثل مفاتيح API أو الجلسة)
  Future<bool> validateCredentials();

  // وظائف إضافية محتملة يمكن تعريفها هنا (مثل الشراء، البيع، إلخ)
  // Future<dynamic> buy(String symbol, double amount, String direction, ...);
  // Future<dynamic> sell(String symbol, double amount, ...);
}

