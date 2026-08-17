import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'chat_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  final _tabs = const [
    _DiscussionsTab(),
    _GroupsTab(),
    _PublicationsTab(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Discussions'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: 'Groupes'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), label: 'Publications'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}

String get _uid => FirebaseAuth.instance.currentUser!.uid;

// =========================================================================
// DISCUSSIONS
// =========================================================================

class _DiscussionsTab extends StatelessWidget {
  const _DiscussionsTab();

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Discussions'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orange,
        onPressed: () => _openNewChatSheet(context),
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
      body: StreamBuilder<List<ChatThread>>(
        stream: fs.myChats(_uid),
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingView();
          final threads = snap.data!.where((t) => !t.isGroup).toList();
          if (threads.isEmpty) {
            return const _EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              text: "Aucune discussion pour l'instant.\nAppuie sur ✏️ pour écrire à quelqu'un.",
            );
          }
          return ListView.separated(
            itemCount: threads.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
            itemBuilder: (context, i) => _DirectChatTile(thread: threads[i]),
          );
        },
      ),
    );
  }

  Future<void> _openNewChatSheet(BuildContext context) async {
    final fs = FirestoreService();
    final users = await fs.allUsersExcept(_uid);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UserPickerSheet(
        title: 'Nouvelle discussion',
        users: users,
        singleSelect: true,
        onConfirm: (selected) async {
          Navigator.pop(ctx);
          if (selected.isEmpty) return;
          final other = selected.first;
          final chatId = await fs.getOrCreateDirectChat(_uid, other.uid);
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: chatId,
                title: other.username,
                subtitle: 'Discussion privée',
                avatarLabel: other.username,
                avatarPhoto: other.photoUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DirectChatTile extends StatelessWidget {
  final ChatThread thread;
  const _DirectChatTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    final otherUid = thread.memberIds.firstWhere((id) => id != _uid, orElse: () => '');
    return StreamBuilder<AppUser?>(
      stream: FirestoreService().watchUser(otherUid),
      builder: (context, snap) {
        final other = snap.data;
        final name = other?.username ?? '...';
        final time = thread.lastMessageAt != null ? DateFormat.Hm().format(thread.lastMessageAt!) : '';
        return ListTile(
          leading: AppAvatar(label: name, photoUrl: other?.photoUrl),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
          subtitle: Text(
            thread.lastMessage.isEmpty ? 'Dites bonjour 👋' : thread.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inkSoft),
          ),
          trailing: Text(time, style: const TextStyle(fontSize: 11, color: AppColors.inkFaint)),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: thread.id,
                title: name,
                subtitle: 'Discussion privée',
                avatarLabel: name,
                avatarPhoto: other?.photoUrl,
              ),
            ),
          ),
        );
      },
    );
  }
}

