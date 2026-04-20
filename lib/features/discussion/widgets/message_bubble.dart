import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../models/sms_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final SmsMessage message;

  String _formatTime(int timestamp) {
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final incoming = message.isIncoming;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: incoming ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (incoming) ...[
            const CircleAvatar(
              radius: 18,
              backgroundColor: HandiTheme.accent,
              child: Icon(Icons.person, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: incoming ? HandiTheme.surface : HandiTheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: incoming ? Radius.zero : const Radius.circular(16),
                  bottomRight: incoming ? const Radius.circular(16) : Radius.zero,
                ),
                border: incoming ? Border.all(color: const Color(0xFFE0E0E0)) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.body,
                    style: TextStyle(
                      fontSize: HandiTheme.fontSize,
                      color: incoming ? HandiTheme.textPrimary : Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: incoming ? HandiTheme.textSecondary : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!incoming) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
