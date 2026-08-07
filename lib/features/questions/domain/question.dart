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
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty) {
      throw FormatException('question id empty');
    }
    final yearRaw = json['year'];
    final year = yearRaw is int
        ? yearRaw
        : yearRaw is num
            ? yearRaw.toInt()
            : int.tryParse(yearRaw?.toString() ?? '') ?? 0;
    final ciRaw = json['correctIndex'] ?? json['correct_index'];
    final correctIndex = ciRaw is int
        ? ciRaw
        : ciRaw is num
            ? ciRaw.toInt()
            : int.tryParse(ciRaw?.toString() ?? '') ?? 0;
    final opts = json['options'];
    final options = opts is List
        ? opts.map((e) => e.toString()).toList()
        : <String>[];
    return Question(
      id: id,
      year: year,
      subject: json['subject']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      subtopic: json['subtopic']?.toString(),
      statement: json['statement']?.toString() ?? '',
      options: options,
      correctIndex: correctIndex,
      difficulty: json['difficulty']?.toString() ?? 'Média',
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      resolution: json['resolution']?.toString(),
      bancaIntent: json['bancaIntent']?.toString(),
      macete: json['macete']?.toString(),
      pegadinha: json['pegadinha']?.toString(),
      relatedTopics: (json['relatedTopics'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      keywords: (json['keywords'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      professorMode: json['professorMode'] is Map
          ? Map<String, dynamic>.from(json['professorMode'] as Map)
          : null,
      generated: json['generated'] == true,
      approved: json['approved'] != false,
      source: json['source']?.toString(),
      sourcePdf: json['sourcePdf']?.toString(),
      examBoard: (json['examBoard']?.toString().isNotEmpty == true)
          ? json['examBoard'].toString()
          : 'TREINO',
      similarityOf: json['similarityOf']?.toString(),
      similarityNote: json['similarityNote']?.toString(),
      resolutionQuality: json['resolutionQuality']?.toString(),
      resolutionAxes: json['resolutionAxes'] is Map
          ? Map<String, dynamic>.from(json['resolutionAxes'] as Map)
          : null,
      studentResolutionLabel: json['studentResolutionLabel']?.toString(),
    );
  }
}
