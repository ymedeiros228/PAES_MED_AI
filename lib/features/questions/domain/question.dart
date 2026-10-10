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

  /// Tolerante a nulos/tipos trocados: um único campo ruim (ex.: `year` nulo
  /// numa questão importada) não pode derrubar a lista inteira de questões.
  factory Question.fromJson(Map<String, dynamic> json) {
    String str(Object? v, [String fallback = '']) => v?.toString() ?? fallback;
    String? strOrNull(Object? v) => v?.toString();
    int toInt(Object? v, [int fallback = 0]) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? fallback;
    List<String> strList(Object? v) =>
        v is List ? v.map((e) => e.toString()).toList() : const <String>[];
    final mapRaw = json['professorMode'];
    return Question(
      id: str(json['id']),
      year: toInt(json['year']),
      subject: str(json['subject'], 'Geral'),
      topic: str(json['topic'], 'Geral'),
      subtopic: strOrNull(json['subtopic']),
      statement: str(json['statement']),
      options: strList(json['options']),
      correctIndex: toInt(json['correctIndex'] ?? json['correct_index'], -1),
      difficulty: str(json['difficulty'], 'media'),
      tags: strList(json['tags']),
      resolution: strOrNull(json['resolution']),
      bancaIntent: strOrNull(json['bancaIntent']),
      macete: strOrNull(json['macete']),
      pegadinha: strOrNull(json['pegadinha']),
      relatedTopics: strList(json['relatedTopics']),
      keywords: strList(json['keywords']),
      professorMode: mapRaw is Map ? Map<String, dynamic>.from(mapRaw) : null,
      generated: json['generated'] == true,
      approved: json['approved'] != false,
      source: strOrNull(json['source']),
      sourcePdf: strOrNull(json['sourcePdf']),
      examBoard: strOrNull(json['examBoard']) ?? 'TREINO',
      similarityOf: strOrNull(json['similarityOf']),
      similarityNote: strOrNull(json['similarityNote']),
      resolutionQuality: strOrNull(json['resolutionQuality']),
      resolutionAxes: json['resolutionAxes'] is Map
          ? Map<String, dynamic>.from(json['resolutionAxes'] as Map)
          : null,
      studentResolutionLabel: strOrNull(json['studentResolutionLabel']),
    );
  }
}
