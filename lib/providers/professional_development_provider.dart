import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/professional_development_model.dart';
import '../services/professional_development_service.dart';

class ProfessionalDevelopmentProvider with ChangeNotifier {
  final ProfessionalDevelopmentService _devService = ProfessionalDevelopmentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  ProfessionalDevelopmentModel _developmentData = ProfessionalDevelopmentModel();
  String _error = '';

  Map<String, StreamSubscription<DocumentSnapshot>> _dataSubscriptions = {};

  // Getters
  bool get isLoading => _isLoading;
  ProfessionalDevelopmentModel get developmentData => _developmentData;
  List<SkillModel> get skills => _developmentData.skills;
  List<CertificationModel> get certifications => _developmentData.certifications;
  List<DevelopmentGoalModel> get goals => _developmentData.goals;
  Map<String, dynamic> get careerPath => _developmentData.careerPath;
  String get error => _error;

  ProfessionalDevelopmentProvider() {
    // Listen for auth state changes to setup/teardown listeners
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadDevelopmentData();
      } else {
        _cancelAllSubscriptions();
        _developmentData = ProfessionalDevelopmentModel();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _cancelAllSubscriptions();
    super.dispose();
  }

  void _cancelAllSubscriptions() {
    for (var subscription in _dataSubscriptions.values) {
      subscription.cancel();
    }
    _dataSubscriptions.clear();
  }

  // Load all professional development data
  Future<void> loadDevelopmentData() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Cancel any existing subscriptions
      _cancelAllSubscriptions();

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get reference to user's professional development collection
      final userDevCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('professional_development');

      // Setup real-time listeners
      _setupDocumentListener(userDevCollection, 'skills', (data) {
        final List<dynamic> skillsData = data['items'] ?? [];
        final skills = skillsData.map((data) => SkillModel.fromJson(data)).toList();
        _developmentData = _developmentData.copyWith(skills: skills);
        notifyListeners();
      });

      _setupDocumentListener(userDevCollection, 'certifications', (data) {
        final List<dynamic> certsData = data['items'] ?? [];
        final certifications = certsData.map((data) => CertificationModel.fromJson(data)).toList();
        _developmentData = _developmentData.copyWith(certifications: certifications);
        notifyListeners();
      });

      _setupDocumentListener(userDevCollection, 'goals', (data) {
        final List<dynamic> goalsData = data['items'] ?? [];
        final goals = goalsData.map((data) => DevelopmentGoalModel.fromJson(data)).toList();
        _developmentData = _developmentData.copyWith(goals: goals);
        notifyListeners();
      });

      _setupDocumentListener(userDevCollection, 'career_path', (data) {
        _developmentData = _developmentData.copyWith(careerPath: data);
        notifyListeners();
      });

      // Do initial data load
      _developmentData = await _devService.getUserProfessionalDevelopment();

    } catch (e) {
      _error = 'Error loading professional development data: ${e.toString()}';
      if (kDebugMode) {
        print(_error);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupDocumentListener(
      CollectionReference collection,
      String docId,
      Function(Map<String, dynamic> data) onData
      ) {
    _dataSubscriptions[docId] = collection.doc(docId).snapshots().listen(
          (docSnapshot) {
        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          onData(data);
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error listening to $docId: $error');
        }
      }
    );
  }

  // Add or update a skill
  Future<void> saveSkill({
    required String name,
    required int proficiencyLevel,
    List<String> endorsements = const [],
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      final skill = SkillModel(
        name: name,
        proficiencyLevel: proficiencyLevel,
        endorsements: endorsements,
        lastUpdated: DateTime.now(),
      );
      
      await _devService.saveSkill(skill);
      await loadDevelopmentData(); // Reload data
    } catch (e) {
      _error = 'Error saving skill: ${e.toString()}';
      if (kDebugMode) {
        print(_error);
      }
      notifyListeners();
    }
  }
  
  // Remove a skill
  Future<void> removeSkill(String skillName) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      await _devService.removeSkill(skillName);
      await loadDevelopmentData(); // Reload data
    } catch (e) {
      _error = 'Error removing skill: ${e.toString()}';
      if (kDebugMode) {
        print(_error);
      }
      notifyListeners();
    }
  }
  
  // Add or update a certification
  Future<void> saveCertification({
    required String name,
    required String issuingOrganization,
    required DateTime issueDate,
    DateTime? expiryDate,
    String? credentialUrl,
    String? credentialId,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      final certification = CertificationModel(
        name: name,
        issuingOrganization: issuingOrganization,
        issueDate: issueDate,
        expiryDate: expiryDate,
        credentialUrl: credentialUrl,
        credentialId: credentialId,
      );
      
      await _devService.saveCertification(certification);
      await loadDevelopmentData(); // Reload data
    } catch (e) {
      _error = 'Error saving certification: ${e.toString()}';
      if (kDebugMode) {
        print(_error);
      }
      notifyListeners();
    }
  }
  
  // Remove a certification
  Future<void> removeCertification(String name, String issuingOrg) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      await _devService.removeCertification(name, issuingOrg);
      await loadDevelopmentData(); // Reload data
    } catch (e) {
      _error = 'Error removing certification: ${e.toString()}';
      if (kDebugMode) {
        print(_error);
      }
      notifyListeners();
    }
  }
  
  // Add a development goal
  Future<void> addGoal({
    required String title,
    required String description,
    required DateTime targetDate,
    List<String> relatedSkills = const [],
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      final goal = DevelopmentGoalModel(
        id: '', // Will be generated in the service
        title: title,
        description: description,
        targetDate: targetDate,
        completed: false,
        relatedSkills: relatedSkills,
      );
      
      await _devService.addGoal(goal);
      await loadDevelopmentData(); // Reload data
    } catch (e) {
      _error = 'Error adding goal: ${e.toString()}';
      if (kDebugMode) {
        print(_error);
      }
      notifyListeners();
    }
  }
  
  // Update a goal
  Future<void> updateGoal(DevelopmentGoalModel goal) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      await _devService.updateGoal(goal);
      await loadDevelopmentData(); // Reload data
    } catch (e) {
      _error = 'Error updating goal: ${e.toString()}';
      if (kDebugMode) {
        print(_error);
      }
      notifyListeners();
    }
  }
  
  // Toggle goal completion status
  Future<void> toggleGoalCompletion(String goalId) async {
    final goalToUpdate = goals.firstWhere((g) => g.id == goalId);
    if (goalToUpdate != null) {
      final updatedGoal = goalToUpdate.copyWith(
        completed: !goalToUpdate.completed
      );
      await updateGoal(updatedGoal);
    }
  }
  
  // Remove a goal
  Future<void> removeGoal(String goalId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      await _devService.removeGoal(goalId);
      await loadDevelopmentData(); // Reload data
    } catch (e) {
      _error = 'Error removing goal: ${e.toString()}';
      if (kDebugMode) {
        print(_error);
      }
      notifyListeners();
    }
  }
  
  // Update career path
  Future<void> updateCareerPath(Map<String, dynamic> careerPathData) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      await _devService.updateCareerPath(careerPathData);
      await loadDevelopmentData(); // Reload data
    } catch (e) {
      _error = 'Error updating career path: ${e.toString()}';
      if (kDebugMode) {
        print(_error);
      }
      notifyListeners();
    }
  }
}