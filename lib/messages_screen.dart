import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/chat_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _showNewChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _NewChatSheet(chatService: _chatService),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.inversePrimary,
            child: TabBar(
              controller: _tabController!,
              indicatorColor: const Color.fromARGB(255, 183, 58, 58),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Chats'),
                Tab(text: 'People'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              children: [
                _ChatsTab(chatService: _chatService),
                _PeopleTab(chatService: _chatService),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: const Color.fromARGB(255, 183, 58, 58),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}

// ── Chats Tab ──────────────────────────────────────────────
class _ChatsTab extends StatelessWidget {
  final ChatService chatService;
  const _ChatsTab({required this.chatService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: chatService.getConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No conversations yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Tap the pencil icon to start a chat',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }

        final conversations = snapshot.data!;

        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final data =
                conversations[index].data() as Map<String, dynamic>;
            final conversationId = conversations[index].id;
            final isGroup = data['type'] == 'group';
            final myEmail = chatService.currentUser?.email ?? '';

            String title = '';
            String initials = '';
            if (isGroup) {
              title = data['name'] ?? 'Group';
              initials = title.isNotEmpty ? title[0].toUpperCase() : 'G';
            } else {
              final memberNames =
                  Map<String, String>.from(data['memberNames'] ?? {});
              final otherEntry = memberNames.entries.firstWhere(
                  (e) => e.key != myEmail,
                  orElse: () => const MapEntry('', 'Unknown'));
              title = otherEntry.value;
              initials = title.isNotEmpty ? title[0].toUpperCase() : '?';
            }

            final lastMessage = data['lastMessage'] ?? '';
            final lastSender = data['lastSenderName'] ?? '';
            final Timestamp? time =
                data['lastMessageTime'] as Timestamp?;
            final timeStr =
                time != null ? _formatTime(time.toDate()) : '';

            return ListTile(
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: isGroup
                    ? Colors.blue
                    : const Color.fromARGB(255, 183, 58, 58),
                child: isGroup
                    ? const Icon(Icons.group, color: Colors.white)
                    : Text(initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                lastMessage.isEmpty
                    ? 'No messages yet'
                    : '$lastSender: $lastMessage',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              trailing: Text(timeStr,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    conversationId: conversationId,
                    title: title,
                    isGroup: isGroup,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.month}/${time.day}';
  }
}

// ── People Tab ─────────────────────────────────────────────
class _PeopleTab extends StatelessWidget {
  final ChatService chatService;
  const _PeopleTab({required this.chatService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: chatService.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No other users found',
                style: TextStyle(color: Colors.grey)),
          );
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index].data() as Map<String, dynamic>;
            final name = data['displayName'] ??
                data['username'] ??
                'Unknown';
            final email = data['email'] ?? '';
            final initials = name.isNotEmpty
                ? name
                    .trim()
                    .split(' ')
                    .map((e) => e[0])
                    .take(2)
                    .join()
                    .toUpperCase()
                : '?';

            return ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor:
                    const Color.fromARGB(255, 183, 58, 58),
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
              title: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(email,
                  style:
                      TextStyle(color: Colors.grey[600], fontSize: 13)),
              trailing: IconButton(
                icon: const Icon(Icons.chat_bubble_outline,
                    color: Color.fromARGB(255, 183, 58, 58)),
                onPressed: () async {
                  final convId = await chatService
                      .getOrCreateDMConversation(email, name);
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: convId,
                        title: name,
                        isGroup: false,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ── New Chat Bottom Sheet ──────────────────────────────────
class _NewChatSheet extends StatefulWidget {
  final ChatService chatService;
  const _NewChatSheet({required this.chatService});

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final TextEditingController _groupNameController = TextEditingController();
  final List<Map<String, String>> _selectedUsers = [];
  bool _isCreatingGroup = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Conversation',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            Row(
              children: [
                const Text('Create group chat'),
                const Spacer(),
                Switch(
                  value: _isCreatingGroup,
                  activeThumbColor:
                      const Color.fromARGB(255, 183, 58, 58),
                  activeTrackColor:
                      const Color.fromARGB(255, 183, 58, 58)
                          .withValues(alpha: 0.5),
                  onChanged: (val) =>
                      setState(() => _isCreatingGroup = val),
                ),
              ],
            ),

            if (_isCreatingGroup) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Text('Select People',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            SizedBox(
              height: 250,
              child: StreamBuilder<QuerySnapshot>(
                stream: widget.chatService.getUsers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final data =
                          users[index].data() as Map<String, dynamic>;
                      final name = data['displayName'] ??
                          data['username'] ??
                          'Unknown';
                      final email = data['email'] ?? '';
                      final isSelected =
                          _selectedUsers.any((u) => u['email'] == email);

                      return CheckboxListTile(
                        value: isSelected,
                        activeColor:
                            const Color.fromARGB(255, 183, 58, 58),
                        title: Text(name),
                        subtitle: Text(email,
                            style: const TextStyle(fontSize: 12)),
                        secondary: CircleAvatar(
                          backgroundColor:
                              const Color.fromARGB(255, 183, 58, 58),
                          child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style:
                                const TextStyle(color: Colors.white),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedUsers
                                  .add({'email': email, 'name': name});
                            } else {
                              _selectedUsers.removeWhere(
                                  (u) => u['email'] == email);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedUsers.isEmpty
                    ? null
                    : () async {
                        String convId;

                        if (_isCreatingGroup) {
                          final groupName =
                              _groupNameController.text.trim();
                          if (groupName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please enter a group name')),
                            );
                            return;
                          }
                          convId = await widget.chatService
                              .createGroupConversation(
                                  groupName, _selectedUsers);
                        } else {
                          final user = _selectedUsers.first;
                          convId = await widget.chatService
                              .getOrCreateDMConversation(
                                  user['email']!, user['name']!);
                        }

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              conversationId: convId,
                              title: _isCreatingGroup
                                  ? _groupNameController.text.trim()
                                  : _selectedUsers.first['name']!,
                              isGroup: _isCreatingGroup,
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color.fromARGB(255, 183, 58, 58),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isCreatingGroup ? 'Create Group' : 'Start Chat',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}