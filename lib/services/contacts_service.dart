import 'package:flutter_contacts/flutter_contacts.dart';

/// خدمة سحب جهات الاتصال من الهاتف لإضافتها كمدعوين
class AppContactsService {
  /// يطلب صلاحية الوصول لجهات الاتصال، ويعيد true إذا سُمح بالوصول
  static Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission(readonly: true);
  }

  /// يجلب جميع جهات الاتصال (اسم + رقم هاتف) من الهاتف
  static Future<List<Contact>> fetchContacts() async {
    final granted = await requestPermission();
    if (!granted) return [];
    return FlutterContacts.getContacts(withProperties: true, withPhoto: false);
  }
}
