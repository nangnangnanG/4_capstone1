import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api/api_service.dart';

class FeedDetailScreen extends StatefulWidget {
  final String feedId;

  const FeedDetailScreen({Key? key, required this.feedId}) : super(key: key);

  @override
  State<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends State<FeedDetailScreen> {
  bool _isLoading = true;
  PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFeedDetail();
  }

  Future<void> _loadFeedDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<FeedProvider>(context, listen: false)
          .fetchFeedDetail(widget.feedId);
    } catch (e) {
      print("❌ 피드 상세 정보 로드 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("피드 정보를 불러오는 중 오류가 발생했습니다.")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 이미지 URL 변환
  String _getFullImageUrl(String url) {
    if (url.isEmpty) return '';

    // 이미 전체 URL인 경우
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // 경로 정규화 (Windows 경로 문제 해결)
    url = url.replaceAll(r'\\', '/');

    // 상대 경로를 전체 URL로 변환
    if (url.startsWith('/')) {
      // 슬래시로 시작하는 경우, 첫 슬래시 제거
      url = url.substring(1);
    }

    // API 서비스의 baseUrl 사용
    return "${ApiService.baseUrl}/$url";
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = Provider.of<FeedProvider>(context);
    final feed = feedProvider.currentFeed;
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          // 상단 이미지 (앱바 대신 사용)
          Image.asset(
            'assets/images/eaves.png',
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          // 스크롤 가능한 본문
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : feed == null
                ? Center(child: Text("피드 정보를 불러올 수 없습니다."))
                : RefreshIndicator(
              onRefresh: _loadFeedDetail,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 작성자 정보
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // 프로필 이미지
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: feed['user'] != null &&
                                feed['user']['profile_image'] != null
                                ? NetworkImage(_getFullImageUrl(
                                feed['user']['profile_image']))
                                : AssetImage(
                                'assets/images/default_profile.png')
                            as ImageProvider,
                          ),
                          SizedBox(width: 12),
                          // 사용자 이름
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feed['user'] != null
                                    ? feed['user']['username'] ?? "사용자"
                                    : "사용자",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                feed['created_at'] != null
                                    ? _formatDate(feed['created_at'])
                                    : "",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          // 삭제/수정 버튼 (자신의 피드인 경우에만)
                          if (feed['user'] != null &&
                              feed['user']['id'] == userProvider.userId)
                            PopupMenuButton<String>(
                              color: Colors.grey[800],
                              icon: Icon(Icons.more_vert, color: Colors.white),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  // 수정 기능
                                  _editFeed(feed);
                                } else if (value == 'delete') {
                                  // 삭제 기능
                                  _showDeleteConfirmDialog(feed['id']);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('수정',
                                          style: TextStyle(
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      SizedBox(width: 8),
                                      Text('삭제',
                                          style: TextStyle(
                                              color: Colors.redAccent)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // 이미지 슬라이더
                    if (feed['images'] != null &&
                        feed['images'] is List &&
                        feed['images'].isNotEmpty)
                      Stack(
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.6,
                            ),
                            child: PageView.builder(
                              controller: _imagePageController,
                              itemCount: feed['images'].length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final imageUrl = _getFullImageUrl(
                                    feed['images'][index]['image_url']);
                                return Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child,
                                      loadingProgress) {
                                    if (loadingProgress == null)
                                      return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                            .expectedTotalBytes !=
                                            null
                                            ? loadingProgress
                                            .cumulativeBytesLoaded /
                                            loadingProgress
                                                .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image,
                                              color: Colors.grey,
                                              size: 50),
                                          SizedBox(height: 8),
                                          Text(
                                            '이미지를 불러올 수 없습니다',
                                            style: TextStyle(
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          // 이미지 인디케이터
                          if (feed['images'].length > 1)
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: List.generate(
                                  feed['images'].length,
                                      (index) => Container(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentImageIndex == index
                                          ? Colors.white
                                          : Colors.white
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                    // 유물 이름
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.category,
                              color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "유물명: ${feed['artifact_name'] ?? ''}",
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 피드 제목
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        feed['title'] ?? "",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // 피드 내용
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Text(
                        feed['content'] ?? "",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // 조회수 정보
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Row(
                        children: [
                          Icon(Icons.remove_red_eye,
                              color: Colors.grey[400], size: 16),
                          SizedBox(width: 4),
                          Text(
                            "조회수 ${feed['view_count'] ?? 0}",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 하단 여백
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // 뒤로가기 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: Colors.white.withOpacity(0.3),
        child: Icon(Icons.arrow_back),
        mini: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
    );
  }

  // 날짜 포맷팅
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        // 7일 이상이면 년월일 표시
        return "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";
      } else if (difference.inDays > 0) {
        // 1일 이상이면 n일 전
        return "${difference.inDays}일 전";
      } else if (difference.inHours > 0) {
        // 1시간 이상이면 n시간 전
        return "${difference.inHours}시간 전";
      } else if (difference.inMinutes > 0) {
        // 1분 이상이면 n분 전
        return "${difference.inMinutes}분 전";
      } else {
        // 그 외는 방금 전
        return "방금 전";
      }
    } catch (e) {
      return dateString;
    }
  }

  // 피드 수정 함수
  void _editFeed(dynamic feed) {
    // 피드 수정 화면으로 이동 (구현 필요)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("피드 수정 기능은 아직 구현되지 않았습니다.")),
    );
  }

  // 피드 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmDialog(String feedId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          title: Text('피드 삭제', style: TextStyle(color: Colors.white)),
          content: Text('이 피드를 정말 삭제하시겠습니까?',
              style: TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              child: Text('취소', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('삭제', style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFeed(feedId);
              },
            ),
          ],
        );
      },
    );
  }

  // 피드 삭제 함수
  Future<void> _deleteFeed(String feedId) async {
    try {
      final result = await Provider.of<FeedProvider>(context, listen: false)
          .deleteFeed(feedId);

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("피드가 삭제되었습니다.")),
        );
        Navigator.pop(context, true); // 삭제 성공 여부를 결과로 반환
      } else {
        final feedProvider = Provider.of<FeedProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("피드 삭제 실패: ${feedProvider.error}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("피드 삭제 중 오류가 발생했습니다: $e")),
      );
    }
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }
}