import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/features/buyer/conversation_models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class ChatConnection {
  Stream<ChatMessage> get messages;
  Stream<bool> get status;
  bool get isConnected;
  void send(String content);
  Future<void> close();
}

class WebSocketChatConnection implements ChatConnection {
  WebSocketChatConnection({required Uri uri, required String token}) {
    _channel = WebSocketChannel.connect(
      uri,
      protocols: <String>['milpa.chat.v1', 'bearer.$token'],
    );
    _channel.ready.then<void>(
      (_) => _handleReady(),
      onError: _handleReadyError,
    );
    _channel.stream.listen(
      _handleFrame,
      onError: _handleStreamError,
      onDone: _markDisconnected,
      cancelOnError: false,
    );
  }

  late final WebSocketChannel _channel;
  final StreamController<ChatMessage> _messagesController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();
  bool _connected = false;
  bool _closed = false;

  @override
  Stream<ChatMessage> get messages => _messagesController.stream;

  @override
  Stream<bool> get status => _statusController.stream;

  @override
  bool get isConnected => _connected;

  void _handleReady() {
    if (_closed) {
      return;
    }
    _connected = true;
    if (!_statusController.isClosed) {
      _statusController.add(true);
    }
  }

  void _handleReadyError(Object error) {
    _markDisconnected();
  }

  void _handleStreamError(Object error, StackTrace stackTrace) {
    _markDisconnected();
  }

  void _handleFrame(dynamic frame) {
    if (_closed || frame is! String) {
      return;
    }
    try {
      final dynamic decoded = jsonDecode(frame);
      if (decoded is Map<String, dynamic>) {
        _messagesController.add(ChatMessage.fromJson(decoded));
      }
    } on FormatException {
      return;
    } on TypeError {
      return;
    }
  }

  void _markDisconnected() {
    if (_closed) {
      return;
    }
    _connected = false;
    if (!_statusController.isClosed) {
      _statusController.add(false);
    }
  }

  @override
  void send(String content) {
    if (!_connected) {
      return;
    }
    _channel.sink.add(content);
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _connected = false;
    if (!_statusController.isClosed) {
      _statusController.add(false);
    }
    try {
      await _channel.sink.close();
    } finally {
      await _messagesController.close();
      await _statusController.close();
    }
  }
}
