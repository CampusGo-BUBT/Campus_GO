import 'dart:convert';
import 'dart:io';

import 'package:campusgo/models/tutor_model.dart';
import 'package:campusgo/models/feed_post.dart';
import 'package:campusgo/models/study_group_model.dart';
import 'package:campusgo/models/book_model.dart';
import 'package:campusgo/models/job_model.dart';
import 'package:campusgo/models/hostel_model.dart';
import 'package:campusgo/models/notice_model.dart';
import 'package:campusgo/models/conversation_model.dart';
import 'package:campusgo/models/chat_model.dart';

Future<void> main(List<String> args) async {
  final path = args[0];
  final kind = args[1];
  final raw = File(path).readAsStringSync();
  final data = jsonDecode(raw);
  try {
    switch (kind) {
      case 'tutors':
        final list = (data as List).map((e) => TutorModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()));
        print('OK tutors count=${list.length}');
        break;
      case 'posts':
        final list = (data as List).map((e) => FeedPost.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()));
        print('OK posts count=${list.length}');
        break;
      case 'groups':
        final list = (data as List).map((e) => StudyGroupModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()));
        print('OK groups count=${list.length}');
        break;
      case 'books':
        final list = (data as List).map((e) => BookModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()));
        print('OK books count=${list.length}');
        break;
      case 'jobs':
        final list = (data as List).map((e) => JobModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()));
        print('OK jobs count=${list.length}');
        break;
      case 'hostels':
        final list = (data as List).map((e) => HostelModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()));
        print('OK hostels count=${list.length}');
        break;
      case 'notices':
        final list = (data as List).map((e) => NoticeModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()));
        print('OK notices count=${list.length}');
        break;
      case 'conversations':
        final list = (data as List).map((e) => ConversationModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()));
        print('OK conversations count=${list.length}');
        break;
      case 'chats':
        final list = (data as List).map((e) => ChatModel.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()));
        print('OK chats count=${list.length}');
        break;
    }
  } catch (e, st) {
    print('PARSE ERROR for $kind: $e');
    print(st);
  }
}