import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// 在线客服聊天页面
class ChatScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const ChatScreen({
    super.key,
    this.userId = 0,
    this.userName = '用户',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  bool _sending = false;
  int _convId = 0;
  Timer? _pollTimer;
  int _lastMsgCount = 0;
  int _extractedUserId = 0;

  @override
  void initState() {
    super.initState();
    // 如果 userId 为 0，尝试从 token 中提取
    if (widget.userId == 0) {
      final token = ApiService.token ?? '';
      final regex = RegExp(r'shop_c(\d+)_');
      final match = regex.firstMatch(token);
      if (match != null) {
        final id = int.tryParse(match.group(1) ?? '0') ?? 0;
        // 通过 setState 间接更新 widget.userId 不可行，暂记录
        _extractedUserId = id;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPolling());
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // 每3秒轮询新消息
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_convId > 0) {
        await _loadMessages();
      }
    });
  }

  Future<void> _loadMessages() async {
    if (_convId <= 0) return;
    try {
      final msgs = await ApiService.getChatMessages(_convId);
      if (msgs.length != _messages.length) {
        setState(() => _messages..clear()..addAll(msgs));
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final content = _msgCtrl.text.trim();
    if (content.isEmpty || _sending) return;
    _msgCtrl.clear();
    setState(() => _sending = true);

    try {
      final effectiveUserId = widget.userId > 0 ? widget.userId : _extractedUserId;
      final result = await ApiService.sendChatMessage(
        content: content,
        convId: _convId,
        userId: effectiveUserId,
        userName: widget.userName,
      );
      if (result['code'] == 0) {
        _convId = result['data']['conv_id'] ?? 0;
        await _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e'), backgroundColor: Colors.red[800]),
        );
      }
    }
    setState(() => _sending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.headset_mic, size: 20),
            SizedBox(width: 6),
            Text('在线客服', style: TextStyle(fontSize: 16)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            child: Row(
              children: [
                const Spacer(),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green[400],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text('在线', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(child: _buildMessages(theme)),
          // 输入栏
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessages(ThemeData theme) {
    if (_messages.isEmpty && !_sending) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.chat_bubble_outline, size: 30, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '有什么可以帮您的？',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '请描述您的问题，我们将为您提供帮助',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 24),
          _quickBtn('你们卖什么商品？'),
          const SizedBox(height: 8),
          _quickBtn('如何退款？'),
          const SizedBox(height: 8),
          _quickBtn('订单多久到账？'),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(12),
        itemCount: _messages.length + (_sending ? 1 : 0),
        itemBuilder: (context, index) {
          if (_sending && index == _messages.length) {
            return _buildTypingIndicator();
          }
          final msg = _messages[index];
          final role = msg['role']?.toString() ?? 'user';
          final isUser = role == 'user';
          final content = msg['content']?.toString() ?? '';
          final time = msg['created_at']?.toString() ?? '';
          final userName = msg['user_name']?.toString() ?? (isUser ? widget.userName : '客服');

          // system消息居中显示
          if (role == 'system') {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(content, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isUser && userName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(userName, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      ),
                    if (isUser)
                      Text('我', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    const SizedBox(width: 6),
                    if (time.length >= 16)
                      Text(time.substring(11, 16), style: TextStyle(fontSize: 9, color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary
                        : Colors.grey[850],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                  ),
                  child: _buildMessageContent(msg, content),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _quickBtn(String text) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          _msgCtrl.text = text;
          _sendMessage();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(150),
                const SizedBox(width: 4),
                _dot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Map<String, dynamic> msg, String content) {
    final msgType = msg['msg_type']?.toString() ?? 'text';
    // 图片消息
    if (msgType == 'image') {
      // 从内容中提取图片URL（格式: [图片]/uploads/xxx.jpg 或直接路径）
      String imgUrl = content;
      if (imgUrl.startsWith('[图片]')) { imgUrl = imgUrl.replaceFirst('[图片]', ''); }
      if (imgUrl.startsWith('[图片]')) { imgUrl = imgUrl.replaceFirst('[图片]', ''); }
      if (imgUrl.startsWith('[')) {
        final start = imgUrl.indexOf(']');
        if (start >= 0) imgUrl = imgUrl.substring(start + 1);
      }
      // 补全域名
      final base = 'http://3003.online';
      if (!imgUrl.startsWith('http://') && !imgUrl.startsWith('https://')) {
        if (imgUrl.startsWith('/')) { imgUrl = '$base$imgUrl'; }
        else { imgUrl = '$base/$imgUrl'; }
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imgUrl,
          fit: BoxFit.contain,
          width: 200,
          height: 200,
          errorBuilder: (_, __, ___) => Text(content,
            style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4)),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              width: 80, height: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
        ),
      );
    }
    // 文本消息
    return Text(content,
      style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4));
  }

  Widget _dot(int delay) {
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  Color get themeColor => Theme.of(context).colorScheme.primary;

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: '输入消息...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
