import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/chat_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (authProvider.currentUser?.email != null) {
      await chatProvider.initialize(authProvider.currentUser!.email!);
      await productProvider.loadProducts();
      await orderProvider.loadUserOrders(authProvider.currentUser!.email!);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    _messageController.clear();

    if (authProvider.currentUser?.email != null) {
      await chatProvider.sendMessage(
        message,
        authProvider.currentUser!.email!,
        productProvider: productProvider,
        orderProvider: orderProvider,
      );
    }

    // Scroll to bottom
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa lịch sử chat'),
                  content: const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử chat?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                
                if (authProvider.currentUser?.email != null) {
                  await chatProvider.clearChatHistory(authProvider.currentUser!.email!);
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.messages.isEmpty) {
                  return const Center(
                    child: Text('Chưa có tin nhắn nào'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return ChatMessageBubble(message: message);
                  },
                );
              },
            ),
          ),

          // Loading indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text('Đang trả lời...'),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Error message
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.errorMessage != null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.red.shade50,
                  child: Text(
                    chatProvider.errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    return IconButton(
                      onPressed: chatProvider.isLoading ? null : _sendMessage,
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
