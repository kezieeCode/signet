import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/chat_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/chat_simulation_service.dart';
import '../../services/api_service.dart';
import '../calls/call_screen.dart';
import '../../services/call_service.dart';

class ChatScreen extends StatefulWidget {
  final String driverName; // Rename to 'otherUserName' for clarity
  final String driverAvatar; // Rename to 'otherUserAvatar' for clarity
  final String rideId;
  final String userType; // NEW: 'rider' or 'driver'

  const ChatScreen({
    super.key,
    required this.driverName,
    required this.driverAvatar,
    required this.rideId,
    this.userType = 'rider', // Default to rider for backward compatibility
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatSimulationService _chatSimulation = ChatSimulationService();
  bool _isSending = false;
  Timer? _chatHistoryTimer;
  final Set<String> _loadedMessageIds = {};

  @override
  void initState() {
    super.initState();
    
    // Fetch chat history immediately
    _loadChatHistory();
    
    // Start polling chat history every second
    _chatHistoryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _loadChatHistory();
    });
    
    // Listen to chat simulation messages
    _chatSimulation.messageStream.listen((message) {
      if (mounted) {
        context.read<ChatCubit>().addMessage(
          ChatMessage(
            text: message,
            isFromDriver: true,
            timestamp: DateTime.now(),
            hasImage: false,
          ),
        );
        _scrollToBottom();
      }
    });
  }
  
