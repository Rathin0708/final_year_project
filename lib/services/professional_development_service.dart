import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/professional_development_model.dart';
import 'package:uuid/uuid.dart';

class ProfessionalDevelopmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();
  
  // Get collection reference for a user's professional development data
  CollectionReference _getUserDevCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('professional_development');
  }
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Fetch all professional development data for the current user
  Future<ProfessionalDevelopmentModel> getUserProfessionalDevelopment() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get skills
      final skillsSnapshot = await _getUserDevCollection(userId).doc('skills').get();
      final List<dynamic> skillsData = skillsSnapshot.exists ? skillsSnapshot.get('items') ?? [] : [];
      final List<SkillModel> skills = skillsData.map((data) => SkillModel.fromJson(data)).toList();
      
      // Get certifications
      final certsSnapshot = await _getUserDevCollection(userId).doc('certifications').get();
      final List<dynamic> certsData = certsSnapshot.exists ? certsSnapshot.get('items') ?? [] : [];
      final List<CertificationModel> certifications = certsData.map((data) => CertificationModel.fromJson(data)).toList();
      
      // Get goals
      final goalsSnapshot = await _getUserDevCollection(userId).doc('goals').get();
      final List<dynamic> goalsData = goalsSnapshot.exists ? goalsSnapshot.get('items') ?? [] : [];
      final List<DevelopmentGoalModel> goals = goalsData.map((data) => DevelopmentGoalModel.fromJson(data)).toList();
      
      // Get career path
      final careerSnapshot = await _getUserDevCollection(userId).doc('career_path').get();
      final Map<String, dynamic> careerPath = careerSnapshot.exists ? careerSnapshot.data() as Map<String, dynamic> : {};
      
      return ProfessionalDevelopmentModel(
        skills: skills,
        certifications: certifications,
        goals: goals,
        careerPath: careerPath,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching professional development data: $e');
      }
      rethrow;
    }
  }
  
  // Add or update a skill
  Future<void> saveSkill(SkillModel skill) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final skillsDocRef = _getUserDevCollection(userId).doc('skills');
      
      // Get current skills
      final snapshot = await skillsDocRef.get();
      final List<dynamic> currentSkills = snapshot.exists ? snapshot.get('items') ?? [] : [];
      
      // Check if skill already exists and update it, or add a new one
      bool skillExists = false;
      final updatedSkills = currentSkills.map((data) {
        final existingSkill = SkillModel.fromJson(data);
        if (existingSkill.name.toLowerCase() == skill.name.toLowerCase()) {
          skillExists = true;
          return skill.toJson();
        }
        return data;
      }).toList();
      
      // If skill doesn't exist, add it
      if (!skillExists) {
        updatedSkills.add(skill.toJson());
      }
      
      // Save the updated skills list
      await skillsDocRef.set({'items': updatedSkills}, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving skill: $e');
      }
      rethrow;
    }
  }
  
  // Remove a skill
  Future<void> removeSkill(String skillName) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final skillsDocRef = _getUserDevCollection(userId).doc('skills');
      
      // Get current skills
      final snapshot = await skillsDocRef.get();
      final List<dynamic> currentSkills = snapshot.exists ? snapshot.get('items') ?? [] : [];
      
      // Filter out the skill to remove
      final updatedSkills = currentSkills.where((data) {
        final skill = SkillModel.fromJson(data);
        return skill.name.toLowerCase() != skillName.toLowerCase();
      }).toList();
      
      // Save the updated skills list
      await skillsDocRef.set({'items': updatedSkills}, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error removing skill: $e');
      }
      rethrow;
    }
  }
  
  // Add or update a certification
  Future<void> saveCertification(CertificationModel certification) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final certsDocRef = _getUserDevCollection(userId).doc('certifications');
      
      // Get current certifications
      final snapshot = await certsDocRef.get();
      final List<dynamic> currentCerts = snapshot.exists ? snapshot.get('items') ?? [] : [];
      
      // Check if certification already exists and update it, or add a new one
      bool certExists = false;
      final updatedCerts = currentCerts.map((data) {
        final existingCert = CertificationModel.fromJson(data);
        if (existingCert.name.toLowerCase() == certification.name.toLowerCase() && 
            existingCert.issuingOrganization.toLowerCase() == certification.issuingOrganization.toLowerCase()) {
          certExists = true;
          return certification.toJson();
        }
        return data;
      }).toList();
      
      // If certification doesn't exist, add it
      if (!certExists) {
        updatedCerts.add(certification.toJson());
      }
      
      // Save the updated certifications list
      await certsDocRef.set({'items': updatedCerts}, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving certification: $e');
      }
      rethrow;
    }
  }
  
  // Remove a certification
  Future<void> removeCertification(String certName, String issuingOrg) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final certsDocRef = _getUserDevCollection(userId).doc('certifications');
      
      // Get current certifications
      final snapshot = await certsDocRef.get();
      final List<dynamic> currentCerts = snapshot.exists ? snapshot.get('items') ?? [] : [];
      
      // Filter out the certification to remove
      final updatedCerts = currentCerts.where((data) {
        final cert = CertificationModel.fromJson(data);
        return !(cert.name.toLowerCase() == certName.toLowerCase() && 
               cert.issuingOrganization.toLowerCase() == issuingOrg.toLowerCase());
      }).toList();
      
      // Save the updated certifications list
      await certsDocRef.set({'items': updatedCerts}, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error removing certification: $e');
      }
      rethrow;
    }
  }
  
  // Add a development goal
  Future<DevelopmentGoalModel> addGoal(DevelopmentGoalModel goal) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final goalsDocRef = _getUserDevCollection(userId).doc('goals');
      
      // Generate a unique ID if not provided
      final goalWithId = goal.id.isNotEmpty ? goal : 
        DevelopmentGoalModel(
          id: _uuid.v4(),
          title: goal.title,
          description: goal.description, 
          targetDate: goal.targetDate,
          completed: goal.completed,
          relatedSkills: goal.relatedSkills,
          milestones: goal.milestones,
        );
      
      // Get current goals
      final snapshot = await goalsDocRef.get();
      final List<dynamic> currentGoals = snapshot.exists ? snapshot.get('items') ?? [] : [];
      
      // Add the new goal
      currentGoals.add(goalWithId.toJson());
      
      // Save the updated goals list
      await goalsDocRef.set({'items': currentGoals}, SetOptions(merge: true));
      
      return goalWithId;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding goal: $e');
      }
      rethrow;
    }
  }
  
  // Update a development goal
  Future<void> updateGoal(DevelopmentGoalModel goal) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final goalsDocRef = _getUserDevCollection(userId).doc('goals');
      
      // Get current goals
      final snapshot = await goalsDocRef.get();
      final List<dynamic> currentGoals = snapshot.exists ? snapshot.get('items') ?? [] : [];
      
      // Check if goal exists and update it
      bool goalExists = false;
      final updatedGoals = currentGoals.map((data) {
        final existingGoal = DevelopmentGoalModel.fromJson(data);
        if (existingGoal.id == goal.id) {
          goalExists = true;
          return goal.toJson();
        }
        return data;
      }).toList();
      
      if (!goalExists) {
        throw Exception('Goal not found');
      }
      
      // Save the updated goals list
      await goalsDocRef.set({'items': updatedGoals}, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error updating goal: $e');
      }
      rethrow;
    }
  }
  
  // Remove a development goal
  Future<void> removeGoal(String goalId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final goalsDocRef = _getUserDevCollection(userId).doc('goals');
      
      // Get current goals
      final snapshot = await goalsDocRef.get();
      final List<dynamic> currentGoals = snapshot.exists ? snapshot.get('items') ?? [] : [];
      
      // Filter out the goal to remove
      final updatedGoals = currentGoals.where((data) {
        final goal = DevelopmentGoalModel.fromJson(data);
        return goal.id != goalId;
      }).toList();
      
      // Save the updated goals list
      await goalsDocRef.set({'items': updatedGoals}, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error removing goal: $e');
      }
      rethrow;
    }
  }
  
  // Update career path
  Future<void> updateCareerPath(Map<String, dynamic> careerPathData) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final careerDocRef = _getUserDevCollection(userId).doc('career_path');
      
      // Save the career path data
      await careerDocRef.set(careerPathData, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error updating career path: $e');
      }
      rethrow;
    }
  }
}