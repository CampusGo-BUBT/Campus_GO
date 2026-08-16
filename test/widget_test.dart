import 'package:flutter_test/flutter_test.dart';

import 'package:campusgo/models/feed_post.dart';
import 'package:campusgo/models/book_model.dart';
import 'package:campusgo/services/chat_service.dart';

void main() {
  test('FeedPost.fromMap parses backend JSON', () {
    final post = FeedPost.fromMap({
      'id': 'abc',
      'authorId': 'u1',
      'authorName': 'Arafat',
      'authorHandle': '@arafat',
      'caption': 'Hello campus',
      'likedBy': ['u1', 'u2'],
      'savedBy': <String>[],
      'commentCount': 3,
      'type': 'general',
      'createdAt': '2026-08-16T10:00:00Z',
    }, 'abc');

    expect(post.authorName, 'Arafat');
    expect(post.likedBy, ['u1', 'u2']);
    expect(post.commentCount, 3);
    expect(post.createdAt, isNotNull);
  });

  test('BookModel.fromMap handles missing fields with defaults', () {
    final book = BookModel.fromMap({'id': 'b1', 'title': 'DSA', 'author': 'Karumanchi', 'price': 350}, 'b1');
    expect(book.price, 350);
    expect(book.condition, 'Good');
    expect(book.imageUrl, '');
  });

  test('conversationIdFor is deterministic and sorted', () {
    expect(ChatService.conversationIdFor('b', 'a'), 'a_b');
    expect(ChatService.conversationIdFor('a', 'b'), 'a_b');
  });
}
