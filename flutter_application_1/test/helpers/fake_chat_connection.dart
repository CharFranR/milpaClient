import 'dart:async';

import 'package:flutter_application_1/features/buyer/chat_connection.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';

class FakeChatConnection implements ChatConnection {
  FakeChatConnection({this.connected = true});

  final StreamController<ChatMessage> _messagesController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  bool connected;
  int closeCalls = 0;
  final List<String> sentContents = <String>[];

  @override
  Stream<ChatMessage> get messages => _messagesController.stream;

  @override
  Stream<bool> get status => _statusController.stream;

  @override
  bool get isConnected => connected;

  void emitMessage(ChatMessage message) {
    if (!_messagesController.isClosed) {
      _messagesController.add(message);
    }
  }

  void emitStatus(bool value) {
    connected = value;
    if (!_statusController.isClosed) {
      _statusController.add(value);
    }
  }

  @override
  void send(String content) {
    sentContents.add(content);
  }

  @override
  Future<void> close() async {
    closeCalls++;
    connected = false;
    if (!_statusController.isClosed) {
      _statusController.add(false);
    }
    if (!_messagesController.isClosed) {
      await _messagesController.close();
    }
    if (!_statusController.isClosed) {
      await _statusController.close();
    }
  }
}
