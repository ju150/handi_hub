class SmsConversation {
  const SmsConversation({
    required this.threadId,
    required this.address,
    required this.snippet,
    required this.date,
    required this.isRead,
  });

  final String threadId;
  final String address;
  final String snippet;
  final int date;
  final bool isRead;

  factory SmsConversation.fromMap(Map<String, dynamic> map) {
    return SmsConversation(
      threadId: map['threadId'] as String? ?? '',
      address: map['address'] as String? ?? '',
      snippet: map['snippet'] as String? ?? '',
      date: map['date'] as int? ?? 0,
      isRead: map['isRead'] as bool? ?? true,
    );
  }
}
