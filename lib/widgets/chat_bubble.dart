import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../main.dart';

class ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const ChatBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final content = message['content'] ?? '';
    final profile = message['profiles'] as Map<String, dynamic>?;
    final senderName = profile?['full_name'] ?? 'Unknown';
    final createdAt = message['created_at'] != null ? DateTime.parse(message['created_at']) : DateTime.now();
    final initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.dark : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe ? null : Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(senderName, style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  Text(content, style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(timeago.format(createdAt), style: TextStyle(color: isMe ? Colors.white54 : AppColors.textTertiary, fontSize: 10)),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }
}
