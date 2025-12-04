import 'package:flutter_bloc/flutter_bloc.dart';

// Chat Message Model
class ChatMessage {
  final String text;
  final bool isFromDriver;
  final DateTime timestamp;
  final bool hasImage;

  ChatMessage({
    required this.text,
    required this.isFromDriver,
    required this.timestamp,
    this.hasImage = false,
  });
}

// Chat State
class ChatState {
  final List<ChatMessage> messages;
  final List<String> quickReplies;
  final bool isLoading;

  const ChatState({
    this.messages = const [],
    this.quickReplies = const [
      "Okay",
      "I'm here",
      "On my way!",
      "Thank you",
    ],
    this.isLoading = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<String>? quickReplies,
    bool? isLoading,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      quickReplies: quickReplies ?? this.quickReplies,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatState &&
        other.messages.length == messages.length &&
        other.quickReplies.length == quickReplies.length &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return Object.hash(messages.length, quickReplies.length, isLoading);
  }
}

// Chat Cubit
class ChatCubit extends Cubit<ChatState> {
  ChatCubit() : super(const ChatState()) {
    // Initialize with driver's first message
    _addInitialMessage();
  }

  void _addInitialMessage() {
    final initialMessage = ChatMessage(
      text: "Hello! I'm on my way to your location. I should be there in about 5 minutes.",
      isFromDriver: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      hasImage: false,
    );

    emit(state.copyWith(messages: [initialMessage]));
  }

  void addMessage(ChatMessage message) {
    final updatedMessages = List<ChatMessage>.from(state.messages)..add(message);
    emit(state.copyWith(messages: updatedMessages));
  }

  void sendMessage(String text) {
    final userMessage = ChatMessage(
      text: text,
      isFromDriver: false,
      timestamp: DateTime.now(),
      hasImage: false,
    );

    addMessage(userMessage);
    
    // Simulate driver response
    _simulateDriverResponse(text);
  }

  void _simulateDriverResponse(String userMessage) {
    // Simulate typing delay
    Future.delayed(const Duration(seconds: 1), () {
      final responses = [
        "Got it, thanks!",
        "I'll be there shortly.",
        "See you soon!",
        "Perfect, I'm on my way.",
        "Thanks for letting me know.",
      ];

      final randomResponse = responses[DateTime.now().millisecond % responses.length];
      
      final driverResponse = ChatMessage(
        text: randomResponse,
        isFromDriver: true,
        timestamp: DateTime.now(),
        hasImage: false,
      );

      addMessage(driverResponse);
    });
  }

  void setLoading(bool isLoading) {
    emit(state.copyWith(isLoading: isLoading));
  }

  void clearMessages() {
    emit(state.copyWith(messages: []));
    _addInitialMessage();
  }
}
