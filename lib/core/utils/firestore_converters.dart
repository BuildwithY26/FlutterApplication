import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper to reliably serialize and deserialize timestamps across Firestore and local JSON.
class FirestoreConverters {
  FirestoreConverters._();

  static DateTime toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  static dynamic fromDateTime(DateTime? dateTime) {
    if (dateTime == null) return FieldValue.serverTimestamp();
    return Timestamp.fromDate(dateTime);
  }

  static List<String> toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}
