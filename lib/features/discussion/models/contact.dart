import 'dart:typed_data';

class Contact {
  final String id;
  final String name;
  final List<String> phones;
  final Uint8List? photo;

  const Contact({
    required this.id,
    required this.name,
    required this.phones,
    this.photo,
  });

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
        id: map['id'] as String,
        name: map['name'] as String,
        phones: List<String>.from(map['phones'] as List),
        photo: map['photo'] != null
            ? Uint8List.fromList(List<int>.from(map['photo'] as List))
            : null,
      );
}
