import 'package:flutter/material.dart';

class SavedPostsService extends ChangeNotifier {
  final Set<String> _savedPostIds = {};

  bool isSaved(String postId) => _savedPostIds.contains(postId);

  void toggleSave(String postId) {
    if (_savedPostIds.contains(postId)) {
      _savedPostIds.remove(postId);
    } else {
      _savedPostIds.add(postId);
    }
    notifyListeners();
  }

  Set<String> get savedIds => _savedPostIds;
}