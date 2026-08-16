import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../models/conversation_model.dart';
import 'api_client.dart';

class ChatService {
  static final _api = ApiClient.instance;

  // Real-time group messages stream (backend polls Firestore).
  Stream<List<ChatModel>> getMessages(String groupId) {
    return pollStream(() async {
      final data = await _api.get('/study-groups/$groupId/messages/');
      return _parseMessages(data);
    });
  }

  // Send group message.
  Future<void> sendMessage({
    required String groupId,
    required String message,
    required String senderId,
    required String senderName,
  }) async {
    await _api.post('/study-groups/$groupId/messages/', body: {
      'message': message,
      'senderId': senderId,
      'senderName': senderName,
    });
  }

  // Streams every conversation belonging to the logged-in user.
  Stream<List<ConversationModel>> getInbox() {
    return pollStream(() async {
      final data = await _api.get('/conversations/');
      if (data is! List) return <ConversationModel>[];
      return data
          .map((e) => ConversationModel.fromMap(
              Map<String, dynamic>.from(e as Map), e['id'].toString()))
          .toList();
    });
  }

  // Streams 1-to-1 direct messages (empty while no conversation exists yet).
  Stream<List<ChatModel>> getDirectMessages(String otherUserId) {
    return pollStream(() async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || otherUserId.trim().isEmpty) return <ChatModel>[];
      final convId = conversationIdFor(uid, otherUserId);
      try {
        final data = await _api.get('/conversations/$convId/messages/');
        return _parseMessages(data);
      } on ApiException catch (e) {
        if (e.statusCode == 404) return <ChatModel>[];
        rethrow;
      }
    });
  }

  // Sends a 1-to-1 direct message.
  Future<void> sendDirectMessage({
    required String otherUserId,
    required String message,
    required String senderName,
  }) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) return;
    await _api.post('/conversations/send/', body: {
      'otherUserId': otherUserId,
      'message': cleanMessage,
    });
  }

  // Deterministic Conversation ID generator (matches the backend).
  static String conversationIdFor(String firstUid, String secondUid) {
    final ids = [firstUid, secondUid]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  List<ChatModel> _parseMessages(dynamic data) {
    if (data is! List) return const [];
    return data
        .map((e) => ChatModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()))
        .toList();
  }
}
