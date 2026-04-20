class SmsMessage {
  const SmsMessage({
    required this.id,
    required this.threadId,
    required this.address,
    required this.body,
    required this.date,
    required this.isIncoming,
  });

  final String id;
  final String threadId;
  final String address;
  final String body;
  final int date;
  final bool isIncoming;

  factory SmsMessage.fromMap(Map<String, dynamic> map) {
    return SmsMessage(
      id: map['id'] as String? ?? '',
      threadId: map['threadId'] as String? ?? '',
      address: map['address'] as String? ?? '',
      body: map['body'] as String? ?? '',
      date: map['date'] as int? ?? 0,
      isIncoming: (map['type'] as int? ?? 1) == 1,
    );
  }
}
