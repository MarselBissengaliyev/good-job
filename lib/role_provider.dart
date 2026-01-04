import 'package:flutter/foundation.dart';

enum UserRole {
  master,
  client,
  none
}

class RoleProvider extends ChangeNotifier {
  UserRole _selectedRole = UserRole.none;
  
  UserRole get selectedRole => _selectedRole;
  
  void selectMaster() {
    _selectedRole = UserRole.master;
    notifyListeners();
  }
  
  void selectClient() {
    _selectedRole = UserRole.client;
    notifyListeners();
  }
  
  void resetRole() {
    _selectedRole = UserRole.none;
    notifyListeners();
  }
  
  bool get isMasterSelected => _selectedRole == UserRole.master;
  bool get isClientSelected => _selectedRole == UserRole.client;
  bool get isRoleSelected => _selectedRole != UserRole.none;
}