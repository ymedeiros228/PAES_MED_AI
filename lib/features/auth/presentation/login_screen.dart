import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/auth.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// Tela de entrada da versão web. Depois do login o router (que escuta [auth])
/// leva para onde a pessoa queria ir.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuario = TextEditingController();
  final _senha = TextEditingController();
  final _focoSenha = FocusNode();
  bool _mostrarSenha = false;
  bool _entrando = false;
  String? _erro;

  @override
  void dispose() {
    _usuario.dispose();
    _senha.dispose();
    _focoSenha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_entrando) return;
    if (_usuario.text.trim().isEmpty || _senha.text.isEmpty) {
      setState(() => _erro = 'Preencha o usuário e a senha.');
      return;
    }
    setState(() {
      _entrando = true;
      _erro = null;
    });
    try {
      await auth.entrar(_usuario.text, _senha.text);
      // o navegador oferece guardar a senha
      TextInput.finishAutofillContext();
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } on ApiTimeoutException {
      if (mounted) setState(() => _erro = 'O servidor demorou para responder. Tente de novo.');
    } catch (_) {
      if (mounted) setState(() => _erro = 'Sem conexão com o servidor. Confira a internet e tente de novo.');
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: Stack(
        children: [
          const Positioned(top: -160, left: -120, child: _Brilho(tamanho: 520, opacidade: 0.30)),
          const Positioned(bottom: -200, right: -140, child: _Brilho(tamanho: 600, opacidade: 0.22)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final largo = c.maxWidth >= 900;
                final cartao = _CartaoLogin(
                  usuario: _usuario,
                  senha: _senha,
                  focoSenha: _focoSenha,
                  mostrarSenha: _mostrarSenha,
                  entrando: _entrando,
                  erro: _erro,
                  onAlternarSenha: () => setState(() => _mostrarSenha = !_mostrarSenha),
                  onEntrar: _entrar,
                );
                if (largo) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Row(
                          children: [
                            const Expanded(child: _Apresentacao(largo: true)),
                            const SizedBox(width: 56),
                            SizedBox(width: 420, child: cartao),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          const _Apresentacao(largo: false),
                          const SizedBox(height: 28),
                          cartao,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo, nome e o que o app oferece (a lista só aparece em tela larga).
class _Apresentacao extends StatelessWidget {
  const _Apresentacao({required this.largo});

  final bool largo;

  @override
  Widget build(BuildContext context) {
    final alinhamento = largo ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    return Column(
      crossAxisAlignment: alinhamento,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(largo ? 22 : 18),
          child: Image.asset(
            'assets/branding/paes_med_ai_logo_bg.png',
            width: largo ? 88 : 72,
            height: largo ? 88 : 72,
            filterQuality: FilterQuality.medium,
          ),
        ),
        SizedBox(height: largo ? 28 : 18),
        Text(
          'PAES MED AI',
          textAlign: largo ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.displayFamily,
            fontSize: largo ? 40 : 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Sua preparação para o PAES-UEMA, rumo à Medicina.',
          textAlign: largo ? TextAlign.start : TextAlign.center,
          style: TextStyle(fontSize: largo ? 18 : 15.5, height: 1.45, color: Colors.white.withOpacity(0.72)),
        ),
        if (largo) ...[
          const SizedBox(height: 36),
          const _Recurso(icone: Icons.fact_check_rounded, texto: 'Questões oficiais do PAES, com gabarito e resolução'),
          const _Recurso(icone: Icons.timer_rounded, texto: 'Simulados no formato da prova'),
          const _Recurso(icone: Icons.auto_awesome_rounded, texto: 'Revisão inteligente e tutor com IA'),
        ],
      ],
    );
  }
}

class _Recurso extends StatelessWidget {
  const _Recurso({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.teal.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, size: 19, color: const Color(0xFF6FE0C4)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(texto, style: TextStyle(fontSize: 15.5, color: Colors.white.withOpacity(0.86))),
          ),
        ],
      ),
    );
  }
}

class _CartaoLogin extends StatelessWidget {
  const _CartaoLogin({
    required this.usuario,
    required this.senha,
    required this.focoSenha,
    required this.mostrarSenha,
    required this.entrando,
    required this.erro,
    required this.onAlternarSenha,
    required this.onEntrar,
  });

  final TextEditingController usuario;
  final TextEditingController senha;
  final FocusNode focoSenha;
  final bool mostrarSenha;
  final bool entrando;
  final String? erro;
  final VoidCallback onAlternarSenha;
  final VoidCallback onEntrar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 40, offset: const Offset(0, 18)),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Entrar',
              style: TextStyle(
                fontFamily: AppFonts.displayFamily,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use o usuário e a senha da sua conta.',
              style: TextStyle(fontSize: 14.5, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: usuario,
              enabled: !entrando,
              autofillHints: const [AutofillHints.username],
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => focoSenha.requestFocus(),
              decoration: const InputDecoration(
                labelText: 'Usuário',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: senha,
              focusNode: focoSenha,
              enabled: !entrando,
              obscureText: !mostrarSenha,
              autofillHints: const [AutofillHints.password],
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onEntrar(),
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: mostrarSenha ? 'Esconder senha' : 'Mostrar senha',
                  onPressed: onAlternarSenha,
                  icon: Icon(mostrarSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: erro == null
                  ? const SizedBox(height: 22)
                  : Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: AppTheme.errorBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 19, color: AppTheme.danger),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                erro!,
                                style: const TextStyle(fontSize: 13.5, color: Color(0xFF8E2A22), height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: entrando ? null : onEntrar,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: entrando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Entrar'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Esqueceu a senha? Peça uma nova a quem criou sua conta.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brilho verde-água difuso do fundo.
class _Brilho extends StatelessWidget {
  const _Brilho({required this.tamanho, required this.opacidade});

  final double tamanho;
  final double opacidade;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: tamanho,
        height: tamanho,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [AppTheme.teal.withOpacity(opacidade), AppTheme.teal.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}
