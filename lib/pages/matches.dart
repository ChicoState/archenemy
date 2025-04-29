import 'package:flutter/material.dart';
import '../profile.dart';

class ChatMessage {
  final String text;
  final bool isMine;
  ChatMessage({required this.text, required this.isMine});
}

class MatchesPage extends StatelessWidget {
  final List<Profile> profiles = [
    Profile.dummy("Match 1"),
    Profile.dummy("Match 2"),
    Profile.dummy("Match 3"),
  ];

  MatchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Matches"),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 1,
      ),
      backgroundColor: cs.surface,
      body: ListView.separated(
        itemCount: profiles.length,
        separatorBuilder: (_, __) => Divider(
          color: cs.onSurface.withValues(alpha: 0.2),
          indent: 16,
          endIndent: 16,
          height: 1,
        ),
        itemBuilder: (context, i) {
          final profile = profiles[i];
          final initial =
              profile.displayName.isNotEmpty ? profile.displayName[0] : '?';

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(profile: profile),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      initial,
                      style: txt.titleMedium
                          ?.copyWith(color: cs.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: txt.titleMedium?.copyWith(color: cs.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "[latest message...]",
                          style: txt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: cs.onSurface),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final Profile profile;
  const ChatPage({required this.profile, super.key});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.displayName),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),
      backgroundColor: cs.surface,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                return Align(
                  alignment:
                      msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: msg.isMine
                          ? cs.primaryContainer
                          : cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg.text,
                      style: txt.bodyMedium?.copyWith(
                        color: msg.isMine
                            ? cs.onPrimaryContainer
                            : cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        fillColor: cs.surface,
                        filled: true,
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: cs.primary),
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty) {
                        setState(() {
                          _messages.add(ChatMessage(text: text, isMine: true));
                        });
                        _controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
