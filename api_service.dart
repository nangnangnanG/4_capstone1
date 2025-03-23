import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://172.17.8.86:8000";

  // ✅ SharedPreferences에서 user_id 가져오기 (모든 API에서 사용)
  static Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_id");
  }

  // ✅ 공통 HTTP 요청 핸들러 (GET, POST, PATCH)
  static Future<dynamic> sendRequest({
    required String endpoint,
    String method = "GET",
    Map<String, dynamic>? body,
    File? file,
  }) async {
    final url = Uri.parse("$baseUrl$endpoint");
    print("🔍 API 요청: $method $url");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('auth_token');

    // ✅ 변경됨: UTF-8 인코딩 설정 추가
    Map<String, String> headers = {
      "Content-Type": "application/json; charset=UTF-8", // ✅ 변경됨
    };

    if (authToken != null && authToken.isNotEmpty) {
      headers["Authorization"] = "Token $authToken";
      print("📱 사용 중인 인증 토큰: $authToken");
    } else {
      print("⚠️ 인증 토큰이 없습니다!");
    }

    try {
      http.Response response;

      if (method == "GET") {
        response = await http.get(url, headers: headers);
      } else if (method == "POST") {
        print("🔍 POST 요청 본문: ${jsonEncode(body)}");
        response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
      } else if (method == "PATCH") {
        var request = http.MultipartRequest("PATCH", url);

        headers.forEach((key, value) {
          if (key != "Content-Type") {
            request.headers[key] = value;
          }
        });

        if (body != null) {
          body.forEach((key, value) {
            if (value != null) {
              request.fields[key] = value.toString();
            }
          });
        }

        print("🔍 PATCH 요청 필드: ${body}");
        print("🔍 PATCH 요청 헤더: ${headers}");

        if (file != null) {
          request.files.add(
            await http.MultipartFile.fromPath("file", file.path, filename: basename(file.path)),
          );
          print("🔍 파일 추가: ${file.path}");
        }

        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else if (method == "DELETE") {
        response = await http.delete(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      } else {
        return {"error": "Invalid HTTP method"};
      }

      print("🔍 응답 상태 코드: ${response.statusCode}");
      print("🔍 응답 헤더: ${response.headers}");

      if (response.body.length < 1000) {
        print("🔍 응답 본문: ${utf8.decode(response.bodyBytes)}"); // ✅ 변경됨
      } else {
        print("🔍 응답 본문 (일부): ${utf8.decode(response.bodyBytes).substring(0, 500)}..."); // ✅ 변경됨
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        print("⚠️ 인증 오류 (${response.statusCode}): 토큰이 만료되었거나 유효하지 않을 수 있습니다.");
        return {
          "error": "인증이 만료되었습니다. 다시 로그인해 주세요.",
          "status": response.statusCode
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {"message": "Success"};
        }
        try {
          var decoded = utf8.decode(response.bodyBytes); // ✅ 변경됨
          var result = jsonDecode(decoded);              // ✅ 변경됨
          print("📊 API 응답 성공: $result");
          return result;
        } catch (e) {
          print("❌ JSON 파싱 오류: $e");
          return {"error": "응답을 파싱할 수 없습니다: ${utf8.decode(response.bodyBytes)}"}; // ✅ 변경됨
        }
      } else {
        print("❌ HTTP 오류 상태 코드: ${response.statusCode}");
        try {
          var decoded = utf8.decode(response.bodyBytes); // ✅ 변경됨
          return jsonDecode(decoded);                    // ✅ 변경됨
        } catch (e) {
          return {"error": "서버 오류: ${response.statusCode}", "body": utf8.decode(response.bodyBytes)}; // ✅ 변경됨
        }
      }
    } catch (e) {
      print("❌ API 요청 실패 상세 내용: $e");
      if (e is SocketException) {
        return {"error": "네트워크 연결 실패: ${e.message}"};
      } else if (e is HttpException) {
        return {"error": "HTTP 요청 실패: ${e.message}"};
      } else if (e is FormatException) {
        return {"error": "응답 형식 오류: ${e.message}"};
      } else if (e is TimeoutException) {
        return {"error": "요청 시간 초과"};
      } else {
        return {"error": "Request Failed: ${e.toString()}"};
      }
    }
  }

  // ✅ 여러 파일이 있는 Multipart 요청 처리
  static Future<dynamic> sendMultipartRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? fields,
    List<Map<String, dynamic>>? files,
  }) async {
    final url = Uri.parse("$baseUrl$endpoint");
    print("🔍 Multipart API 요청: $method $url");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('auth_token');

    try {
      var request = http.MultipartRequest(method, url);

      if (authToken != null && authToken.isNotEmpty) {
        request.headers["Authorization"] = "Token $authToken";
        print("📱 사용 중인 인증 토큰: $authToken");
      } else {
        print("⚠️ 인증 토큰이 없습니다!");
      }

      if (fields != null) {
        fields.forEach((key, value) {
          if (value != null) {
            request.fields[key] = value.toString();
          }
        });
        print("🔍 Multipart 요청 필드: ${fields}");
      }

      if (files != null) {
        for (var fileInfo in files) {
          String fieldName = fileInfo["name"];
          File file = fileInfo["file"];

          request.files.add(
            await http.MultipartFile.fromPath(
                fieldName,
                file.path,
                filename: basename(file.path)
            ),
          );
          print("🔍 파일 추가: ${fieldName} - ${file.path}");
        }
      }

      print("🔍 Multipart 요청 헤더: ${request.headers}");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("🔍 응답 상태 코드: ${response.statusCode}");
      print("🔍 응답 헤더: ${response.headers}");

      if (response.body.length < 1000) {
        print("🔍 응답 본문: ${utf8.decode(response.bodyBytes)}"); // ✅ 변경됨
      } else {
        print("🔍 응답 본문 (일부): ${utf8.decode(response.bodyBytes).substring(0, 500)}..."); // ✅ 변경됨
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        print("⚠️ 인증 오류 (${response.statusCode}): 토큰이 만료되었거나 유효하지 않을 수 있습니다.");
        return {
          "error": "인증이 만료되었습니다. 다시 로그인해 주세요.",
          "status": response.statusCode
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {"message": "Success"};
        }
        try {
          var decoded = utf8.decode(response.bodyBytes); // ✅ 변경됨
          return jsonDecode(decoded);                    // ✅ 변경됨
        } catch (e) {
          print("❌ JSON 파싱 오류: $e");
          return {"error": "응답을 파싱할 수 없습니다: ${utf8.decode(response.bodyBytes)}"}; // ✅ 변경됨
        }
      } else {
        print("❌ HTTP 오류 상태 코드: ${response.statusCode}");
        try {
          var decoded = utf8.decode(response.bodyBytes); // ✅ 변경됨
          return jsonDecode(decoded);                    // ✅ 변경됨
        } catch (e) {
          return {"error": "서버 오류: ${response.statusCode}", "body": utf8.decode(response.bodyBytes)}; // ✅ 변경됨
        }
      }
    } catch (e) {
      print("❌ Multipart 요청 실패 상세 내용: $e");
      if (e is SocketException) {
        return {"error": "네트워크 연결 실패: ${e.message}"};
      } else if (e is HttpException) {
        return {"error": "HTTP 요청 실패: ${e.message}"};
      } else if (e is FormatException) {
        return {"error": "응답 형식 오류: ${e.message}"};
      } else if (e is TimeoutException) {
        return {"error": "요청 시간 초과"};
      } else {
        return {"error": "Request Failed: ${e.toString()}"};
      }
    }
  }
}
