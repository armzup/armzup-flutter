// lib/features/members/providers/member_provider.dart
import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../data/member_repository.dart';

class MemberProvider extends ChangeNotifier {
  final MemberRepository _repository = MemberRepository();

  List<MemberModel> _members = [];
  List<MemberModel> get members => _members;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  String? _ownerId;

  void init(String ownerId) {
    _ownerId = ownerId;
    _listenMembers(ownerId);
  }

  void _listenMembers(String ownerId) {
    _repository.streamMembers(ownerId).listen((list) {
      _members = list;
      _error = null; // Clear any previous errors
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    if (_ownerId != null) {
      _loading = true;
      _error = null;
      notifyListeners();
      try {
        _members = await _repository.streamMembers(_ownerId!).first;
      } catch (e) {
        _error = e.toString();
        debugPrint("Error refreshing members: $e");
      }
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addMember(MemberModel member) async {
    _error = null;
    notifyListeners();
    try {
      await _repository.addMember(member);
      await refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint("Add member error: $e");
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMember(MemberModel member) async {
    _error = null;
    notifyListeners();
    try {
      await _repository.updateMember(member);
      await refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint("Update member error: $e");
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMember(String memberId) async {
    if (_ownerId == null) return false;
    _error = null;
    notifyListeners();
    try {
      await _repository.deleteMember(memberId);
      await refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint("Delete member error: $e");
      notifyListeners();
      return false;
    }
  }
}