  Future<void> _loadChatHistory() async {
    print('💬 CHAT - Polling chat history...');
    print('   Ride ID: ${widget.rideId}');
    
    try {
      final response = await ApiService.getChatHistory(rideId: widget.rideId);
      
      print('💬 CHAT - History response:');
      print('   Success: ${response['success']}');
      print('   Response: $response');
      
      if (response['success'] == true) {
        final data = response['data'];
        final messages = data['messages'] as List?;
        
        print('💬 CHAT - Messages found: ${messages?.length ?? 0}');
        print('   Already loaded: ${_loadedMessageIds.length} messages');
        
        if (messages != null && messages.isNotEmpty) {
          int newMessagesCount = 0;
          
          // Load messages in chronological order, skip duplicates
          for (var msg in messages) {
            final messageId = msg['id']?.toString() ?? '';
            final messageText = msg['message']?.toString() ?? '';
            
            // Skip if already loaded or empty
            if (messageId.isEmpty || messageText.isEmpty || _loadedMessageIds.contains(messageId)) {
              continue;
            }
            
            print('   📨 NEW message: ${msg['message']} from ${msg['sender_type']} (ID: $messageId)');
            
            // Determine if message is from driver based on sender_type (raw API value)
            final isFromDriver = msg['sender_type']?.toString().toLowerCase() == 'driver';
            
            final timestamp = msg['sent_at'] != null 
                ? DateTime.tryParse(msg['sent_at'].toString()) ?? DateTime.now()
                : DateTime.now();
            
            if (mounted) {
              context.read<ChatCubit>().addMessage(
                ChatMessage(
                  text: messageText,
                  isFromDriver: isFromDriver,
                  timestamp: timestamp,
                  hasImage: false,
                ),
              );
              
              // Track this message as loaded
              _loadedMessageIds.add(messageId);
              newMessagesCount++;
            }
          }
          
          if (newMessagesCount > 0) {
            print('✅ CHAT - Added $newMessagesCount new messages');
            _scrollToBottom();
          } else {
            print('💬 CHAT - No new messages (all already loaded)');
          }
        } else {
          print('💬 CHAT - No messages in history');
        }
      } else {
        print('❌ CHAT - Failed to load history: ${response['error']}');
      }
    } catch (e) {
      print('❌ CHAT - Error loading history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<ChatCubit, ChatState>(
          builder: (context, chatState) {
        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeState.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: themeState.textPrimary,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  backgroundColor: themeState.fieldBg,
                  child: Icon(
                    Icons.person,
                    color: themeState.textSecondary,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.driverName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Online',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.phone,
                  color: themeState.textPrimary,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                ),
                onPressed: () async {
                  try {
                    // Ensure CallService is initialized before attempting call
                    if (!CallService.isInitialized) {
                      if (kDebugMode) {
                        print('💬 CHAT - CallService not initialized, initializing...');
                      }
                      try {
                        await CallService.initialize();
                        // Wait a moment for initialization to complete
                        await Future.delayed(const Duration(milliseconds: 500));
                      } catch (initError) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Call service not ready. Please try again.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                        return;
                      }
                    }
                    
                    await CallService.startCall(rideId: widget.rideId);
                    if (mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CallScreen(
                            counterpartName: widget.driverName,
                            counterpartIdentity: 'ride:${widget.rideId}',
                            isIncoming: false,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print('❌ CHAT - Error starting call: $e');
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Unable to start call: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Chat Messages
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  child: Column(
                    children: [
                      // Date Header
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
                          vertical: ResponsiveHelper.getResponsiveSpacing(context, 6),
                        ),
                        decoration: BoxDecoration(
                          color: themeState.fieldBg,
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                        ),
                        child: Text(
                          'Today, 10:28 AM',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: themeState.textSecondary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                      
                      // Messages
                      ...chatState.messages.map((message) => _buildMessageBubble(message, themeState)).toList(),
                    ],
                  ),
                ),
              ),
              
              // Quick Reply Buttons
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: chatState.quickReplies.map((reply) {
                      return Container(
                        margin: EdgeInsets.only(right: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        child: GestureDetector(
                          onTap: () {
                            _sendMessage(reply);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                              vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
                            ),
                            decoration: BoxDecoration(
                              color: themeState.fieldBg,
                              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                              border: Border.all(color: themeState.fieldBorder),
                            ),
                            child: Text(
                              reply,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: themeState.textPrimary,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              // Message Input
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                decoration: BoxDecoration(
                  color: themeState.panelBg,
                  border: Border(
                    top: BorderSide(color: themeState.fieldBorder),
                  ),
                ),
                child: Row(
                  children: [
                    // Attachment Button
                    Container(
                      width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                      height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                      decoration: BoxDecoration(
                        color: themeState.fieldBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: themeState.fieldBorder),
                      ),
                      child: Icon(
                        Icons.attach_file,
                        color: themeState.textSecondary,
                        size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                      ),
                    ),
                    
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    
                    // Message Input Field
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                          vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
                        ),
                        decoration: BoxDecoration(
                          color: themeState.fieldBg,
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
                          border: Border.all(color: themeState.fieldBorder),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: themeState.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: themeState.textSecondary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (text) {
                            if (text.trim().isNotEmpty) {
                              _sendMessage(text.trim());
                            }
                          },
                        ),
                      ),
                    ),
                    
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    
                    // Send Button
                    GestureDetector(
                      onTap: _isSending ? null : () {
                        if (_messageController.text.trim().isNotEmpty) {
                          _sendMessage(_messageController.text.trim());
                        }
                      },
                      child: Container(
                        width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                        height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                        decoration: BoxDecoration(
                          color: _isSending ? AppColors.gold.withOpacity(0.5) : AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                        child: _isSending
                            ? SizedBox(
                                width: ResponsiveHelper.getResponsiveIconSize(context, 20),
                                height: ResponsiveHelper.getResponsiveIconSize(context, 20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : Icon(
                                Icons.send,
                                color: Colors.black,
                                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeState themeState) {
    // Apply flip logic for driver view
    bool isFromDriver = message.isFromDriver;
    if (widget.userType == 'driver') {
      isFromDriver = !isFromDriver; // Flip: driver messages show on right, rider messages on left
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 12)),
      child: Row(
        mainAxisAlignment: isFromDriver ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isFromDriver) ...[
            // Driver Avatar
            Container(
              margin: EdgeInsets.only(right: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              child: CircleAvatar(
                radius: ResponsiveHelper.getResponsiveSpacing(context, 16),
                backgroundColor: themeState.fieldBg,
                child: Icon(
                  Icons.person,
                  color: themeState.textSecondary,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                ),
              ),
            ),
          ],
          
          // Message Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isFromDriver ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  decoration: BoxDecoration(
                    color: isFromDriver 
                        ? (themeState.isDarkTheme ? Colors.grey.shade800 : themeState.fieldBg)
                        : AppColors.gold,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                      topRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                      bottomLeft: isFromDriver 
                          ? Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 4))
                          : Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                      bottomRight: isFromDriver 
                          ? Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16))
                          : Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 4)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isFromDriver 
                              ? themeState.textPrimary 
                              : Colors.black,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                      ),
                      if (message.hasImage) ...[
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        Container(
                          height: ResponsiveHelper.getResponsiveSpacing(context, 120),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: themeState.fieldBorder,
                            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                          ),
                          child: Icon(
                            Icons.car_rental,
                            color: themeState.textSecondary,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 40),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeState.textSecondary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  ),
                ),
              ],
            ),
          ),
          
          if (!message.isFromDriver) ...[
            // User Avatar
            Container(
              margin: EdgeInsets.only(left: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              child: CircleAvatar(
                radius: ResponsiveHelper.getResponsiveSpacing(context, 16),
                backgroundColor: themeState.fieldBg,
                child: Icon(
                  Icons.person,
                  color: themeState.textSecondary,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (_isSending) return;

    print('💬 CHAT - Sending message:');
    print('   Ride ID: ${widget.rideId}');
    print('   Message: $text');

    setState(() {
      _isSending = true;
    });

    // Add user message to UI immediately
    // The message should show as the current user's own message (on the right, in gold bubble)
    // So we set isFromDriver based on who the current user is:
    // - If rider is using chat: isFromDriver = false (shows on right as their own message)
    // - If driver is using chat: isFromDriver = true (will be flipped to show on right as their own message)
    context.read<ChatCubit>().addMessage(
      ChatMessage(
        text: text,
        isFromDriver: widget.userType == 'driver', // Driver: true (will be flipped), Rider: false (shows on right)
        timestamp: DateTime.now(),
        hasImage: false,
      ),
    );
    _messageController.clear();
    _scrollToBottom();

    try {
      // Validate rideId before sending
      if (widget.rideId.isEmpty) {
        print('❌ CHAT - Cannot send message: rideId is empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot send message: Ride ID is missing'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Send message to API
      // Include sender_type to ensure backend knows who is sending (especially important for driver)
      print('💬 CHAT - Sending message with senderType: ${widget.userType}');
      final response = await ApiService.sendChatMessage(
        rideId: widget.rideId,
        message: text,
        senderType: widget.userType, // 'driver' or 'rider'
      );

      print('💬 CHAT - Response received:');
      print('   Success: ${response['success']}');
      print('   Response: $response');

      if (response['success'] != true) {
        print('❌ CHAT - Failed to send message');
        print('   Error: ${response['error']}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['error']?['message'] ?? 'Failed to send message',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('✅ CHAT - Message sent successfully');
      }
    } catch (e) {
      print('❌ CHAT - Exception occurred: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  @override
  void dispose() {
    _chatHistoryTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _chatSimulation.dispose();
    super.dispose();
  }
}

