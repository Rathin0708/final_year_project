import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/professional_development_model.dart';
import '../providers/professional_development_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/app_dimensions.dart';

class ProfessionalDevelopmentScreen extends StatefulWidget {
  const ProfessionalDevelopmentScreen({super.key});

  @override
  State<ProfessionalDevelopmentScreen> createState() => _ProfessionalDevelopmentScreenState();
}

class _ProfessionalDevelopmentScreenState extends State<ProfessionalDevelopmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load professional development data when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfessionalDevelopmentProvider>(context, listen: false).loadDevelopmentData();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Development'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Skills'),
            Tab(text: 'Goals'),
            Tab(text: 'Certifications'),
          ],
        ),
      ),
      body: Consumer<ProfessionalDevelopmentProvider>(
        builder: (context, devProvider, _) {
          if (devProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (devProvider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: AppTypography.h5.copyWith(color: AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      devProvider.error,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => devProvider.loadDevelopmentData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildSkillsTab(devProvider),
              _buildGoalsTab(devProvider),
              _buildCertificationsTab(devProvider),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  
  Widget _buildFloatingActionButton() {
    return Consumer<ProfessionalDevelopmentProvider>(
      builder: (context, devProvider, _) {
        return FloatingActionButton(
          onPressed: () {
            switch (_tabController.index) {
              case 0:
                _showAddSkillDialog();
                break;
              case 1:
                _showAddGoalDialog();
                break;
              case 2:
                _showAddCertificationDialog();
                break;
            }
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add),
        );
      },
    );
  }
  
  // Skills Tab
  Widget _buildSkillsTab(ProfessionalDevelopmentProvider provider) {
    final skills = provider.skills;
    
    if (skills.isEmpty) {
      return _buildEmptyState(
        icon: Icons.lightbulb_outline,
        title: 'No Skills Added',
        description: 'Add skills to track your professional growth',
        actionText: 'Add Skill',
        onAction: () => _showAddSkillDialog(),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(AppDimensions.paddingM),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return Card(
          elevation: AppDimensions.elevationS,
          margin: EdgeInsets.only(bottom: AppDimensions.paddingS),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        skill.name,
                        style: AppTypography.h1.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () async {
                        await provider.removeSkill(skill.name);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Proficiency: ${skill.proficiencyLevel}/5',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: skill.proficiencyLevel / 5,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                if (skill.endorsements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Endorsements:', style: AppTypography.bodySmall),
                  Wrap(
                    spacing: 8,
                    children: skill.endorsements.map((endorser) {
                      return Chip(
                        label: Text(endorser),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: TextStyle(color: AppColors.primary),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Goals Tab
  Widget _buildGoalsTab(ProfessionalDevelopmentProvider provider) {
    final goals = provider.goals;
    
    if (goals.isEmpty) {
      return _buildEmptyState(
        icon: Icons.flag_outlined,
        title: 'No Goals Set',
        description: 'Set development goals to track your progress',
        actionText: 'Add Goal',
        onAction: () => _showAddGoalDialog(),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(AppDimensions.paddingM),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        final daysRemaining = goal.targetDate.difference(DateTime.now()).inDays;
        
        return Card(
          elevation: AppDimensions.elevationS,
          margin: EdgeInsets.only(bottom: AppDimensions.paddingS),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: goal.completed,
                      activeColor: AppColors.success,
                      onChanged: (value) async {
                        await provider.toggleGoalCompletion(goal.id);
                      },
                    ),
                    Expanded(
                      child: Text(
                        goal.title,
                        style: AppTypography.h1.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: goal.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () async {
                        await provider.removeGoal(goal.id);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    goal.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: goal.completed ? Colors.grey : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: goal.completed ? Colors.grey : 
                            daysRemaining < 0 ? Colors.red : Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(goal.targetDate),
                          style: AppTypography.bodySmall.copyWith(
                            color: goal.completed ? Colors.grey : 
                              daysRemaining < 0 ? Colors.red : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    if (!goal.completed) 
                      Text(
                        daysRemaining > 0 
                            ? '$daysRemaining days remaining' 
                            : '${daysRemaining.abs()} days overdue',
                        style: AppTypography.bodySmall.copyWith(
                          color: daysRemaining < 0 ? Colors.red : Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                if (goal.relatedSkills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: goal.relatedSkills.map((skill) {
                      return Chip(
                        label: Text(skill),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: TextStyle(color: AppColors.primary),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Certifications Tab
  Widget _buildCertificationsTab(ProfessionalDevelopmentProvider provider) {
    final certifications = provider.certifications;
    
    if (certifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.badge_outlined,
        title: 'No Certifications Added',
        description: 'Add your certifications and credentials',
        actionText: 'Add Certification',
        onAction: () => _showAddCertificationDialog(),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(AppDimensions.paddingM),
      itemCount: certifications.length,
      itemBuilder: (context, index) {
        final cert = certifications[index];
        final isExpired = cert.expiryDate != null && 
            cert.expiryDate!.isBefore(DateTime.now());
        
        return Card(
          elevation: AppDimensions.elevationS,
          margin: EdgeInsets.only(bottom: AppDimensions.paddingS),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cert.name,
                        style: AppTypography.h1.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () async {
                        await provider.removeCertification(cert.name, cert.issuingOrganization);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  cert.issuingOrganization,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Issued: ${DateFormat('MMM yyyy').format(cert.issueDate)}',
                      style: AppTypography.bodySmall,
                    ),
                    if (cert.expiryDate != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        'Expires: ${DateFormat('MMM yyyy').format(cert.expiryDate!)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: isExpired ? Colors.red : null,
                        ),
                      ),
                      if (isExpired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Expired',
                            style: AppTypography.bodySmall.copyWith(color: Colors.red),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
                if (cert.credentialUrl != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      // Launch URL (would need url_launcher package)
                    },
                    child: Text(
                      'View Credential',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.h5.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingL,
                  vertical: AppDimensions.paddingM,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Add Skill Dialog
  void _showAddSkillDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    int proficiencyLevel = 3;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Skill'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Skill Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a skill name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Proficiency Level:'),
                Slider(
                  value: proficiencyLevel.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$proficiencyLevel',
                  onChanged: (value) {
                    setState(() {
                      proficiencyLevel = value.round();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Beginner'),
                    const Text('Expert'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Provider.of<ProfessionalDevelopmentProvider>(context, listen: false)
                    .saveSkill(
                      name: nameController.text.trim(),
                      proficiencyLevel: proficiencyLevel,
                    );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Add Skill'),
            ),
          ],
        );
      },
    );
  }
  
  // Add Goal Dialog
  void _showAddGoalDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime targetDate = DateTime.now().add(const Duration(days: 30));
    final provider = Provider.of<ProfessionalDevelopmentProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Goal'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a goal title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Target Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(targetDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: targetDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          targetDate = selectedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  provider.addGoal(
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    targetDate: targetDate,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Add Goal'),
            ),
          ],
        );
      },
    );
  }
  
  // Add Certification Dialog
  void _showAddCertificationDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final organizationController = TextEditingController();
    final credentialIdController = TextEditingController();
    final credentialUrlController = TextEditingController();
    DateTime issueDate = DateTime.now();
    DateTime? expiryDate;
    bool hasExpiration = false;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Certification'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Certification Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter certification name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: organizationController,
                        decoration: const InputDecoration(
                          labelText: 'Issuing Organization',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter issuing organization';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Issue Date'),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(issueDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: issueDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (selectedDate != null) {
                            setDialogState(() {
                              issueDate = selectedDate;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: hasExpiration,
                            onChanged: (value) {
                              setDialogState(() {
                                hasExpiration = value ?? false;
                                if (!hasExpiration) {
                                  expiryDate = null;
                                } else if (expiryDate == null) {
                                  expiryDate = DateTime.now().add(const Duration(days: 365));
                                }
                              });
                            },
                          ),
                          const Text('Has Expiration Date'),
                        ],
                      ),
                      if (hasExpiration)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Expiry Date'),
                          subtitle: Text(expiryDate != null 
                              ? DateFormat('MMM dd, yyyy').format(expiryDate!)
                              : 'Not set'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                            );
                            if (selectedDate != null) {
                              setDialogState(() {
                                expiryDate = selectedDate;
                              });
                            }
                          },
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: credentialIdController,
                        decoration: const InputDecoration(
                          labelText: 'Credential ID (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: credentialUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Credential URL (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Provider.of<ProfessionalDevelopmentProvider>(context, listen: false)
                          .saveCertification(
                            name: nameController.text.trim(),
                            issuingOrganization: organizationController.text.trim(),
                            issueDate: issueDate,
                            expiryDate: hasExpiration ? expiryDate : null,
                            credentialId: credentialIdController.text.isEmpty 
                                ? null : credentialIdController.text.trim(),
                            credentialUrl: credentialUrlController.text.isEmpty
                                ? null : credentialUrlController.text.trim(),
                          );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Add Certification'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}