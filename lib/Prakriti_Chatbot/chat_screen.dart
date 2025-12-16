import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFD8ECFF), Color(0xFF8CCBFF)],
            )
          ),
        ),
        title: const Text('Upyogi Support',style: TextStyle(
          color: Colors.black,
        ),),
        
        actions: [
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  provider.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: provider.isConnected ? Colors.lightGreenAccent : Colors.red,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.isConnected 
                          ? 'Connected to internet' 
                          : 'No internet connection'),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, _) {
                return ListView.builder(
                  reverse: true,
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages.reversed.toList()[index];
                    return _buildMessage(message);
                  },
                );
              },
            ),
          ),
          _buildInputField(context),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message.text),
      ),
    );
  }

  Widget _buildInputField(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: provider.isConnected && !provider.isLoading,
              decoration: InputDecoration(
                hintText: provider.isConnected 
                    ? 'Type your message...' 
                    : 'No internet connection',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onSubmitted: (text) => _sendMessage(text, provider, controller),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: provider.isConnected && !provider.isLoading
                ? () => _sendMessage(controller.text, provider, controller)
                : null,
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text, ChatProvider provider, TextEditingController controller) {
    if (text.trim().isNotEmpty) {
      provider.sendMessage(text);
      controller.clear();
      FocusScope.of(context as BuildContext).unfocus();
    }
  }
}