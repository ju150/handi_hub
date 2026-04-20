import 'package:flutter/services.dart';
import '../models/contact.dart';

class ContactsService {
  static const _channel = MethodChannel('handi_hub/sms');

  static List<Contact>? _cache;

  static Future<List<Contact>> getContacts() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('getContacts');
      _cache = raw
              ?.map((e) => Contact.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [];
      return _cache!;
    } catch (_) {
      _cache = [];
      return _cache!;
    }
  }

  static void clearCache() => _cache = null;

  // Retourne le nom du contact correspondant à ce numéro, ou null.
  static Future<String?> lookupName(String phone) async {
    final contacts = await getContacts();
    final n = normalize(phone);
    for (final c in contacts) {
      if (c.phones.any((p) => normalize(p) == n)) return c.name;
    }
    return null;
  }

  // Construit un cache phone→name pour les listes (évite N appels async).
  static Future<Map<String, String>> buildNameMap(List<String> phones) async {
    final contacts = await getContacts();
    final result = <String, String>{};
    for (final phone in phones) {
      final n = normalize(phone);
      for (final c in contacts) {
        if (c.phones.any((p) => normalize(p) == n)) {
          result[phone] = c.name;
          break;
        }
      }
    }
    return result;
  }

  // Construit un cache phone→photo pour les favoris.
  static Future<Map<String, Uint8List?>> buildPhotoMap(List<String> phones) async {
    final contacts = await getContacts();
    final result = <String, Uint8List?>{};
    for (final phone in phones) {
      final n = normalize(phone);
      for (final c in contacts) {
        if (c.phones.any((p) => normalize(p) == n)) {
          result[phone] = c.photo;
          break;
        }
      }
    }
    return result;
  }

  // Trouve le contact correspondant à un numéro.
  static Future<Contact?> findByPhone(String phone) async {
    final contacts = await getContacts();
    final n = normalize(phone);
    for (final c in contacts) {
      if (c.phones.any((p) => normalize(p) == n)) return c;
    }
    return null;
  }

  static String normalize(String phone) {
    var p = phone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (p.startsWith('+33')) p = '0${p.substring(3)}';
    if (p.startsWith('0033')) p = '0${p.substring(4)}';
    return p;
  }
}
