import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';

class EmployeeApiService {
  static const String baseUrl = 'https://67d9262600348dd3e2a9d318.mockapi.io/api/v1';
  static const String employeesEndpoint = '/employees';

  // Fetch all employees
  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$employeesEndpoint'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((data) => EmployeeModel.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load employees: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching employees: $e');
    }
  }

  // Fetch single employee by ID
  Future<EmployeeModel> getEmployeeById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$employeesEndpoint/$id'));
      
      if (response.statusCode == 200) {
        return EmployeeModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load employee: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching employee: $e');
    }
  }

  // Create a new employee
  Future<EmployeeModel> createEmployee(EmployeeModel employee) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$employeesEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(employee.toJson()),
      );
      
      if (response.statusCode == 201) {
        return EmployeeModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create employee: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating employee: $e');
    }
  }

  // Update employee
  Future<EmployeeModel> updateEmployee(String id, EmployeeModel employee) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$employeesEndpoint/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(employee.toJson()),
      );
      
      if (response.statusCode == 200) {
        return EmployeeModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update employee: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating employee: $e');
    }
  }

  // Delete employee
  Future<bool> deleteEmployee(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl$employeesEndpoint/$id'));
      
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete employee: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting employee: $e');
    }
  }
}