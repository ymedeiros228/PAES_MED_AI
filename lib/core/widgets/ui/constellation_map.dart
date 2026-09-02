import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'layout_tokens.dart';

/// Constelação de Conhecimento — gamificação do progresso de estudo.
///
/// Renderiza um céu estrelado onde cada dia ativo de estudo vira uma estrela
/// que brilha, e dias inativos ficam como pontos escuros. As estrelas se
/// conectam em uma "constelação" que cresce conforme o streak aumenta.
/// O título/nível muda conforme o número de dias seguidos:
/// 0-2: "Explorador" · 3-6: "Observador" · 7-13: "Astrônomo" ·
/// 14-29: "Cartógrafo" · 30+: "Mestre das Estrelas"
class ConstellationMap extends StatefulWidget {
  const ConstellationMap({
    required this.activeDays,
    required this.streakDays,
    required this.totalDays,
    required this.accuracy,
    super.key,
  });

  /// Lista de dias ativos (índice 0 = mais antigo, último = mais recente).
  /// Cada item é true se houve estudo naquele dia, false caso contrário.
  final List<bool> activeDays;

  /// Dias seguidos (streak atual).
  final int streakDays;

  /// Total de dias no período (ex: 28).
  final int totalDays;

  /// Acurácia atual (0.0 a 1.0) — afeta o brilho das estrelas.

  final double accuracy;

  @override
  State<ConstellationMap> createState() => _ConstellationMapState();
}

