import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Conta logada (versão web). No app local o backend não exige login e devolve
/// [exigeLogin] = false: não há tela de entrada nem botão de sair.
class Sessao {
  const Sessao({required this.usuario, required this.nome, required this.papel, required this.exigeLogin});

  factory Sessao.fromJson(Map<String, dynamic> json) => Sessao(
        usuario: json['usuario']?.toString() ?? '',
        nome: json['nome']?.toString() ?? '',
        papel: json['papel']?.toString() ?? 'aluno',
        exigeLogin: json['exigeLogin'] == true,
      );

  final String usuario;
  final String nome;
  final String papel;
  final bool exigeLogin;

  String get nomeExibido => nome.isNotEmpty ? nome : usuario;
}

enum EstadoLogin { verificando, entrou, saiu }

/// Estado do login; o router escuta (refreshListenable) e manda para /entrar quando sai.
class AuthController extends ChangeNotifier {
  AuthController() {
    ApiClient.aoPerderSessao = _sessaoExpirou;
  }

  EstadoLogin estado = EstadoLogin.verificando;
  Sessao? sessao;

  /// Pergunta ao backend se já há sessão (cookie). Chamado uma vez no main().
  Future<void> verificar() async {
    // Só um 401 quer dizer "sem login". Erro de rede, servidor lento ou 5xx NÃO desloga:
    // antes qualquer falha aqui mandava para a tela de entrada quem tinha sessão válida
    // (foi o que aconteceu com o Jonas quando o banco caiu). Tenta de novo algumas vezes.
    const esperas = [Duration(seconds: 2), Duration(seconds: 4), Duration(seconds: 8)];
    for (var tentativa = 0; ; tentativa++) {
      try {
        final dados = await apiClient.get('/api/auth/me');
        sessao = Sessao.fromJson(Map<String, dynamic>.from(dados as Map));
        estado = EstadoLogin.entrou;
        break;
      } on ApiUnauthorizedException {
        estado = EstadoLogin.saiu;
        break;
      } catch (_) {
        if (!kIsWeb) {
          // Desktop: o backend local ainda está subindo, e local não exige login.
          estado = EstadoLogin.entrou;
          break;
        }
        if (tentativa >= esperas.length) {
          // Web e servidor ainda fora: a tela de entrada mostra o erro ao tentar entrar.
          // O cookie da sessão continua guardado; ao voltar o servidor, recarregar entra direto.
          estado = EstadoLogin.saiu;
          break;
        }
        await Future<void>.delayed(esperas[tentativa]);
      }
    }
    notifyListeners();
  }

  /// Lança [ApiException] com a mensagem do backend (senha errada, conta travada...).
  Future<void> entrar(String usuario, String senha) async {
    final dados = await apiClient.post('/api/auth/login', {'usuario': usuario.trim(), 'senha': senha});
    sessao = Sessao.fromJson(Map<String, dynamic>.from(dados as Map));
    estado = EstadoLogin.entrou;
    notifyListeners();
  }

  Future<void> sair() async {
    try {
      await apiClient.post('/api/auth/logout', const {});
    } catch (_) {
      // Mesmo sem resposta, sai daqui: o cookie vence sozinho.
    }
    sessao = null;
    estado = EstadoLogin.saiu;
    notifyListeners();
  }

  void _sessaoExpirou() {
    if (estado == EstadoLogin.entrou && (sessao?.exigeLogin ?? false)) {
      sessao = null;
      estado = EstadoLogin.saiu;
      notifyListeners();
    }
  }
}

final auth = AuthController();
