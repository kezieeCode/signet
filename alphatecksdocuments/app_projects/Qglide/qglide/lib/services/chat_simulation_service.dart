import 'dart:async';
import 'dart:math';

class ChatSimulationService {
  static final ChatSimulationService _instance = ChatSimulationService._internal();
  factory ChatSimulationService() => _instance;
  ChatSimulationService._internal();

  final StreamController<String> _messageController = StreamController.broadcast();
  Stream<String> get messageStream => _messageController.stream;

  Timer? _responseTimer;
  final Random _random = Random();

  // Driver response templates based on ride status
  final Map<String, List<String>> _driverResponses = {
    'driver_found': [
      "Hello! I'm on my way to your location. I should be there in about 5 minutes.",
      "Hi there! I've accepted your ride request. I'm heading to your pickup location now.",
      "Hello! I'm coming to pick you up. Please be ready in about 5 minutes.",
      "Hi! I'm en route to your location. Should arrive shortly.",
    ],
    'driver_arrived': [
      "I've arrived at your location. Please come outside when you're ready.",
      "I'm here! I can see your building. Please come down when you're ready.",
      "I've reached your pickup point. I'm waiting outside.",
      "I'm here and ready to go. Please come outside when you're ready.",
    ],
    'ride_started': [
      "We're on our way! Please fasten your seatbelt.",
      "Starting the trip now. Please let me know if you need anything.",
      "We're heading to your destination. Should be a smooth ride.",
      "Trip started! Please sit back and relax.",
    ],
    'trip_progress': [
      "We're making good progress. Traffic looks clear ahead.",
      "Halfway there! How are you doing?",
      "We're about 10 minutes away from your destination.",
      "Almost there! Just a few more minutes.",
    ],
    'trip_completed': [
      "We've arrived at your destination. Thank you for riding with QGlide!",
      "Here we are! Have a great day!",
      "We've reached your destination. Thank you for choosing QGlide!",
      "Trip completed! Please rate your ride when you get a chance.",
    ],
    'general': [
      "Thank you for choosing QGlide!",
      "Is there anything I can help you with?",
      "Please let me know if you need anything during the ride.",
      "I'm here if you need any assistance.",
      "How is your day going?",
      "The weather looks nice today!",
      "Traffic seems to be moving well.",
      "I hope you're comfortable.",
    ],
  };

  // Auto-responses to user messages
  final Map<String, List<String>> _autoResponses = {
    'hello': [
      "Hello! How can I help you?",
      "Hi there! I'm here to assist you.",
      "Hello! Is everything okay?",
    ],
    'thanks': [
      "You're welcome!",
      "My pleasure!",
      "Happy to help!",
    ],
    'where': [
      "I'm on my way to your location. Should be there soon!",
      "I'm heading to your pickup point now.",
      "I'm coming to get you. Please be ready.",
    ],
    'how long': [
      "I should be there in about 5 minutes.",
      "ETA is about 5 minutes.",
      "Just a few more minutes!",
    ],
    'wait': [
      "No problem! Take your time.",
      "I'll wait for you.",
      "No rush, I'm here when you're ready.",
    ],
    'cold': [
      "I can adjust the temperature for you.",
      "Let me turn up the heat.",
      "I'll make it more comfortable for you.",
    ],
    'hot': [
      "I'll turn on the AC for you.",
      "Let me cool it down.",
      "I'll adjust the temperature.",
    ],
    'music': [
      "What kind of music would you like to listen to?",
      "I can change the music if you'd like.",
      "Any music preferences?",
    ],
    'default': [
      "I understand. I'm here if you need anything.",
      "Got it! Let me know if you need help.",
      "Sure thing! Is there anything else I can do?",
    ],
  };

  // Send driver message based on ride status
  void sendDriverMessage(String status) {
    List<String> responses = _driverResponses[status] ?? _driverResponses['general']!;
    String message = responses[_random.nextInt(responses.length)];
    
    // Simulate typing delay
    _responseTimer = Timer(Duration(seconds: 1 + _random.nextInt(3)), () {
      _messageController.add(message);
    });
  }

  // Respond to user message
  void respondToUserMessage(String userMessage) {
    String message = userMessage.toLowerCase();
    List<String> responses = [];
    
    // Check for keywords and get appropriate responses
    if (message.contains('hello') || message.contains('hi')) {
      responses = _autoResponses['hello']!;
    } else if (message.contains('thank') || message.contains('thanks')) {
      responses = _autoResponses['thanks']!;
    } else if (message.contains('where') || message.contains('location')) {
      responses = _autoResponses['where']!;
    } else if (message.contains('how long') || message.contains('eta') || message.contains('time')) {
      responses = _autoResponses['how long']!;
    } else if (message.contains('wait') || message.contains('ready')) {
      responses = _autoResponses['wait']!;
    } else if (message.contains('cold') || message.contains('freez')) {
      responses = _autoResponses['cold']!;
    } else if (message.contains('hot') || message.contains('warm')) {
      responses = _autoResponses['hot']!;
    } else if (message.contains('music') || message.contains('song')) {
      responses = _autoResponses['music']!;
    } else {
      responses = _autoResponses['default']!;
    }
    
    String response = responses[_random.nextInt(responses.length)];
    
    // Simulate realistic response delay
    int delay = 2 + _random.nextInt(4); // 2-5 seconds
    _responseTimer = Timer(Duration(seconds: delay), () {
      _messageController.add(response);
    });
  }

  // Send periodic driver updates during ride
  void startPeriodicUpdates() {
    Timer.periodic(Duration(seconds: 30 + _random.nextInt(30)), (timer) {
      if (_random.nextBool()) { // 50% chance of sending update
        List<String> generalResponses = _driverResponses['general']!;
        String message = generalResponses[_random.nextInt(generalResponses.length)];
        _messageController.add(message);
      }
    });
  }

  // Stop periodic updates
  void stopPeriodicUpdates() {
    _responseTimer?.cancel();
  }

  // Dispose resources
  void dispose() {
    _responseTimer?.cancel();
    _messageController.close();
  }
}

