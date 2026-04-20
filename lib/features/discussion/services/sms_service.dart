import 'package:flutter/services.dart';
import '../models/sms_conversation.dart';
import '../models/sms_message.dart';

class SmsService {
  static const _channel = MethodChannel('handi_hub/sms');
  static const _eventChannel = EventChannel('handi_hub/sms_events');

  // Stream émis par Android chaque fois qu'un SMS est reçu.
  // Les pages s'y abonnent pour rafraîchir leur contenu automatiquement.
  static Stream<void> get smsEvents =>
      _eventChannel.receiveBroadcastStream().cast<void>();

  static Future<bool> isDefaultSmsApp() async {
    try {
      return await _channel.invokeMethod<bool>('isDefaultSmsApp') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestDefaultSmsApp() async {
    try {
      await _channel.invokeMethod('requestDefaultSmsApp');
    } catch (_) {}
  }

  static Future<bool> hasPermissions() async {
    try {
      return await _channel.invokeMethod<bool>('hasPermissions') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestPermissions() async {
    try {
      await _channel.invokeMethod('requestPermissions');
    } catch (_) {}
  }

  static Future<List<SmsConversation>> getConversations() async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('getConversations');
      return raw
              ?.map((e) => SmsConversation.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<SmsMessage>> getMessages(String threadId) async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>(
        'getMessages',
        {'threadId': threadId},
      );
      return raw
              ?.map((e) => SmsMessage.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [];
    } catch (_) {
      return [];
    }
  }

  // Retourne le threadId résolu si succès, null si échec.
  static Future<String?> sendSms(String address, String body, String threadId) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'sendSms',
        {'address': address, 'body': body, 'threadId': threadId},
      );
      return (result != null && result.isNotEmpty) ? result : null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> deleteThread(String threadId) async {
    try {
      return await _channel.invokeMethod<bool>('deleteThread', {'threadId': threadId}) ?? false;
    } catch (_) {
      return false;
    }
  }
}
