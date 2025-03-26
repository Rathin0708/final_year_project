import 'package:cloud_firestore/cloud_firestore.dart';

class SkillModel {
  final String name;
  final int proficiencyLevel; // 1-5 scale
  final List<String> endorsements;
  final DateTime lastUpdated;

  SkillModel({
    required this.name,
    required this.proficiencyLevel,
    this.endorsements = const [],
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'proficiencyLevel': proficiencyLevel,
      'endorsements': endorsements,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      name: json['name'] ?? '',
      proficiencyLevel: json['proficiencyLevel'] ?? 1,
      endorsements: List<String>.from(json['endorsements'] ?? []),
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
    );
  }
}

class CertificationModel {
  final String name;
  final String issuingOrganization;
  final DateTime issueDate;
  final DateTime? expiryDate;
  final String? credentialUrl;
  final String? credentialId;

  CertificationModel({
    required this.name,
    required this.issuingOrganization,
    required this.issueDate,
    this.expiryDate,
    this.credentialUrl,
    this.credentialId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuingOrganization': issuingOrganization,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'credentialUrl': credentialUrl,
      'credentialId': credentialId,
    };
  }

  factory CertificationModel.fromJson(Map<String, dynamic> json) {
    return CertificationModel(
      name: json['name'] ?? '',
      issuingOrganization: json['issuingOrganization'] ?? '',
      issueDate: json['issueDate'] != null 
          ? DateTime.parse(json['issueDate']) 
          : DateTime.now(),
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate']) 
          : null,
      credentialUrl: json['credentialUrl'],
      credentialId: json['credentialId'],
    );
  }
}

class DevelopmentGoalModel {
  final String id;
  final String title;
  final String description;
  final DateTime targetDate;
  final bool completed;
  final List<String> relatedSkills;
  final List<Map<String, dynamic>> milestones;

  DevelopmentGoalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDate,
    this.completed = false,
    this.relatedSkills = const [],
    this.milestones = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetDate': targetDate.toIso8601String(),
      'completed': completed,
      'relatedSkills': relatedSkills,
      'milestones': milestones,
    };
  }

  factory DevelopmentGoalModel.fromJson(Map<String, dynamic> json) {
    return DevelopmentGoalModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetDate: json['targetDate'] != null 
          ? DateTime.parse(json['targetDate']) 
          : DateTime.now().add(const Duration(days: 90)),
      completed: json['completed'] ?? false,
      relatedSkills: List<String>.from(json['relatedSkills'] ?? []),
      milestones: List<Map<String, dynamic>>.from(json['milestones'] ?? []),
    );
  }

  DevelopmentGoalModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? targetDate,
    bool? completed,
    List<String>? relatedSkills,
    List<Map<String, dynamic>>? milestones,
  }) {
    return DevelopmentGoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      completed: completed ?? this.completed,
      relatedSkills: relatedSkills ?? this.relatedSkills,
      milestones: milestones ?? this.milestones,
    );
  }
}

class ProfessionalDevelopmentModel {
  final List<SkillModel> skills;
  final List<CertificationModel> certifications;
  final List<DevelopmentGoalModel> goals;
  final Map<String, dynamic> careerPath;

  ProfessionalDevelopmentModel({
    this.skills = const [],
    this.certifications = const [],
    this.goals = const [],
    this.careerPath = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'skills': skills.map((skill) => skill.toJson()).toList(),
      'certifications': certifications.map((cert) => cert.toJson()).toList(),
      'goals': goals.map((goal) => goal.toJson()).toList(),
      'careerPath': careerPath,
    };
  }

  factory ProfessionalDevelopmentModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalDevelopmentModel(
      skills: (json['skills'] as List<dynamic>?)
          ?.map((skill) => SkillModel.fromJson(skill))
          .toList() ?? [],
      certifications: (json['certifications'] as List<dynamic>?)
          ?.map((cert) => CertificationModel.fromJson(cert))
          .toList() ?? [],
      goals: (json['goals'] as List<dynamic>?)
          ?.map((goal) => DevelopmentGoalModel.fromJson(goal))
          .toList() ?? [],
      careerPath: json['careerPath'] ?? {},
    );
  }

  ProfessionalDevelopmentModel copyWith({
    List<SkillModel>? skills,
    List<CertificationModel>? certifications,
    List<DevelopmentGoalModel>? goals,
    Map<String, dynamic>? careerPath,
  }) {
    return ProfessionalDevelopmentModel(
      skills: skills ?? this.skills,
      certifications: certifications ?? this.certifications,
      goals: goals ?? this.goals,
      careerPath: careerPath ?? this.careerPath,
    );
  }
}