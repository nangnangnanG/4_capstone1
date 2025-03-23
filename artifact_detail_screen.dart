import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/artifact_provider.dart';
import '../../services/api/api_service.dart';

class ArtifactDetailScreen extends StatefulWidget {
  final String artifactId;

  const ArtifactDetailScreen({Key? key, required this.artifactId}) : super(key: key);

  @override
  _ArtifactDetailScreenState createState() => _ArtifactDetailScreenState();
}

class _ArtifactDetailScreenState extends State<ArtifactDetailScreen> {
  bool _loadingFeeds = false;
  List<dynamic> _relatedFeeds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 유물 상세 정보 로드
    final artifactProvider = Provider.of<ArtifactProvider>(context, listen: false);
    await artifactProvider.fetchArtifactDetail(widget.artifactId);

    // 관련 피드 로드
    await _loadRelatedFeeds();
  }

  Future<void> _loadRelatedFeeds() async {
    setState(() {
      _loadingFeeds = true;
    });

    try {
      final artifactProvider = Provider.of<ArtifactProvider>(context, listen: false);
      _relatedFeeds = await artifactProvider.fetchArtifactFeeds(widget.artifactId);
    } catch (e) {
      print('관련 피드 로드 중 오류 발생: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingFeeds = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 상단 고정 이미지 (앱바처럼)
          Stack(
            children: [
              Image.asset(
                'assets/images/eaves.png',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              SafeArea(
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),

          // 유물 상세 정보
          Expanded(
            child: Consumer<ArtifactProvider>(
              builder: (context, artifactProvider, child) {
                if (artifactProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (artifactProvider.error.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 48),
                          SizedBox(height: 16),
                          Text(
                            artifactProvider.error,
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _loadData(),
                            child: Text('다시 시도'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final artifact = artifactProvider.currentArtifact;

                if (artifact == null) {
                  return Center(
                    child: Text(
                      '유물 정보를 찾을 수 없습니다.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 유물 이름 및 상태
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                artifact['name'] ?? '이름 없음',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(artifact['status']),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getStatusText(artifact['status']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // 유물 기본 정보
                        _buildInfoSection('기본 정보', [
                          if (artifact['time_period'] != null && artifact['time_period'].toString().isNotEmpty)
                            _buildInfoItem('시대', artifact['time_period']),
                          if (artifact['estimated_year'] != null && artifact['estimated_year'].toString().isNotEmpty)
                            _buildInfoItem('추정 연도', artifact['estimated_year']),
                          if (artifact['origin_location'] != null && artifact['origin_location'].toString().isNotEmpty)
                            _buildInfoItem('출토 위치', artifact['origin_location']),
                          _buildInfoItem('이미지 수', '${artifact['image_count'] ?? 0}개'),
                          _buildInfoItem('피드 수', '${artifact['feed_count'] ?? 0}개'),
                          _buildInfoItem('등록일', _formatDate(artifact['created_at'])),
                        ]),

                        // 유물 설명
                        if (artifact['description'] != null && artifact['description'].toString().isNotEmpty) ...[
                          SizedBox(height: 24),
                          _buildInfoSection('설명', [
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                artifact['description'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ]),
                        ],

                        // 3D 모델 유무 표시
                        if (artifact['has_3d_model'] == true) ...[
                          SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.view_in_ar, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      '3D 모델 제공',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '이 유물은 3D 모델을 제공합니다. 추후 기능이 구현될 예정입니다.',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // 관련 피드 섹션
                        SizedBox(height: 24),
                        _buildRelatedFeedsSection(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 정보 섹션 위젯
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  // 정보 항목 위젯
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 관련 피드 섹션 위젯
  Widget _buildRelatedFeedsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '관련 피드',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                // 모든 관련 피드 보기 화면으로 이동
              },
              child: Text('더 보기'),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (_loadingFeeds)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_relatedFeeds.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '관련 피드가 없습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          Container(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _relatedFeeds.length,
              itemBuilder: (context, index) {
                final feed = _relatedFeeds[index];
                return _buildFeedCard(feed);
              },
            ),
          ),
      ],
    );
  }

  // 피드 카드 위젯
  Widget _buildFeedCard(dynamic feed) {
    // 피드 이미지 URL 추출
    String imageUrl = '';
    if (feed is Map &&
        feed.containsKey('images') &&
        feed['images'] is List &&
        feed['images'].isNotEmpty &&
        feed['images'][0] is Map &&
        feed['images'][0].containsKey('image_url')) {
      imageUrl = feed['images'][0]['image_url'];
      imageUrl = _getFullImageUrl(imageUrl);
    }

    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 피드 이미지
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
                  : null,
              color: Colors.grey.shade700,
            ),
            child: imageUrl.isEmpty
                ? Center(
              child: Icon(Icons.image_not_supported, color: Colors.grey),
            )
                : null,
          ),

          // 피드 정보
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feed['title'] ?? '제목 없음',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  feed['content'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade300,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.remove_red_eye, size: 12, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      '${feed['view_count'] ?? 0}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

    // 베이스 URL 추가
    return '${ApiService.baseUrl}/$url';
  }

  // 날짜 포맷팅
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '알 수 없음';

    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}년 ${date.month}월 ${date.day}일';
    } catch (e) {
      return dateStr;
    }
  }

  // 유물 상태에 따른 색상 반환
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'featured':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'auto_generated':
      default:
        return Colors.orange;
    }
  }

  // 유물 상태에 따른 텍스트 반환
  String _getStatusText(String? status) {
    switch (status) {
      case 'verified':
        return '검증됨';
      case 'featured':
        return '주목할 만한';
      case 'rejected':
        return '거부됨';
      case 'auto_generated':
        return '자동 생성됨';
      default:
        return '알 수 없음';
    }
  }
}