import 'package:flutter/material.dart';

class CustomerNotifier extends ChangeNotifier {
  static final CustomerNotifier _instance = CustomerNotifier._internal();
  factory CustomerNotifier() => _instance;
  CustomerNotifier._internal();

  void notifyCustomerAdded() {
    notifyListeners();
  }
}
