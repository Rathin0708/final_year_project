
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/employee_model.dart';
import '../services/employee_api_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_dimensions.dart';
import '../utils/app_typography.dart';
import 'add_employee_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final _employeeApiService = EmployeeApiService();
  bool _isLoading = true;
  List<EmployeeModel> _employees = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final employees = await _employeeApiService.getEmployees();
      
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load employees: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Employee Management',
          style: AppTypography.h5.copyWith(
            color: AppColors.textLight,
          ),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmployees,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty 
          ? _buildErrorView()
          : _buildEmployeeList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEmployeeScreen()),
          ).then((_) => _loadEmployees());
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: AppTypography.h4.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadEmployees,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.textLight,
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    if (_employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No employees found',
              style: AppTypography.h5.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a new employee',
              style: AppTypography.bodyMedium.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _employees.length,
      padding: EdgeInsets.all(AppDimensions.paddingM),
      itemBuilder: (context, index) {
        final employee = _employees[index];
        return Card(
          elevation: AppDimensions.elevationS,
          margin: EdgeInsets.only(bottom: AppDimensions.paddingM),
          child: ListTile(
            contentPadding: EdgeInsets.all(AppDimensions.paddingM),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(
                employee.name.isNotEmpty 
                    ? employee.name[0].toUpperCase() 
                    : '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              employee.name,
              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(employee.position),
                Text(employee.department),
                Text('Salary: \$${employee.salary.toStringAsFixed(2)}'),
                Text('Joined: ${employee.joinDate}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show action menu
                _showEmployeeActions(employee);
              },
            ),
            onTap: () {
              // View employee details
            },
          ),
        );
      },
    );
  }

  void _showEmployeeActions(EmployeeModel employee) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Employee'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete Employee', 
                  style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteEmployee(employee);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteEmployee(EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Employee'),
          content: Text('Are you sure you want to delete ${employee.name}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _employeeApiService.deleteEmployee(employee.id!);
                  _loadEmployees();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${employee.name} deleted successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete employee: ${e.toString()}'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}