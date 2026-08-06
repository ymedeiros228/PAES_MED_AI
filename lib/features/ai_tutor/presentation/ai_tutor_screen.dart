import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paes_med_ai/features/ai_tutor/application/ai_tutor_controller.dart';
import 'package:paes_med_ai/features/ai_tutor/domain/chat_message.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/study_prefs_providers.dart';
import '../../../core/data/theory_reads.dart';
import '../../../core/widgets/theory_topic_sheet.dart';
import '../../../core/widgets/ui_kit.dart';

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({
    super.key,
    this.seedSubject,
    this.seedTopic,
    this.seedQuery,
  });

  final String? seedSubject;
  final String? seedTopic;
  final String? seedQuery;

  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _seedApplied = false;
  bool? _openaiConfigured;
  bool _healthLoaded = false;
  int? _localMaterialCount;
  bool _materialChecked = false;
  Map<String, bool> theoryReadByKey = {};

  bool _isTheoryRead(String subject, String topic) =>
      theoryReadByKey[theoryReadKey(subject, topic)] == true;

  Future<void> _loadSeedRead() async {
    final sub = widget.seedSubject?.trim() ?? '';
    final top = widget.seedTopic?.trim() ?? '';
    if (sub.isEmpty || top.isEmpty) return;
    final out = await fetchTheoryReadMap([(sub, top)]);
    if (mounted) setState(() => theoryReadByKey = out);
  }

  static const _styles = <(String, String)>[
    ('professor', 'Professor'),
    ('macete', 'Macete'),
    ('resumo', 'Resumo'),
    ('analogia', 'Analogia'),
    ('mapa', 'Mapa'),
    ('flashcard', 'Flashcard'),
    ('medico', 'Médico'),
    ('crianca', 'Simples'),
  ];

  @override
  void initState() {
    super.initState();
    _loadHealth();
    _loadMaterialHint();
    _loadSeedRead();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyRouteSeed());
  }

  Future<void> _loadMaterialHint() async {
    final sub = widget.seedSubject?.trim() ?? '';
    final top = widget.seedTopic?.trim() ?? '';
    if (sub.isEmpty || top.isEmpty) {
      if (mounted) setState(() {
        _localMaterialCount = null;
        _materialChecked = true;
      });
      return;
    }
    try {
      final data = await apiClient.get('/api/library/materials', {'subject': sub, 'topic': top});
      final map = Map<String, dynamic>.from(data as Map);
      final n = (map['items'] as List? ?? []).length;
      if (mounted) setState(() {
        _localMaterialCount = n;
        _materialChecked = true;
      });
    } catch (_) {
      if (mounted) setState(() {
        _localMaterialCount = 0;
        _materialChecked = true;
      });
    }
  }

  void _openLocalMaterial() {
    final sub = widget.seedSubject?.trim() ?? '';
    final top = widget.seedTopic?.trim() ?? '';
    if (sub.isEmpty || top.isEmpty) return;
    TheoryTopicSheet.show(
      context,
      subject: sub,
      topic: top,
      onMarkedRead: () {
        if (mounted) setState(() => theoryReadByKey[theoryReadKey(sub, top)] = true);
      },
    );
  }

  String get _materialChipLabel {
    final sub = widget.seedSubject?.trim() ?? '';
    final top = widget.seedTopic?.trim() ?? '';
    final n = _localMaterialCount ?? 0;
    if (sub.isNotEmpty && top.isNotEmpty && _isTheoryRead(sub, top)) {
      return n > 0 ? 'Material local ($n) · Li' : 'Teoria local · Li';
    }
    return n > 0 ? 'Material local ($n)' : 'Teoria local';
  }

  Future<void> _loadHealth() async {
    try {
      final data = await apiClient.get('/health');
      final map = Map<String, dynamic>.from(data as Map);
      if (!mounted) return;
      setState(() {
        _openaiConfigured = map['openai_configured'] == true;
        _healthLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _openaiConfigured = false;
        _healthLoaded = true;
      });
    }
  }

  bool get _offlineMode {
    final tutorOn = ref.read(tutorOnlinePrefProvider);
    return _openaiConfigured != true || !tutorOn;
  }

  String get _offlineBannerText {
    if (_openaiConfigured != true) {
      return 'Modo offline — trechos da base local. OPENAI_API_KEY em backend/.env para diálogo completo.';
    }
    if (!ref.read(tutorOnlinePrefProvider)) {
      return 'IA online desligada em Ajustes — respostas só com material local.';
    }
    return '';
  }

  void _applyRouteSeed() {
    if (_seedApplied || !mounted) return;
    if (_controller.text.trim().isNotEmpty) {
      _seedApplied = true;
      return;
    }
    final sub = widget.seedSubject?.trim() ?? '';
    final top = widget.seedTopic?.trim() ?? '';
    final q = widget.seedQuery?.trim() ?? '';
    if (sub.isEmpty && top.isEmpty && q.isEmpty) {
      _seedApplied = true;
      return;
    }
    final buf = StringBuffer();
    if (sub.isNotEmpty || top.isNotEmpty) {
      buf.write('Sobre ${sub.isEmpty ? '—' : sub}');
      if (top.isNotEmpty) buf.write(' · $top');
      buf.writeln('.');
    }
    if (q.isNotEmpty) {
      buf.writeln('Questão (trecho): $q');
    }
    buf.write('Explique com base local, sem inventar incidência UEMA.');
    setState(() {
      _controller.text = buf.toString().trim();
      _seedApplied = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiTutorControllerProvider);
    ref.watch(tutorOnlinePrefProvider);
    final cs = Theme.of(context).colorScheme;

    ref.listen(aiTutorControllerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 0),
            child: PageHeader(
              eyebrow: 'Ajuda',
              title: 'Tutor',
              subtitle: 'Pergunte sobre o plano do dia, um tópico ou uma questão. A resposta usa a base local.',
              trailing: IconButton(
                tooltip: 'Limpar conversa',
                onPressed: state.isLoading
                    ? null
                    : () => ref.read(aiTutorControllerProvider.notifier).clearConversation(),
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ),
          ),
          if (_healthLoaded && _offlineMode && _offlineBannerText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
              child: SurfacePanel(
                color: cs.secondaryContainer.withOpacity(0.45),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_outlined, size: 20, color: cs.onSecondaryContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _offlineBannerText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (_openaiConfigured != true)
                      TextButton(
                        onPressed: () => context.go('/ajustes'),
                        child: const Text('Ajustes'),
                      ),
                  ],
                ),
              ),
            ),
          if (_materialChecked &&
              (_localMaterialCount ?? 0) > 0 &&
              (widget.seedSubject?.trim().isNotEmpty == true) &&
              (widget.seedTopic?.trim().isNotEmpty == true))
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text(_materialChipLabel),
                  onPressed: _openLocalMaterial,
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
            child: Row(
              children: [
                for (final s in _styles)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(s.$2),
                      selected: state.style == s.$1,
                      showCheckmark: false,
                      onSelected: (_) => ref.read(aiTutorControllerProvider.notifier).setStyle(s.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: (state.messages.length <= 1 && !state.isLoading)
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.messages.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                state.messages.first.content,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          const QuietEmpty(
                            message: 'Escolha um atalho ou digite abaixo.',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              ActionChip(
                                label: const Text('Meta de hoje'),
                                onPressed: state.isLoading
                                    ? null
                                    : () {
                                        ref.read(aiTutorControllerProvider.notifier).send(
                                              'Qual a meta de estudo de hoje e o que priorizar?',
                                              offlineOnly: _offlineMode,
                                            );
                                      },
                              ),
                              ActionChip(
                                label: const Text('Macete do tópico'),
                                onPressed: state.isLoading
                                    ? null
                                    : () {
                                        ref.read(aiTutorControllerProvider.notifier).send(
                                              'Me dá um macete do tópico da fila de hoje e como eliminar distratores.',
                                              offlineOnly: _offlineMode,
                                            );
                                      },
                              ),
                              ActionChip(
                                label: const Text('Abrir sessão'),
                                onPressed: () => context.go('/sessao'),
                              ),
                              if (widget.seedSubject?.trim().isNotEmpty == true &&
                                  widget.seedTopic?.trim().isNotEmpty == true)
                                ActionChip(
                                  label: Text(_materialChipLabel),
                                  onPressed: _openLocalMaterial,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
                    itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(message: state.messages[index]);
                    },
                  ),
          ),
          Material(
            elevation: 6,
            color: cs.surface,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                14 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Sua dúvida…',
                          filled: true,
                          fillColor: cs.surfaceContainerHigh.withOpacity(0.45),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      tooltip: 'Enviar',
                      onPressed: state.isLoading ? null : _send,
                      icon: state.isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(aiTutorControllerProvider.notifier).send(
          text,
          offlineOnly: _offlineMode,
        );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: message.isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : null,
            bottomLeft: message.isUser ? null : const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser && message.isOffline) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Resposta offline · trechos da base local',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
            if (!message.isUser && message.uncited) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sem base local · não inventa cobrança UEMA',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
            SelectableText(message.content),
            if (message.citations.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Fontes na base',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              for (final c in message.citations.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () {
                      final type = c['type']?.toString();
                      final id = c['id']?.toString();
                      final subject = c['subject']?.toString() ?? '';
                      final topic = c['topic']?.toString() ?? '';
                      if (type == 'question' && id != null && id.isNotEmpty) {
                        context.go('/questoes/$id');
                      } else if ((type == 'edital' || type == 'lesson') && subject.isNotEmpty) {
                        context.go(
                          '/adaptativo?subject=${Uri.encodeComponent(subject)}'
                          '&topic=${Uri.encodeComponent(topic)}',
                        );
                      } else if (type == 'edital' || type == 'lesson') {
                        // Ciclo CF: lesson never hostil /aulas sob foco
                        context.go('/sessao');
                      }
                    },
                    child: Text(
                      '• ${c['label'] ?? c['id']}${c['snippet'] != null ? ' — ${c['snippet']}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Pensando…'),
          ],
        ),
      ),
    );
  }
}
