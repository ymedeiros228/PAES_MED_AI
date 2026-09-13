import 'package:flutter_test/flutter_test.dart';
import 'package:paes_med_ai/core/widgets/flashcard_images.dart';

void main() {
  test('mapeia Biologia/Genética para capa local', () {
    expect(flashcardImageFilename('Biologia', 'Genética'), 'bi_gene_capa.jpg');
    expect(
      flashcardImagePath('Biologia', 'Genética'),
      '/api/materials/imagens/bi_gene_capa.jpg',
    );
    expect(
      flashcardImageUrl('http://127.0.0.1:8000', 'Biologia', 'Genética'),
      'http://127.0.0.1:8000/api/materials/imagens/bi_gene_capa.jpg',
    );
  });

  test('matéria desconhecida retorna null', () {
    expect(flashcardImageFilename('Astronomia', 'Órbitas'), isNull);
    expect(flashcardImagePath('Astronomia', 'Órbitas'), isNull);
  });

  test('fallback de tópico usa primeira capa da matéria', () {
    final name = flashcardImageFilename('Biologia', 'Assunto inventado XYZ');
    expect(name, isNotNull);
    expect(name!.startsWith('bi_'), isTrue);
  });
}
