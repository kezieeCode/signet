import 'package:flutter/material.dart';
import '../../cubits/theme_cubit.dart';

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'sender': 'support',
      'text': 'Hello! Thank you for contacting QGlide Support. My name is Sarah. How can I assist you today?',
      'timestamp': '11:01 AM',
      'isTyping': false,
    },
  ];

  bool _isSupportOnline = true;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) {
      return;
    }
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'sender': 'user',
        'text': messageText,
        'timestamp': _getCurrentTime(),
        'isTyping': false,
      });
    });
    
    _messageController.clear();
    _scrollToBottom();
    
    // Simulate support response
    _simulateSupportResponse();
  }

  void _simulateSupportResponse() {
    if (!_isSupportOnline) return;
    
    // Simulate realistic typing time (2-5 seconds)
    final typingDuration = Duration(milliseconds: 2000 + (DateTime.now().millisecond % 3000));
    
    Future.delayed(typingDuration, () {
      if (mounted && _isSupportOnline) {
        // Get contextual response based on user's message
        final lastUserMessage = _messages.lastWhere((msg) => msg['sender'] == 'user')['text'] as String;
        final response = _getContextualResponse(lastUserMessage);
        
        setState(() {
          _messages.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'sender': 'support',
            'text': response,
            'timestamp': _getCurrentTime(),
            'isTyping': false,
          });
        });
        _scrollToBottom();
        
        // Sometimes follow up with another message
        if (response.contains('looking into') || response.contains('investigating')) {
          _simulateFollowUpResponse();
        }
      }
    });
  }

  void _simulateFollowUpResponse() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isSupportOnline) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _isSupportOnline) {
            setState(() {
              _messages.add({
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'sender': 'support',
                'text': 'I found the issue! There was a surge pricing applied during peak hours. I\'ve processed a refund of \$5.50 to your account. You should see it within 24 hours.',
                'timestamp': _getCurrentTime(),
                'isTyping': false,
              });
            });
            _scrollToBottom();
          }
        });
      }
    });
  }

  String _getContextualResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('ride id') || message.contains('qg-')) {
      return 'Perfect! I can see ride QG-843021 in our system. Let me pull up the details and check what happened with the fare calculation.';
    } else if (message.contains('fare') || message.contains('charge') || message.contains('price')) {
      return 'I understand your concern about the fare. Let me investigate this for you. Could you tell me what amount you were charged versus what you expected?';
    } else if (message.contains('driver') || message.contains('pickup') || message.contains('drop')) {
      return 'I\'m looking into the driver and route details for your ride. This will help me understand if there were any issues with the trip.';
    } else if (message.contains('refund') || message.contains('money back')) {
      return 'I completely understand you\'d like a refund. Let me review your ride details and see what we can do to resolve this for you.';
    } else if (message.contains('thank') || message.contains('thanks')) {
      return 'You\'re very welcome! I\'m here to help. Is there anything else I can assist you with today?';
    } else if (message.contains('help') || message.contains('issue') || message.contains('problem')) {
      return 'I\'m here to help! Could you please describe the issue you\'re experiencing in a bit more detail?';
    } else {
      // Default responses for general messages
      final responses = [
        'I understand. Let me look into that for you right away.',
        'Thanks for letting me know. I\'m checking our system now.',
        'I see what you mean. Give me a moment to investigate this.',
        'That sounds frustrating. I\'m going to help you get this sorted out.',
        'I\'m on it! Let me pull up your account details and see what\'s going on.',
      ];
      return responses[DateTime.now().millisecond % responses.length];
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2333),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2333),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.gold,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            // Support agent profile picture
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: const DecorationImage(
                      image: AssetImage('assets/images/user.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.gold,
            ),
            onPressed: () {
              // Handle more options
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Only unfocus if tapping outside the input area
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // Date separator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'Today, September 16, 2025',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            
            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
            
            // Message input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['sender'] == 'user';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Support agent profile picture
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: AssetImage('assets/images/user.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.gold : const Color(0xFF2B4057),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message['text'],
                    style: TextStyle(
                      color: isUser ? Colors.black : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message['timestamp'],
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return GestureDetector(
      onTap: () {
        // Prevent the body GestureDetector from unfocusing when tapping the input area
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF1A2333),
          border: Border(
            top: BorderSide(color: Color(0xFF2B4057), width: 1),
          ),
        ),
        child: Row(
          children: [
            // Attachment button
            IconButton(
              icon: const Icon(
                Icons.attach_file,
                color: AppColors.gold,
                size: 24,
              ),
              onPressed: () {
                // Handle attachment
              },
            ),
            
            // Message input field
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2B4057),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) {
                  _sendMessage();
                },
                textInputAction: TextInputAction.send,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                onTap: () {
                  _messageFocusNode.requestFocus();
                },
              ),
            ),
            
            // Send button
            IconButton(
              onPressed: _sendMessage,
              icon: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
