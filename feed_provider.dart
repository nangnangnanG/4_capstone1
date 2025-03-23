import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api/feed_api.dart';

class FeedProvider extends ChangeNotifier {
  // 피드 관련 데이터를 저장할 변수들
  List<dynamic> _feeds = [];
  List<dynamic> _myFeeds = [];
  dynamic _currentFeed;
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<dynamic> get feeds => _feeds;
  List<dynamic> get myFeeds => _myFeeds;
  dynamic get currentFeed => _currentFeed;
  bool get isLoading => _isLoading;
  String get error => _error;

  // API 결과를 안전하게 처리하는 헬퍼 메서드
  void _processApiResult(dynamic result, Function(dynamic data) onSuccess) {
    if (result == null) {
      _error = '응답이 없습니다';
      return;
    }

    // 문자열인 경우 JSON으로 파싱 시도
    if (result is String) {
      try {
        result = jsonDecode(result);
      } catch (e) {
        _error = '응답 형식이 올바르지 않습니다: $e';
        return;
      }
    }

    // 에러 확인
    if (result is Map && result.containsKey('error')) {
      _error = result['error'].toString();
      return;
    }

    // 성공 처리
    onSuccess(result);
  }

  // 모든 피드 가져오기
  Future<void> fetchFeeds() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final result = await FeedApi.fetchFeeds();

      _processApiResult(result, (data) {
        if (data is List) {
          _feeds = data;
        } else if (data is Map && data.containsKey('results') && data['results'] is List) {
          _feeds = data['results'];
        } else if (data is Map) {
          _feeds = [data];
        } else {
          _error = '예상치 못한 응답 형식입니다';
        }
      });
    } catch (e) {
      _error = '피드를 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 내 피드 가져오기
  Future<void> fetchMyFeeds() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final result = await FeedApi.fetchMyFeeds();

      _processApiResult(result, (data) {
        if (data is List) {
          _myFeeds = data;
        } else if (data is Map && data.containsKey('results') && data['results'] is List) {
          _myFeeds = data['results'];
        } else if (data is Map) {
          _myFeeds = [data];
        } else {
          _error = '예상치 못한 응답 형식입니다';
        }
      });
    } catch (e) {
      _error = '내 피드를 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 피드 상세 정보 가져오기
  Future<void> fetchFeedDetail(String feedId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final result = await FeedApi.fetchFeedDetail(feedId);

      _processApiResult(result, (data) {
        _currentFeed = data;
      });
    } catch (e) {
      _error = '피드 상세 정보를 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 피드 생성하기 (진행률 콜백 추가)
  Future<bool> createFeed({
    required String title,
    required String content,
    required String artifactName,
    required List<File> images,
    Function(double progress)? onProgress,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final result = await FeedApi.createFeed(
        title: title,
        content: content,
        artifactName: artifactName,
        images: images,
        onProgress: onProgress,
      );

      bool success = false;

      _processApiResult(result, (data) {
        _currentFeed = data;
        success = true;
      });

      if (success) {
        // 성공 후 서버에 피드가 완전히 저장될 시간을 확보
        await Future.delayed(Duration(milliseconds: 500));
        await fetchMyFeeds();
        return true;
      }

      return false;
    } catch (e) {
      _error = '피드 생성 중 오류가 발생했습니다: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 피드 업데이트하기
  Future<bool> updateFeed({
    required String feedId,
    String? title,
    String? content,
    String? artifactName,
    String? status,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final result = await FeedApi.updateFeed(
        feedId: feedId,
        title: title,
        content: content,
        artifactName: artifactName,
        status: status,
      );

      bool success = false;

      _processApiResult(result, (data) {
        if (_currentFeed != null && _getIdFromFeed(_currentFeed) == feedId) {
          _currentFeed = data;
        }
        success = true;
      });

      if (success) {
        await fetchFeeds();
        await fetchMyFeeds();
        return true;
      }

      return false;
    } catch (e) {
      _error = '피드 업데이트 중 오류가 발생했습니다: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 피드 삭제하기
  Future<bool> deleteFeed(String feedId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final result = await FeedApi.deleteFeed(feedId);

      bool success = false;

      _processApiResult(result, (data) {
        success = true;
      });

      if (success) {
        if (_currentFeed != null && _getIdFromFeed(_currentFeed) == feedId) {
          _currentFeed = null;
        }

        _feeds = _removeItemById(_feeds, feedId);
        _myFeeds = _removeItemById(_myFeeds, feedId);

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _error = '피드 삭제 중 오류가 발생했습니다: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 피드에서 ID 안전하게 가져오기
  String? _getIdFromFeed(dynamic feed) {
    if (feed is Map && feed.containsKey('id')) {
      return feed['id'].toString();
    }
    return null;
  }

  // ID로 항목 제거하기
  List<dynamic> _removeItemById(List<dynamic> items, String id) {
    return items.where((item) {
      String? itemId = _getIdFromFeed(item);
      return itemId != id;
    }).toList();
  }

  // 오류 초기화
  void clearError() {
    _error = '';
    notifyListeners();
  }
}