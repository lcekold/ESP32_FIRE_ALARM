import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

/// 认证状态管理Provider
/// 
/// 管理用户登录状态、当前用户信息和认证操作
/// _Requirements: 1.2, 3.3, 3.4_
class AuthProvider extends ChangeNotifier {
  AuthService? _authService;
  SharedPreferences? _prefs;
  
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  String? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;
  
  /// 是否已登录
  bool get isLoggedIn => _isLoggedIn;
  
  /// 当前用户名
  String? get currentUser => _currentUser;
  
  /// 是否正在加载
  bool get isLoading => _isLoading;
  
  /// 错误消息
  String? get errorMessage => _errorMessage;

  /// 初始化Provider
  /// 
  /// 检查现有会话并恢复登录状态
  /// _Requirements: 3.4_
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _authService = AuthService(_prefs!);
    
    // 检查是否已登录
    _isLoggedIn = await _authService!.isLoggedIn();
    if (_isLoggedIn) {
      _currentUser = await _authService!.getCurrentUser();
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  /// 用户登录
  /// 
  /// _Requirements: 3.1, 3.2, 3.3_
  Future<bool> login(String username, String password) async {
    if (_authService == null) await initialize();
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService!.login(username, password);
      
      if (result.success) {
        _isLoggedIn = true;
        _currentUser = username;
        _errorMessage = null;
      } else {
        _errorMessage = result.errorMessage;
      }
      
      _isLoading = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = '登录失败，请稍后重试';
      notifyListeners();
      return false;
    }
  }

  /// 用户注册
  /// 
  /// _Requirements: 2.2, 2.3, 2.4_
  Future<bool> register(String username, String password) async {
    if (_authService == null) await initialize();
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService!.register(username, password);
      
      if (!result.success) {
        _errorMessage = result.errorMessage;
      }
      
      _isLoading = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = '注册失败，请稍后重试';
      notifyListeners();
      return false;
    }
  }

  /// 用户登出
  /// 
  /// _Requirements: 3.5_
  Future<void> logout() async {
    if (_authService == null) return;
    
    await _authService!.logout();
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }

  /// 清除错误消息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
