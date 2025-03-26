
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../Widgets/text_field_input.dart';
import '../models/employee_model.dart';
import '../services/employee_api_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_dimensions.dart';
import '../utils/app_typography.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();
  final _departmentController = TextEditingController();
  final _salaryController = TextEditingController();
  final _joinDateController = TextEditingController();
  final _employeeApiService = EmployeeApiService();
  
  bool _isLoading = false;
  String _errorMessage = '';
  String? _selectedDepartment;
  
  final List<String> _departments = [
    'Engineering',
    'Marketing',
    'Sales',
    'Human Resources',
    'Finance',
    'Operations',
    'Customer Support',
    'Research & Development',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    _salaryController.dispose();
    _joinDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textLight,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _joinDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final employee = EmployeeModel(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        position: _positionController.text.trim(),
        department: _selectedDepartment ?? _departmentController.text.trim(),
        salary: double.parse(_salaryController.text),
        joinDate: _joinDateController.text,
      );
      
      final createdEmployee = await _employeeApiService.createEmployee(employee);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employee added successfully'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );

        // Clear form fields
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _positionController.clear();
        _departmentController.clear();
        _salaryController.clear();
        _joinDateController.clear();
        setState(() {
          _selectedDepartment = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to add employee: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Employee',
          style: AppTypography.h5.copyWith(
            color: AppColors.textLight,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: AppDimensions.elevationM,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppDimensions.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Employee Information',
                  style: AppTypography.h4,
                ),
                SizedBox(height: AppDimensions.paddingL),
                
                // Name field
                Padding(
                  padding: EdgeInsets.only(bottom: AppDimensions.paddingM),
                  child: TextFieldInput(
                    textEditingController: _nameController,
                    hintText: 'Enter employee name',
                    labelText: 'Full Name',
                    textInputType: TextInputType.name,
                    prefixIcon: const Icon(Icons.person),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter employee name';
                      }
                      return null;
                    },
                  ),
                ),
                
                // Email field
                Padding(
                  padding: EdgeInsets.only(bottom: AppDimensions.paddingM),
                  child: TextFieldInput(
                    textEditingController: _emailController,
                    hintText: 'Enter email address',
                    labelText: 'Email',
                    textInputType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email address';
                      } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                        return 'Please enter a valid email format';
                      }
                      return null;
                    },
                  ),
                ),
                
                // Phone field
                Padding(
                  padding: EdgeInsets.only(bottom: AppDimensions.paddingM),
                  child: TextFieldInput(
                    textEditingController: _phoneController,
                    hintText: 'Enter phone number',
                    labelText: 'Phone Number',
                    textInputType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      } else if (!RegExp(r'^\d{10,15}$').hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
                        return 'Please enter a valid phone number (10-15 digits)';
                      }
                      return null;
                    },
                  ),
                ),
                
                // Position field
                Padding(
                  padding: EdgeInsets.only(bottom: AppDimensions.paddingM),
                  child: TextFieldInput(
                    textEditingController: _positionController,
                    hintText: 'Enter job position',
                    labelText: 'Position',
                    textInputType: TextInputType.text,
                    prefixIcon: const Icon(Icons.work),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter job position';
                      }
                      return null;
                    },
                  ),
                ),
                
                // Department dropdown
                Padding(
                  padding: EdgeInsets.only(bottom: AppDimensions.paddingM),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingS),
                    child: DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        prefixIcon: const Icon(Icons.business),
                        border: InputBorder.none,
                      ),
                      items: _departments.map((String department) {
                        return DropdownMenuItem<String>(
                          value: department,
                          child: Text(department),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDepartment = newValue;
                        });
                      },
                      validator: (value) {
                        if ((value == null || value.isEmpty) && _departmentController.text.isEmpty) {
                          return 'Please select a department';
                        }
                        return null;
                      },
                      icon: const Icon(Icons.arrow_drop_down),
                      isExpanded: true,
                      hint: Text('Select department'),
                    ),
                  ),
                ),
                
                // Other department field (if not in dropdown)
                if (_selectedDepartment == null || _selectedDepartment == 'Other')
                  Padding(
                    padding: EdgeInsets.only(bottom: AppDimensions.paddingM),
                    child: TextFieldInput(
                      textEditingController: _departmentController,
                      hintText: 'Enter department name',
                      labelText: 'Other Department',
                      textInputType: TextInputType.text,
                      prefixIcon: const Icon(Icons.business_center),
                      validator: (value) {
                        if (_selectedDepartment == null && (value == null || value.isEmpty)) {
                          return 'Please specify department';
                        }
                        return null;
                      },
                    ),
                  ),
                
                // Salary field
                Padding(
                  padding: EdgeInsets.only(bottom: AppDimensions.paddingM),
                  child: TextFieldInput(
                    textEditingController: _salaryController,
                    hintText: 'Enter salary',
                    labelText: 'Salary',
                    textInputType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: const Icon(Icons.attach_money),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter salary';
                      } else if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                
                // Join Date field
                Padding(
                  padding: EdgeInsets.only(bottom: AppDimensions.paddingM),
                  child: TextFieldInput(
                    textEditingController: _joinDateController,
                    hintText: 'Select join date',
                    labelText: 'Join Date',
                    textInputType: TextInputType.text,
                    prefixIcon: const Icon(Icons.calendar_today),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select join date';
                      }
                      return null;
                    },
                  ),
                ),
                
                SizedBox(height: AppDimensions.paddingL),
                
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(AppDimensions.paddingM),
                    margin: EdgeInsets.only(bottom: AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error),
                        SizedBox(width: AppDimensions.paddingS),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.disabled,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Submit',
                            style: AppTypography.button.copyWith(fontSize: AppDimensions.fontL),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}