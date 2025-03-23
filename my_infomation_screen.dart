import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/user_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/api/api_service.dart';
import '../feed/feed_detail_screen.dart';

class MyInformationScreenPage extends StatefulWidget {
  @override
  State<MyInformationScreenPage> createState() => _MyInformationScreenPageState();
}

class _MyInformationScreenPageState extends State<MyInformationScreenPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingFeeds = false;

  @override
  void initState() {
    super.initState();
    _refreshUserInfo();
    _loadMyFeeds();
  }

  // 사용자 정보 새로고침 메서드
  Future<void> _refreshUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<UserProvider>(context, listen: false).loadUserInfo(forceRefresh: true);
    } catch (e) {
      print("❌ 사용자 정보 새로고침 실패: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 내 피드 불러오기 메서드
  Future<void> _loadMyFeeds() async {
    setState(() {
      _isLoadingFeeds = true;
    });

    try {
      await Provider.of<FeedProvider>(context, listen: false).fetchMyFeeds();
    } catch (e) {
      print("❌ 내 피드 로드 실패: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFeeds = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final feedProvider = Provider.of<FeedProvider>(context);
    final myFeeds = feedProvider.myFeeds;

    return Scaffold(
      body: Column(
        children: [
          // ✅ 최상단 고정된 이미지 (앱바처럼 사용)
          Image.asset(
            'assets/images/eaves.png',
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          // ✅ 스크롤 가능한 컨텐츠 영역
          Expanded(
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _refreshUserInfo();
                  await _loadMyFeeds();
                },
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        child: _isLoading
                            ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 100.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 30),

                            // 프로필 이미지 영역
                            GestureDetector(
                              onTap: () => _pickImage(context, userProvider),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundImage: userProvider.profileImage.isNotEmpty
                                        ? NetworkImage(_getFullImageUrl(userProvider.profileImage))
                                        : AssetImage('assets/images/default_profile.png') as ImageProvider,
                                    child: userProvider.profileImage.isNotEmpty
                                        ? null
                                        : Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.grey.shade300, width: 2),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.grey.shade300, width: 1),
                                      ),
                                      child: Icon(Icons.camera_alt, size: 20, color: Colors.grey[600]),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 16),

                            // 사용자 이름 표시
                            Text(
                              userProvider.username,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            SizedBox(height: 8),
                            Text(
                              "랭크: ${userProvider.rank}",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade300,
                              ),
                            ),

                            SizedBox(height: 20),
                            Text(
                              "내 피드 수: ${feedProvider.myFeeds.length}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            SizedBox(height: 24),

                            ElevatedButton(
                              onPressed: () {
                                // 정보 수정 화면으로 이동 (구현 필요)
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.grey.shade800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text('정보 수정'),
                            ),

                            SizedBox(height: 30),

                            Divider(color: Colors.grey.shade700, thickness: 1),

                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(Icons.grid_on, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    '내 피드',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            _buildFeedGrid(myFeeds, context),

                            if (userProvider.error.isNotEmpty || feedProvider.error.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  userProvider.error.isNotEmpty ? userProvider.error : feedProvider.error,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  // 피드 그리드 빌더 메서드
  Widget _buildFeedGrid(List<dynamic> feeds, BuildContext context) {
    // 피드가 로딩 중이거나 비어있는 경우 처리
    if (_isLoadingFeeds) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (feeds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                '아직 게시한 피드가 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 그리드 뷰 생성
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // 스크롤 비활성화 (상위 스크롤에 통합)
      padding: EdgeInsets.symmetric(horizontal: 2),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 한 줄에 3개 항목
        crossAxisSpacing: 2, // 가로 간격
        mainAxisSpacing: 2, // 세로 간격
        childAspectRatio: 1, // 정사각형 비율
      ),
      itemCount: feeds.length,
      itemBuilder: (context, index) {
        final feed = feeds[index];

        // 이미지 URL 추출
        String imageUrl = '';
        if (feed is Map &&
            feed.containsKey('images') &&
            feed['images'] is List &&
            feed['images'].isNotEmpty &&
            feed['images'][0] is Map &&
            feed['images'][0].containsKey('image_url')) {
          imageUrl = feed['images'][0]['image_url'];
        }

        // 전체 URL로 변환
        imageUrl = _getFullImageUrl(imageUrl);

        return GestureDetector(
          onTap: () {
            // 피드 상세 페이지로 이동 (구현 필요)
            if (feed is Map && feed.containsKey('id')) {
              _navigateToFeedDetail(context, feed['id'].toString());
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
            ),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print("이미지 로딩 오류: $error, URL: $imageUrl");
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image, color: Colors.grey),
                      SizedBox(height: 4),
                      Text(
                        '이미지 오류',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            )
                : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_not_supported, color: Colors.grey),
                  SizedBox(height: 4),
                  Text(
                    '이미지 없음',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 상대 경로를 전체 URL로 변환
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

    // 베이스 URL 추가 (서버 주소를 하드코딩하지 말고 환경 설정에서 가져오는 것이 좋음)
    return "${ApiService.baseUrl}/$url";
  }

  // 피드 상세 페이지로 이동
  void _navigateToFeedDetail(BuildContext context, String feedId) async {
    // 피드 상세 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedDetailScreen(feedId: feedId),
      ),
    );

    // 피드가 삭제되었다면 내 피드 목록 새로고침
    if (result == true) {
      _loadMyFeeds();
    }
  }

  // 갤러리에서 이미지 선택 후 프로필 업데이트
  Future<void> _pickImage(BuildContext context, UserProvider userProvider) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
        });

        File imageFile = File(pickedFile.path);
        await userProvider.updateProfileImage(imageFile);

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ 이미지 선택 또는 업로드 중 오류 발생: $e");
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("이미지 업로드 중 오류가 발생했습니다.")),
      );
    }
  }
}