// =========================================================================
// GROUPES
// =========================================================================

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Groupes'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orange,
        onPressed: () => _openCreateGroupSheet(context),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: StreamBuilder<List<ChatThread>>(
        stream: fs.myChats(_uid),
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingView();
          final groups = snap.data!.where((t) => t.isGroup).toList();
          if (groups.isEmpty) {
            return const _EmptyState(
              icon: Icons.groups_outlined,
              text: "Aucun groupe pour l'instant.\nAppuie sur + pour en créer un.",
            );
          }
          return ListView.separated(
            itemCount: groups.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
            itemBuilder: (context, i) {
              final g = groups[i];
              final time = g.lastMessageAt != null ? DateFormat.Hm().format(g.lastMessageAt!) : '';
              return ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.navy, AppColors.navy2]),
                      borderRadius: BorderRadius.circular(13)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
                ),
                title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                subtitle: Text('${g.memberIds.length} membres · ${g.lastMessage}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.inkSoft)),
                trailing: Text(time, style: const TextStyle(fontSize: 11, color: AppColors.inkFaint)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: g.id,
                      title: g.name,
                      subtitle: '${g.memberIds.length} membres',
                      avatarLabel: g.name,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openCreateGroupSheet(BuildContext context) async {
    final fs = FirestoreService();
    final users = await fs.allUsersExcept(_uid);
    final nameCtrl = TextEditingController();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UserPickerSheet(
        title: 'Créer un groupe',
        users: users,
        singleSelect: false,
        nameController: nameCtrl,
        onConfirm: (selected) async {
          final name = nameCtrl.text.trim();
          if (name.isEmpty || selected.isEmpty) return;
          Navigator.pop(ctx);
          final chatId = await fs.createGroup(
            name: name,
            memberIds: selected.map((u) => u.uid).toList(),
            creatorId: _uid,
          );
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: chatId,
                title: name,
                subtitle: '${selected.length + 1} membres',
                avatarLabel: name,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Feuille partagée pour choisir un ou plusieurs utilisateurs
/// (nouvelle discussion en tête-à-tête ou création de groupe).
class _UserPickerSheet extends StatefulWidget {
  final String title;
  final List<AppUser> users;
  final bool singleSelect;
  final TextEditingController? nameController;
  final void Function(List<AppUser> selected) onConfirm;

  const _UserPickerSheet({
    required this.title,
    required this.users,
    required this.singleSelect,
    required this.onConfirm,
    this.nameController,
  });

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Container(
                  width: 38, height: 4,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(100))),
              const SizedBox(height: 16),
              Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
              if (widget.nameController != null) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: widget.nameController,
                  decoration: const InputDecoration(labelText: 'Nom du groupe'),
                ),
              ],
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: widget.users.length,
                  itemBuilder: (context, i) {
                    final u = widget.users[i];
                    final isSelected = _selected.contains(u.uid);
                    return CheckboxListTile(
                      value: isSelected,
                      activeColor: AppColors.orange,
                      onChanged: (v) {
                        setState(() {
                          if (widget.singleSelect) {
                            _selected
                              ..clear()
                              ..add(u.uid);
                          } else {
                            v == true ? _selected.add(u.uid) : _selected.remove(u.uid);
                          }
                        });
                      },
                      secondary: AppAvatar(label: u.username, photoUrl: u.photoUrl, size: 36),
                      title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onConfirm(
                    widget.users.where((u) => _selected.contains(u.uid)).toList(),
                  ),
                  child: Text(widget.singleSelect ? 'Discuter' : 'Créer le groupe'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =========================================================================
// PUBLICATIONS
// =========================================================================

class _PublicationsTab extends StatefulWidget {
  const _PublicationsTab();
  @override
  State<_PublicationsTab> createState() => _PublicationsTabState();
}

class _PublicationsTabState extends State<_PublicationsTab> {
  final _fs = FirestoreService();
  final _storage = StorageService();
  final _textCtrl = TextEditingController();
  final _picker = ImagePicker();
  File? _pickedImage;
  bool _publishing = false;
  String _myName = 'Toi';
  String? _myPhoto;

  @override
  void initState() {
    super.initState();
    _fs.watchUser(_uid).first.then((u) {
      if (u != null && mounted) setState(() {
        _myName = u.username;
        _myPhoto = u.photoUrl;
      });
    });
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _publish() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _pickedImage == null) return;
    setState(() => _publishing = true);
    try {
      String? imageUrl;
      final postId = DateTime.now().millisecondsSinceEpoch.toString();
      if (_pickedImage != null) {
        imageUrl = await _storage.uploadPostImage(postId, _pickedImage!);
      }
      await _fs.createPost(
        authorId: _uid,
        authorName: _myName,
        authorPhoto: _myPhoto,
        text: text,
        imageUrl: imageUrl,
      );
      _textCtrl.clear();
      setState(() => _pickedImage = null);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publications'), automaticallyImplyLeading: false),
      body: StreamBuilder<List<Post>>(
        stream: _fs.feed(),
        builder: (context, snap) {
          final posts = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _buildComposer(),
              if (!snap.hasData) const Padding(padding: EdgeInsets.all(24), child: LoadingView()),
              if (snap.hasData && posts.isEmpty)
                const _EmptyState(
                  icon: Icons.campaign_outlined,
                  text: 'Aucune publication pour le moment.\nSois le premier à partager une annonce.',
                ),
              ...posts.map((p) => _PostCard(post: p)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(label: _myName, photoUrl: _myPhoto, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Partage une annonce avec ta promotion...',
                    hintStyle: TextStyle(color: AppColors.inkFaint),
                  ),
                ),
              ),
            ],
          ),
          if (_pickedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_pickedImage!, height: 140, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6, right: 6,
                    child: InkWell(
                      onTap: () => setState(() => _pickedImage = null),
                      child: const CircleAvatar(
                          radius: 12, backgroundColor: Colors.black54,
                          child: Icon(Icons.close, size: 14, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_outlined, color: AppColors.inkSoft),
                onPressed: _pickImage,
                tooltip: 'Ajouter une image',
              ),
              const Spacer(),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: _publishing ? null : _publish,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18)),
                  child: _publishing
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Publier'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final Post post;
  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final _fs = FirestoreService();
  bool _showComments = false;
  final _commentCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final liked = post.likes.contains(_uid);
    final time = post.createdAt != null ? DateFormat('d MMM · HH:mm', 'fr_FR').format(post.createdAt!) : '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line), bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(label: post.authorName, photoUrl: post.authorPhoto, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                    Text(time, style: const TextStyle(fontSize: 11, color: AppColors.inkFaint)),
                  ],
                ),
              ),
            ],
          ),
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(post.text, style: const TextStyle(fontSize: 14, height: 1.5)),
            ),
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(imageUrl: post.imageUrl!, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _fs.toggleLike(post.id, _uid, liked),
                icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 18, color: liked ? AppColors.orange : AppColors.inkSoft),
                label: Text('${post.likes.length}',
                    style: TextStyle(color: liked ? AppColors.orange : AppColors.inkSoft, fontWeight: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showComments = !_showComments),
                icon: const Icon(Icons.mode_comment_outlined, size: 18, color: AppColors.inkSoft),
                label: Text('${post.commentCount}',
                    style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (_showComments) _buildComments(post),
        ],
      ),
    );
  }

  Widget _buildComments(Post post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<PostComment>>(
          stream: _fs.comments(post.id),
          builder: (context, snap) {
            final comments = snap.data ?? [];
            return Column(
              children: comments
                  .map((c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: AppColors.paper, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.authorName,
                                  style: const TextStyle(
                                      fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
                              Text(c.text, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  decoration: InputDecoration(
                    hintText: 'Écrire un commentaire...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    fillColor: AppColors.paper,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100), borderSide: BorderSide.none),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.blue, size: 20),
                onPressed: () async {
                  final text = _commentCtrl.text.trim();
                  if (text.isEmpty) return;
                  final me = await _fs.watchUser(_uid).first;
                  await _fs.addComment(post.id,
                      authorId: _uid, authorName: me?.username ?? 'Toi', text: text);
                  _commentCtrl.clear();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// PROFIL
// =========================================================================

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _authService = AuthService();
  final _storage = StorageService();
  final _fs = FirestoreService();
  final _picker = ImagePicker();
  bool _uploadingPhoto = false;

  Future<void> _changePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await _storage.uploadProfilePhoto(_uid, File(picked.path));
      await _fs.updateProfilePhoto(_uid, url);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), automaticallyImplyLeading: false),
      body: StreamBuilder<AppUser?>(
        stream: _authService.watchCurrentAppUser(),
        builder: (context, snap) {
          final user = snap.data;
          return ListView(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                color: AppColors.white,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        AppAvatar(label: user?.username ?? '?', photoUrl: user?.photoUrl, size: 84),
                        Positioned(
                          bottom: 0, right: 0,
                          child: InkWell(
                            onTap: _uploadingPhoto ? null : _changePhoto,
                            child: Container(
                              width: 30, height: 30,
                              decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: _uploadingPhoto
                                  ? const SizedBox(
                                      width: 14, height: 14,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(user?.username ?? '...', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFEEF3FF), borderRadius: BorderRadius.circular(100)),
                      child: Text('🎓 IN CRYPT Codage', style: TextStyle(fontSize: 12, color: AppColors.blue, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _ProfileRow(icon: Icons.notifications_outlined, label: 'Notifications'),
              _ProfileRow(icon: Icons.color_lens_outlined, label: 'Apparence'),
              _ProfileRow(icon: Icons.lock_outline_rounded, label: 'Confidentialité'),
              _ProfileRow(icon: Icons.help_outline_rounded, label: 'Aide & support'),
              _ProfileRow(
                icon: Icons.logout_rounded,
                label: 'Se déconnecter',
                danger: true,
                onTap: () => _authService.signOut(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback? onTap;
  const _ProfileRow({required this.icon, required this.label, this.danger = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.ink;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: danger ? AppColors.danger : AppColors.inkSoft, size: 20),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      shape: const Border(bottom: BorderSide(color: AppColors.line)),
    );
  }
}

// =========================================================================
// SHARED
// =========================================================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.inkFaint),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkFaint)),
          ],
        ),
      ),
    );
  }
}
