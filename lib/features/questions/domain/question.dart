class Question {
  const Question({
    required this.id,
    required this.year,
    required this.subject,
    required this.topic,
    required this.statement,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    this.subtopic,
    this.tags = const [],
    this.resolution,
    this.bancaIntent,
    this.macete,
    this.pegadinha,
    this.relatedTopics = const [],
    this.keywords = const [],
    this.professorMode,
    this.generated = false,
    this.approved = true,
    this.source,
    this.sourcePdf,
    this.examBoard = 'TREINO',
    this.similarityOf,
    this.similarityNote,
    this.resolutionQuality,
    this.resolutionAxes,
    this.studentResolutionLabel,
  });

  final String id;
  final int year;
  final String subject;
  final String topic;
  final String? subtopic;
  final String statement;
  final List<String> options;
  final int correctIndex;
  final String difficulty;
  final List<String> tags;
  final String? resolution;
  final String? bancaIntent;
  final String? macete;
  final String? pegadinha;
  final List<String> relatedTopics;
  final List<String> keywords;
  final Map<String, dynamic>? professorMode;
  final bool generated;
  final bool approved;
  final String? source;
  final String? sourcePdf;
  final String examBoard;
  final String? similarityOf;
  final String? similarityNote;
  final String? resolutionQuality;
  final Map<String, dynamic>? resolutionAxes;
  final String? studentResolutionLabel;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      year: json['year'] as int,
      subject: json['subject'] as String,
      topic: json['topic'] as String,
      subtopic: json['subtopic'] as String?,
      statement: json['statement'] as String,
      options: (json['options'] as List<dynamic>).map((e) => e.toString()).toList(),
      correctIndex: json['correctIndex'] as int,
      difficulty: json['difficulty'] as String,
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      resolution: json['resolution'] as String?,
      bancaIntent: json['bancaIntent'] as String?,
      macete: json['macete'] as String?,
      pegadinha: json['pegadinha'] as String?,
      relatedTopics: (json['relatedTopics'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      keywords: (json['keywords'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      professorMode: json['professorMode'] as Map<String, dynamic>?,
      generated: json['generated'] == true,
      approved: json['approved'] != false,
      source: json['source'] as String?,
      sourcePdf: json['sourcePdf'] as String?,
      examBoard: (json['examBoard'] as String?) ?? 'TREINO',
      similarityOf: json['similarityOf'] as String?,
      similarityNote: json['similarityNote'] as String?,
      resolutionQuality: json['resolutionQuality'] as String?,
      resolutionAxes: json['resolutionAxes'] is Map
          ? Map<String, dynamic>.from(json['resolutionAxes'] as Map)
          : null,
      studentResolutionLabel: json['studentResolutionLabel'] as String?,
    );
  }
}
