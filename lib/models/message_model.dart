import 'package:flutter/material.dart';

class MessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Widget? card;

  MessageModel({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.card,
  }) : timestamp = timestamp ?? DateTime.now();
}