class _ConstellationMapState extends State<ConstellationMap>
    with TickerProviderStateMixin {
  late final AnimationController _twinkle;
  late final AnimationController _grow;
  late final AnimationController _shootingStar;
  late final Listenable _animations;
  Timer? _shootingStarTimer;

  @override
  void initState() {
    super.initState();
    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _grow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _shootingStar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    // Listenable.merge criado UMA VEZ — AnimatedBuilder mantém referência estável
    _animations = Listenable.merge([_twinkle, _grow, _shootingStar]);
    // Listener único para agendar próxima estrela cadente
    _shootingStar.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _scheduleNextShootingStar();
      }
    });
    _scheduleNextShootingStar();
  }

  void _scheduleNextShootingStar() {
    final delay = Duration(seconds: 10 + DateTime.now().millisecond % 8);
    _shootingStarTimer = Timer(delay, _fireShootingStar);
  }

  void _fireShootingStar() {
    if (!mounted) return;
    _shootingStar
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _shootingStarTimer?.cancel();
    _twinkle.dispose();
    _grow.dispose();
    _shootingStar.dispose();
    super.dispose();
  }

  String _levelTitle() {
    final s = widget.streakDays;
    if (s >= 30) return 'Mestre das Estrelas';
    if (s >= 14) return 'Cartógrafo Celeste';
    if (s >= 7) return 'Astrônomo';
    if (s >= 3) return 'Observador';
    return 'Explorador';
  }

  String _levelHint() {
    final s = widget.streakDays;
    if (s >= 30) return '30+ dias seguidos — constelação completa';
    if (s >= 14) return '14+ dias — mapeando o céu inteiro';
    if (s >= 7) return '7+ dias — as estrelas formam figuras';
    if (s >= 3) return '3+ dias — começando a enxergar padrões';
    return 'Estude 3 dias seguidos para subir de nível';
  }

  (Color, Color) _levelColors() {
    final s = widget.streakDays;
    if (s >= 30) return (const Color(0xFFFFD700), const Color(0xFFFFA500));
    if (s >= 14) return (const Color(0xFFB39DDB), const Color(0xFF7E57C2));
    if (s >= 7) return (const Color(0xFF4FC3F7), const Color(0xFF0288D1));
    if (s >= 3) return (const Color(0xFF80CBC4), const Color(0xFF00897B));
    return (const Color(0xFF90A4AE), const Color(0xFF546E7A));
  }

  @override
  Widget build(BuildContext context) {
    final (starColor, lineColor) = _levelColors();
    final title = _levelTitle();
    final hint = _levelHint();

    // Grid de estrelas: 7 colunas (dias da semana) x N linhas
    final cols = 7;
    final rows = (widget.totalDays / cols).ceil();
    final activeCount = widget.activeDays.where((a) => a).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF080B1F),
            const Color(0xFF11142E),
            const Color(0xFF0A0D20),
          ],
        ),
        borderRadius: BorderRadius.circular(kRadiusPanel),
        border: Border.all(color: starColor.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho minimalista
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Título do nível com fonte serif elegante
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF0F2F8),
                        letterSpacing: 0.2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.42),
                        height: 1.3,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge de streak minimalista
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: starColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: starColor.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded, size: 13, color: starColor),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.streakDays}d',
                      style: TextStyle(
                        color: starColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Céu estrelado — AnimatedBuilder com Listenable estável
          SizedBox(
            height: rows * 36.0,
            child: AnimatedBuilder(
              animation: _animations,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ConstellationPainter(
                    activeDays: widget.activeDays,
                    cols: cols,
                    rows: rows,
                    starColor: starColor,
                    lineColor: lineColor,
                    twinkleValue: _twinkle.value,
                    growValue: Curves.easeOutCubic.transform(_grow.value),
                    accuracy: widget.accuracy,
                    // -1 quando inativa (value=0 e não animando), senão progresso 0..1
                    shootingStarProgress:
                        _shootingStar.isAnimating ? _shootingStar.value : -1,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Rodapé com estatísticas — mais limpo e espaçado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatChip(
                icon: Icons.star_rounded,
                value: '$activeCount',
                label: 'estrelas',
                color: starColor,
              ),
              _StatChip(
                icon: Icons.whatshot_rounded,
                value: '${widget.streakDays}',
                label: 'streak',
                color: starColor,
              ),
              _StatChip(
                icon: Icons.gps_fixed_rounded,
                value: '${(widget.accuracy * 100).toStringAsFixed(0)}%',
                label: 'acerto',
                color: starColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.withOpacity(0.6)),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFFF0F2F8),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// Painter que desenha o céu estrelado com constelação.
class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({
    required this.activeDays,
    required this.cols,
    required this.rows,
    required this.starColor,
    required this.lineColor,
    required this.twinkleValue,
    required this.growValue,
    required this.accuracy,
    required this.shootingStarProgress,
  });

  final List<bool> activeDays;
  final int cols;
  final int rows;
  final Color starColor;
  final Color lineColor;
  final double twinkleValue;
  final double growValue;
  final double accuracy;
  // -1 = sem estrela cadente; 0..1 = progresso da travessia
  final double shootingStarProgress;

  @override
  void paint(Canvas canvas, Size size) {
    // Guard: se o size for muito pequeno, não desenha nada (evita crash)
    if (size.width < 10 || size.height < 10) return;

    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final starRadius = (cellW * 0.14).clamp(2.5, 6.0);

    // Nebulosa sutil de fundo para profundidade
    _drawNebula(canvas, size);

    // Estrelas de fundo (cosmo) — pontos minúsculos fixos
    _drawBackgroundStars(canvas, size);

    // Estrela cadente (se ativa)
    if (shootingStarProgress >= 0 && shootingStarProgress <= 1.0) {
      _drawShootingStar(canvas, size, shootingStarProgress);
    }

    // Posições das estrelas ativas
    final starPositions = <Offset>[];

    // Primeiro desenha os pontos escuros (dias inativos)
    for (var i = 0; i < activeDays.length && i < cols * rows; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      final cx = col * cellW + cellW / 2;
      final cy = row * cellH + cellH / 2;
      final center = Offset(cx, cy);

      if (!activeDays[i]) {
        // Dia inativo: ponto minúsculo e discreto
        final paint = Paint()
          ..color = Colors.white.withOpacity(0.05)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, starRadius * 0.25, paint);
      }
    }

    // Coleta posições das estrelas ativas
    for (var i = 0; i < activeDays.length && i < cols * rows; i++) {
      if (!activeDays[i]) continue;
      final row = i ~/ cols;
      final col = i % cols;
      final cx = col * cellW + cellW / 2;
      final cy = row * cellH + cellH / 2;
      starPositions.add(Offset(cx, cy));
    }

    // Desenha linhas curvas (Bezier) entre estrelas consecutivas ativas
    if (starPositions.length >= 2) {
      for (var i = 0; i < starPositions.length - 1; i++) {
        final p1 = starPositions[i];
        final p2 = starPositions[i + 1];
        // Só conecta se estiverem próximos
        final dist = (p2 - p1).distance;
        if (dist < cellW * 2.8) {
          _drawCurvedLine(canvas, p1, p2, growValue);
        }
      }
    }

    // Por fim desenha as estrelas ativas (por cima das linhas)
    for (var i = 0; i < starPositions.length; i++) {
      final pos = starPositions[i];
      // Cada estrela pisca em momento diferente
      final phase = (i * 0.37) % 1.0;
      final twinkle = 0.5 + 0.5 * ((twinkleValue + phase) % 1.0);
      final intensity = (0.4 + 0.6 * twinkle) * growValue;

      // Halo/glow multi-camada ao redor da estrela
      _drawStarGlow(canvas, pos, starRadius, starColor, intensity, twinkle);

      // Estrela de 5 pontas
      _drawStarShape(
        canvas,
        pos,
        starRadius * (0.7 + 0.3 * twinkle),
        starColor.withOpacity(0.95 * intensity),
      );

      // Brilho central branco
      final whitePaint = Paint()
        ..color = Colors.white.withOpacity(0.9 * intensity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, starRadius * 0.28 * twinkle, whitePaint);
    }
  }

  /// Desenha uma nebulosa sutil para dar profundidade ao fundo.
  void _drawNebula(Canvas canvas, Size size) {
    final r1 = size.width * 0.45;
    if (r1 > 1) {
      final nebula1Paint = Paint()
        ..shader = RadialGradient(
          colors: [
            lineColor.withOpacity(0.04),
            lineColor.withOpacity(0.01),
            lineColor.withOpacity(0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.15, size.height * 0.1),
          radius: r1,
        ));
      canvas.drawRect(Offset.zero & size, nebula1Paint);
    }

    final r2 = size.width * 0.35;
    if (r2 > 1) {
      final nebula2Paint = Paint()
        ..shader = RadialGradient(
          colors: [
            starColor.withOpacity(0.03),
            starColor.withOpacity(0.008),
            starColor.withOpacity(0),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.9),
          radius: r2,
        ));
      canvas.drawRect(Offset.zero & size, nebula2Paint);
    }
  }

  /// Desenha estrelas de fundo minúsculas (cosmo) com posições determinísticas.
  void _drawBackgroundStars(Canvas canvas, Size size) {
    final rng = _SeededRandom(size.width.toInt() * 31 + size.height.toInt());
    final bgStarPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 50; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.4 + rng.nextDouble() * 1.0;
      // Piscar suavemente
      final phase = (i * 0.13) % 1.0;
      final alpha = 0.06 + 0.10 * ((twinkleValue + phase) % 1.0);
      bgStarPaint.color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), r, bgStarPaint);
    }
  }

  /// Desenha uma linha curva (Bezier quadrática) entre dois pontos.
  /// A curva dá um arco orgânico, como constelações reais.
  void _drawCurvedLine(Canvas canvas, Offset p1, Offset p2, double grow) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 1) return; // pontos muito próximos — não desenha linha

    // Ponto de controle: perpendicular ao midpoint, deslocado suavemente
    final mid = Offset.lerp(p1, p2, 0.5)!;
    final perpX = -dy / len;
    final perpY = dx / len;
    // Deslocamento sutil (10% da distância)
    final offset = len * 0.08;
    final control = Offset(
      mid.dx + perpX * offset,
      mid.dy + perpY * offset,
    );

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..quadraticBezierTo(control.dx, control.dy, p2.dx, p2.dy);

    // Anima a linha crescendo com um PathMetric
    final paint = Paint()
      ..color = lineColor.withOpacity(0.15 * grow)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (grow >= 0.99) {
      canvas.drawPath(path, paint);
    } else {
      // Desenha parcialmente usando PathMetric
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final extracted = metric.extractPath(0, metric.length * grow);
        canvas.drawPath(extracted, paint);
      }
    }
  }

  /// Desenha o glow multi-camada ao redor de uma estrela.
  void _drawStarGlow(
    Canvas canvas,
    Offset pos,
    double radius,
    Color color,
    double intensity,
    double twinkle,
  ) {
    if (intensity <= 0) return;

    // Camada externa: glow amplo e suave
    final outerRadius = radius * 3.0 * intensity;
    if (outerRadius > 0.5) {
      final outerPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.10 * intensity),
            color.withOpacity(0.03 * intensity),
            color.withOpacity(0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: pos, radius: outerRadius));
      canvas.drawCircle(pos, outerRadius, outerPaint);
    }

    // Camada interna: glow mais concentrado
    final innerRadius = radius * 1.5 * intensity;
    if (innerRadius > 0.5) {
      final innerPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.25 * intensity),
            color.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: pos, radius: innerRadius));
      canvas.drawCircle(pos, innerRadius, innerPaint);
    }
  }

  /// Desenha uma estrela de 5 pontas usando Path.
  void _drawStarShape(Canvas canvas, Offset center, double radius, Color color) {
    if (radius < 0.5) return;
    final path = Path();
    const points = 5;
    const innerRatio = 0.4; // razão entre raio interno e externo
    for (var i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - pi / 2; // começa apontando para cima
      final r = i.isEven ? radius : radius * innerRatio;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  /// Desenha uma estrela cadente que cruza o céu diagonalmente.
  void _drawShootingStar(Canvas canvas, Size size, double progress) {
    // Trajetória: canto sup-esq para inf-dir
    final startX = size.width * 0.05;
    final startY = size.height * 0.1;
    final endX = size.width * 0.95;
    final endY = size.height * 0.7;
    final headX = startX + (endX - startX) * progress;
    final headY = startY + (endY - startY) * progress;

    // Cauda: gradient path
    final tailLen = 80.0;
    final dx = (endX - startX) / ((endX - startX).abs() + 0.01);
    final dy = (endY - startY) / ((endY - startY).abs() + 0.01);
    final dirLen = (Offset(dx, dy).distance);
    final ndx = dx / dirLen;
    final ndy = dy / dirLen;

    // Cauda: pontos com gradiente de opacidade (mais suave)
    for (var i = 0; i < 16; i++) {
      final t = i / 16.0;
      final tailX = headX - ndx * tailLen * t;
      final tailY = headY - ndy * tailLen * t;
      final alpha = (1.0 - t) * 0.5 * (1.0 - (progress * 0.4));
      final paint = Paint()
        ..color = Colors.white.withOpacity(alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tailX, tailY), 1.8 * (1.0 - t * 0.6), paint);
    }

    // Cabeça brilhante
    final headPaint = Paint()
      ..color = Colors.white.withOpacity(0.95 * (1.0 - progress * 0.3))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(headX, headY), 2.5, headPaint);

    // Halo da cabeça
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.5 * (1.0 - progress * 0.3)),
          Colors.white.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(headX, headY), radius: 14));
    canvas.drawCircle(Offset(headX, headY), 14, haloPaint);
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) =>
      oldDelegate.twinkleValue != twinkleValue ||
      oldDelegate.growValue != growValue ||
      oldDelegate.shootingStarProgress != shootingStarProgress;
}

/// Gerador pseudo-aleatório simples com seed determinística.
class _SeededRandom {
  _SeededRandom(this.seed);
  final int seed;
  int _state = 0;

  double nextDouble() {
    _state = (_state + 1) * 1103515245 + seed;
    return ((_state & 0x7FFFFFFF) / 0x7FFFFFFF).toDouble();
  }
}
