enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.citations = const [],
    this.uncited = false,
    this.hasLocalBase = true,
  });

  final ChatRole role;
  final String content;
  final List<Map<String, dynamic>> citations;
  final bool uncited;
  final bool hasLocalBase;

  bool get isUser => role == ChatRole.user;

  Map<String, dynamic> toJson() => {
        'role': isUser ? 'user' : 'assistant',
        'content': content,
      };
}
