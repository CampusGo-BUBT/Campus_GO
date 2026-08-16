import 'dart:io';
import '../models/book_model.dart';
import 'api_client.dart';

class BookService {
  static final _api = ApiClient.instance;

  Stream<List<BookModel>> getBooks() => pollStream(() => _fetch(''));

  Stream<List<BookModel>> getBooksByCondition(String condition) =>
      pollStream(() => _fetch('?condition=$condition'));

  Future<void> addBook(BookModel book, {File? image}) async {
    final fields = book.toMap()
      ..remove('id')
      ..remove('createdAt')
      ..remove('userId')
      ..remove('sellerName')
      ..remove('imageUrl');
    if (image != null) {
      await _api.postMultipart('/books/', fields: fields, files: {'image': image});
    } else {
      await _api.post('/books/', body: fields);
    }
  }

  Future<void> deleteBook(String bookId) async {
    await _api.delete('/books/$bookId/');
  }

  Future<List<BookModel>> _fetch(String query) async {
    final data = await _api.get('/books/$query');
    if (data is! List) return const [];
    return data
        .map((e) => BookModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()))
        .toList();
  }
}
