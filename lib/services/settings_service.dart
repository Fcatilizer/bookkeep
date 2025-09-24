import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _userNameKey = 'user_name';
  static const String _companyNameKey = 'company_name';
  static const String _companyAddressKey = 'company_address';
  static const String _phoneNumberKey = 'phone_number';
  static const String _gstNumberKey = 'gst_number';

  // Default values
  static const String _defaultCompanyName = 'BOOKKEEP ACCOUNTING';
  static const String _defaultCompanyAddress = 'Customer Event Report';

  // Singleton pattern
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Get user name
  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? '';
  }

  // Set user name
  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // Get company name
  Future<String> getCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companyNameKey) ?? _defaultCompanyName;
  }

  // Set company name
  Future<void> setCompanyName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companyNameKey, name);
  }

  // Get company address
  Future<String> getCompanyAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companyAddressKey) ?? _defaultCompanyAddress;
  }

  // Set company address
  Future<void> setCompanyAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companyAddressKey, address);
  }

  // Get phone number
  Future<String> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneNumberKey) ?? '';
  }

  // Set phone number
  Future<void> setPhoneNumber(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneNumberKey, phoneNumber);
  }

  // Get GST number
  Future<String> getGstNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_gstNumberKey) ?? '';
  }

  // Set GST number
  Future<void> setGstNumber(String gstNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gstNumberKey, gstNumber);
  }

  // Get all settings at once
  Future<Map<String, String>> getAllSettings() async {
    return {
      'userName': await getUserName(),
      'companyName': await getCompanyName(),
      'companyAddress': await getCompanyAddress(),
      'phoneNumber': await getPhoneNumber(),
      'gstNumber': await getGstNumber(),
    };
  }

  // Update all settings at once
  Future<void> updateAllSettings({
    required String userName,
    required String companyName,
    required String companyAddress,
    required String phoneNumber,
    required String gstNumber,
  }) async {
    await Future.wait([
      setUserName(userName),
      setCompanyName(companyName),
      setCompanyAddress(companyAddress),
      setPhoneNumber(phoneNumber),
      setGstNumber(gstNumber),
    ]);
  }
}
