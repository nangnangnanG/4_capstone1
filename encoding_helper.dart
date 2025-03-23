import 'dart:convert';

class EncodingHelper {
  // 한국어 텍스트 디코딩 (일반적인 경우)
  static String fixKoreanText(String text) {
    if (text == null || text.isEmpty) return '';

    try {
      // 먼저 텍스트에 한글이 있는지 확인
      if (_containsKorean(text) || _containsEncodingIssues(text)) {
        // UTF-8로 디코딩 시도
        return utf8.decode(text.codeUnits);
      }
    } catch (e) {
      print('한국어 텍스트 디코딩 실패: $e');
    }

    return text;
  }

  // 중첩된 데이터 구조 전체에서 한국어 텍스트 수정
  static dynamic fixKoreanEncoding(dynamic data) {
    if (data == null) return data;

    if (data is String) {
      return fixKoreanText(data);
    } else if (data is Map) {
      Map result = {};
      data.forEach((key, value) {
        result[key] = fixKoreanEncoding(value);
      });
      return result;
    } else if (data is List) {
      return data.map((item) => fixKoreanEncoding(item)).toList();
    }

    return data;
  }

  // 한글 포함 여부 확인 (가-힣 범위)
  static bool _containsKorean(String text) {
    final koreanRegex = RegExp(r'[\uAC00-\uD7A3]');
    return koreanRegex.hasMatch(text);
  }

  // 인코딩 문제가 있는지 확인 (이상한 문자 조합)
  static bool _containsEncodingIssues(String text) {
    // 한글 깨진 형태에서 자주 나타나는 패턴 확인
    final suspiciousPatterns = [
      '?', '??', '???', // 물음표 연속
      '??', '??', '??', // 일반적인 깨진 패턴
      '??', '??', // 다른 깨진 패턴
    ];

    for (var pattern in suspiciousPatterns) {
      if (text.contains(pattern)) {
        return true;
      }
    }

    return false;
  }
}