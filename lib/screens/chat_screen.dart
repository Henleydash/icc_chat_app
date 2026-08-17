import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final String? subtitle;
  final String avatarLabel;
  final String? avatarPhoto;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.title,
    this.subtitle,
    required this.avatarLabel,
    this.avatarPhoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _fs = FirestoreService();
  final _storage = StorageService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String _myName = 'Toi';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fs.watchUser(_uid).first.then((u) {
      if (u != null && mounted) setState(() => _myName = u.username);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    await _fs.sendMessage(
      widget.chatId,
      ChatMessage(
        id: '',
        senderId: _uid,
        senderName: _myName,
        type: MessageType.text,
        text: text,
      ),
    );
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (picked == null) return;
    await _uploadAndSend(File(picked.path), MessageType.image, picked.name);
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    await _uploadAndSend(file, MessageType.file, result.files.single.name);
  }

  Future<void> _uploadAndSend(File file, MessageType type, String fileName) async {
    setState(() => _sending = true);
    try {
      final url = await _storage.uploadChatFile(widget.chatId, file);
      await _fs.sendMessage(
        widget.chatId,
        ChatMessage(
          id: '',
          senderId: _uid,
          senderName: _myName,
          type: type,
          mediaUrl: url,
          fileName: fileName,
        ),
      );
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(label: widget.avatarLabel, photoUrl: widget.avatarPhoto, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navy)),
                  if (widget.subtitle != null)
                    Text(widget.subtitle!,
                        style: const TextStyle(fontSize: 11, color: AppColors.inkFaint)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _fs.messages(widget.chatId),
              builder: (context, snap) {
                if (!snap.hasData) return const LoadingView();
                final messages = snap.data!;
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Aucun message pour le moment. Dis bonjour 👋',
                        style: TextStyle(color: AppColors.inkFaint)),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length,
                  itemBuilder: (context, i) => _MessageBubble(
                    message: messages[i],
                    isMe: messages[i].senderId == _uid,
                  ),
                );
              },
            ),
          ),
          if (_sending) const LinearProgressIndicator(minHeight: 2, color: AppColors.orange),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined, color: AppColors.inkSoft),
              onPressed: _sending ? null : _sendImage,
              tooltip: 'Envoyer une image',
            ),
            IconButton(
              icon: const Icon(Icons.attach_file_rounded, color: AppColors.inkSoft),
              onPressed: _sending ? null : _sendFile,
              tooltip: 'Envoyer un document',
            ),
            Expanded(
              child: TextField(
                controller: _textCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Écris un message...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  fillColor: AppColors.paper,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendText(),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: _sendText,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final time = message.createdAt != null ? DateFormat.Hm().format(message.createdAt!) : '';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? null : AppColors.white,
          gradient: isMe ? kBrandGradient : null,
          border: isMe ? null : Border.all(color: AppColors.line),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(message.senderName,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.blue)),
              ),
            if (message.type == MessageType.text)
              Text(message.text ?? '',
                  style: TextStyle(color: isMe ? Colors.white : AppColors.ink, fontSize: 14.5)),
            if (message.type == MessageType.image)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: message.mediaUrl ?? '',
                  width: 200,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => const SizedBox(
                      height: 140, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                ),
              ),
            if (message.type == MessageType.file)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insert_drive_file_rounded,
                      size: 18, color: isMe ? Colors.white : AppColors.blue),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      message.fileName ?? 'Document',
                      style: TextStyle(
                          color: isMe ? Colors.white : AppColors.ink,
                          fontSize: 13.5,
                          decoration: TextDecoration.underline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(time,
                style: TextStyle(
                    fontSize: 10, color: isMe ? Colors.white70 : AppColors.inkFaint)),
          ],
        ),
      ),
    );
  }
}
