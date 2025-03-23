import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api/artifact_api.dart';

class ArtifactProvider extends ChangeNotifier {
  List<dynamic> _artifacts = [];
  List<dynamic> _filteredArtifacts = [];
  dynamic _currentArtifact;
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';

  // Getters
  List<dynamic> get artifacts => _artifacts;
  List<dynamic> get filteredArtifacts => _filteredArtifacts;
  dynamic get currentArtifact => _currentArtifact;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;

  // 검색어 설정 및 결과 필터링
  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterArtifacts();
    notifyListeners();
  }

  // 검색어에 따른 유물 필터링
  void _filterArtifacts() {
    if (_searchQuery.isEmpty) {
      _filteredArtifacts = List.from(_artifacts);
      return;
    }

    final lowercaseQuery = _searchQuery.toLowerCase();
    _filteredArtifacts = _artifacts.where((artifact) {
      // 이름 검색
      final name = artifact['name']?.toString().toLowerCase() ?? '';
      if (name.contains(lowercaseQuery)) return true;

      // 설명 검색
      final description = artifact['description']?.toString().toLowerCase() ?? '';
      if (description.contains(lowercaseQuery)) return true;

      // 시대 검색
      final timePeriod = artifact['time_period']?.toString().toLowerCase() ?? '';
      if (timePeriod.contains(lowercaseQuery)) return true;

      // 출토 위치 검색
      final originLocation = artifact['origin_location']?.toString().toLowerCase() ?? '';
      if (originLocation.contains(lowercaseQuery)) return true;

      return false;
    }).toList();
  }

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

  // 모든 유물 가져오기
  Future<void> fetchArtifacts({String status = 'verified'}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final result = await ArtifactApi.fetchArtifacts(status: status);

      _processApiResult(result, (data) {
        if (data is List) {
          _artifacts = data;
        } else if (data is Map && data.containsKey('results') && data['results'] is List) {
          _artifacts = data['results'];
        } else if (data is Map) {
          _artifacts = [data];
        } else {
          _error = '예상치 못한 응답 형식입니다';
        }
        _filterArtifacts(); // 초기 필터링 적용
      });
    } catch (e) {
      _error = '유물을 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 유물 상세 정보 가져오기
  Future<void> fetchArtifactDetail(String artifactId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final result = await ArtifactApi.fetchArtifactDetail(artifactId);

      _processApiResult(result, (data) {
        _currentArtifact = data;
      });
    } catch (e) {
      _error = '유물 상세 정보를 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 유물 관련 피드 가져오기
  Future<List<dynamic>> fetchArtifactFeeds(String artifactId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final result = await ArtifactApi.fetchArtifactFeeds(artifactId);
      List<dynamic> feeds = [];

      _processApiResult(result, (data) {
        if (data is Map && data.containsKey('results') && data['results'] is List) {
          feeds = data['results'];
        } else if (data is List) {
          feeds = data;
        }
      });

      _isLoading = false;
      notifyListeners();
      return feeds;
    } catch (e) {
      _error = '유물 관련 피드를 불러오는 중 오류가 발생했습니다: $e';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // 오류 초기화
  void clearError() {
    _error = '';
    notifyListeners();
  }
}