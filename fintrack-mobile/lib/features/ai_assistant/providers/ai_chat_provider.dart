import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../models/chat_message.dart';

/// Immutable state container for the AI assistant conversation UI.
class AiChatState {
  /// Ordered list of chat messages exchanged in the current session.
  final List<ChatMessage> messages;

  /// True while awaiting an asynchronous response turn from the AI agent.
  final bool isSending;

  /// True while initial message history is being loaded from the backend.
  final bool isLoadingHistory;

  /// Human-readable error message string if an error occurred, or null.
  final String? error;

  /// Creates an immutable [AiChatState] instance.
  const AiChatState({
    this.messages = const [],
    this.isSending = false,
    this.isLoadingHistory = false,
    this.error,
  });

  /// Creates a copy of [AiChatState] with updated field values.
  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    bool? isLoadingHistory,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: error,
    );
  }
}

/// Riverpod Notifier managing chat message state and interaction logic.
class AiChatNotifier extends Notifier<AiChatState> {
  /// Default session identifier. The backend scopes history per authenticated user ID.
  static const String sessionId = 'default';

  @override
  AiChatState build() => const AiChatState();

  /// Loads historical chat messages for this user from the backend API.
  Future<void> loadHistory() async {
    state = state.copyWith(isLoadingHistory: true, error: null);
    try {
      final api = ref.read(apiServiceProvider);
      final raw = await api.getChatHistory(sessionId: sessionId);
      final messages = raw
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
      state = state.copyWith(messages: messages, isLoadingHistory: false);
    } catch (e) {
      state = state.copyWith(isLoadingHistory: false, error: _clean(e));
    }
  }

  /// Sends a text message to the AI assistant endpoint.
  ///
  /// Optimistically appends the user message to the UI state immediately,
  /// then appends the assistant reply when received from the backend.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final userMsg = ChatMessage(
      role: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    );
    // Optimistic UI update: show user prompt right away
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isSending: true,
      error: null,
    );

    try {
      final api = ref.read(apiServiceProvider);
      final reply = await api.sendChatMessage(trimmed, sessionId: sessionId);
      final botMsg = ChatMessage(
        role: 'assistant',
        content: reply,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, botMsg],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(isSending: false, error: _clean(e));
    }
  }

  /// Helper to clean raw exception strings for user-friendly error banners.
  String _clean(Object e) => e.toString().replaceAll('Exception: ', '');
}

/// Provider exposing the [AiChatNotifier] state to Flutter widgets.
final aiChatProvider =
    NotifierProvider<AiChatNotifier, AiChatState>(AiChatNotifier.new);
