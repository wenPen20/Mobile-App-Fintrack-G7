/// Data model representing a single message turn within the AI assistant conversation.
class ChatMessage {
  /// The author role of the message, typically 'user' or 'assistant'.
  final String role;

  /// The text content of the message turn.
  final String content;

  /// The timestamp when the message was recorded, or null if unknown.
  final DateTime? createdAt;

  /// Creates an immutable [ChatMessage] instance.
  ///
  /// [role] specifies the sender ('user' or 'assistant').
  /// [content] holds the text message payload.
  /// [createdAt] optional timestamp of message creation.
  const ChatMessage({
    required this.role,
    required this.content,
    this.createdAt,
  });

  /// Convenience getter returning true if this message was sent by the user.
  bool get isUser => role == 'user';

  /// Deserializes a [ChatMessage] from a JSON map returned by the backend API.
  ///
  /// [json] map containing 'role', 'content', and optional ISO string 'created_at'.
  /// Returns a constructed [ChatMessage] object.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawDate = json['created_at'];
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: rawDate is String ? DateTime.tryParse(rawDate) : null,
    );
  }
}
