import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SwitchProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  bool _isCategoryGridView = false;
  bool _isProductGridView = true;
  bool _isArchiveView = true;
  bool _isDashboardGridView = true; // ✅ Fixed typo

  bool get isCategoryGridView => _isCategoryGridView;
  bool get isProductGridView => _isProductGridView;
  bool get isArchiveView => _isArchiveView;
  bool get isDashboardGridView => _isDashboardGridView; // ✅ Fixed typo

  SwitchProvider() {
    _initialize();
  }

  /// Initialize and load settings
  Future<void> _initialize() async {
    await loadSettings();
  }

  /// Loads settings & ensures default is applied if missing or empty
  Future<void> loadSettings() async {
    _isCategoryGridView = await _loadBool('categoryGridView', defaultValue: false);
    _isProductGridView = await _loadBool('productGridView', defaultValue: true);
    _isArchiveView = await _loadBool('archiveCategory', defaultValue: false);
    _isDashboardGridView = await _loadBool('dashboardGridView', defaultValue: true); // ✅ New line
    notifyListeners();
  }

  /// Helper: Loads bool from storage with default fallback
  Future<bool> _loadBool(String key, {required bool defaultValue}) async {
    final value = await _storage.read(key: key);
    final boolValue = (value ?? '').trim().isEmpty
        ? defaultValue
        : value == 'true';

    if (value == null || value.trim().isEmpty) {
      await _storage.write(key: key, value: defaultValue.toString());
    }

    return boolValue;
  }

  /// Toggle & Save Methods:
  Future<void> toggleCategoryGridView() async {
    _isCategoryGridView = !_isCategoryGridView;
    await _storage.write(key: 'categoryGridView', value: _isCategoryGridView.toString());
    notifyListeners();
  }

  Future<void> toggleProductGridView() async {
    _isProductGridView = !_isProductGridView;
    await _storage.write(key: 'productGridView', value: _isProductGridView.toString());
    notifyListeners();
  }

  Future<void> toggleArchiveView() async {
    _isArchiveView = !_isArchiveView;
    await _storage.write(key: 'archiveCategory', value: _isArchiveView.toString());
    notifyListeners();
  }

  Future<void> toggleDashboardGridView() async { // ✅ NEW toggle method
    _isDashboardGridView = !_isDashboardGridView;
    await _storage.write(key: 'dashboardGridView', value: _isDashboardGridView.toString());
    notifyListeners();
  }

  /// Optional setters:
  Future<void> setCategoryGridView(bool value) async {
    _isCategoryGridView = value;
    await _storage.write(key: 'categoryGridView', value: value.toString());
    notifyListeners();
  }

  Future<void> setProductGridView(bool value) async {
    _isProductGridView = value;
    await _storage.write(key: 'productGridView', value: value.toString());
    notifyListeners();
  }

  Future<void> setArchiveView(bool value) async {
    _isArchiveView = value;
    await _storage.write(key: 'archiveCategory', value: value.toString());
    notifyListeners();
  }

  Future<void> setDashboardGridView(bool value) async { // ✅ NEW setter method
    _isDashboardGridView = value;
    await _storage.write(key: 'dashboardGridView', value: value.toString());
    notifyListeners();
  }
}
