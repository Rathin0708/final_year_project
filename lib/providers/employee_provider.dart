import 'package:flutter/foundation.dart';
import '../models/employee_model.dart';
import '../services/employee_api_service.dart';

class EmployeeProvider extends ChangeNotifier {
  final EmployeeApiService _employeeApiService = EmployeeApiService();
  
  List<EmployeeModel> _employees = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Getters
  List<EmployeeModel> get employees => _employees;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  // Fetch all employees
  Future<void> fetchEmployees() async {
    _setLoading(true);
    
    try {
      final employeesList = await _employeeApiService.getEmployees();
      _employees = employeesList;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Failed to fetch employees: ${e.toString()}';
      debugPrint(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }
  
  // Get employee by ID
  Future<EmployeeModel?> getEmployeeById(String id) async {
    _setLoading(true);
    
    try {
      final employee = await _employeeApiService.getEmployeeById(id);
      _errorMessage = '';
      return employee;
    } catch (e) {
      _errorMessage = 'Failed to get employee: ${e.toString()}';
      debugPrint(_errorMessage);
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Add new employee
  Future<bool> addEmployee(EmployeeModel employee) async {
    _setLoading(true);
    
    try {
      final createdEmployee = await _employeeApiService.createEmployee(employee);
      _employees.add(createdEmployee);
      _errorMessage = '';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add employee: ${e.toString()}';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update existing employee
  Future<bool> updateEmployee(String id, EmployeeModel updatedEmployee) async {
    _setLoading(true);
    
    try {
      final employee = await _employeeApiService.updateEmployee(id, updatedEmployee);
      
      // Update the employee in the list
      final index = _employees.indexWhere((emp) => emp.id == id);
      if (index != -1) {
        _employees[index] = employee;
      }
      
      _errorMessage = '';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update employee: ${e.toString()}';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete employee
  Future<bool> deleteEmployee(String id) async {
    _setLoading(true);
    
    try {
      final result = await _employeeApiService.deleteEmployee(id);
      
      if (result) {
        // Remove the employee from the list
        _employees.removeWhere((emp) => emp.id == id);
        _errorMessage = '';
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      _errorMessage = 'Failed to delete employee: ${e.toString()}';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Helper method to set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}