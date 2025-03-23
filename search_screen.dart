import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/artifact_provider.dart';
import 'artifact_detail_screen.dart';

class SearchScreenPage extends StatefulWidget {
  @override
  _SearchScreenPageState createState() => _SearchScreenPageState();
}

class _SearchScreenPageState extends State<SearchScreenPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_isFirstLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final artifactProvider = Provider.of<ArtifactProvider>(context, listen: false);
        artifactProvider.fetchArtifacts(status: 'all');
      });
      _isFirstLoad = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 상단 고정 이미지 (앱바처럼)
          Image.asset(
            'assets/images/eaves.png',
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          // 검색 영역
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '유물 검색',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                _buildSearchBar(),
              ],
            ),
          ),

          // 검색 결과 영역
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
                            onPressed: () => artifactProvider.fetchArtifacts(status: 'all'),
                            child: Text('다시 시도'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final artifacts = artifactProvider.filteredArtifacts;

                if (artifacts.isEmpty) {
                  if (artifactProvider.searchQuery.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, color: Colors.grey, size: 48),
                          SizedBox(height: 16),
                          Text(
                            '등록된 유물이 없습니다.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, color: Colors.grey, size: 48),
                          SizedBox(height: 16),
                          Text(
                            '검색 결과가 없습니다.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '"${artifactProvider.searchQuery}"에 대한 검색 결과가 없습니다.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                }

                return _buildArtifactList(artifacts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer<ArtifactProvider>(
      builder: (context, artifactProvider, child) {
        _searchController.text = artifactProvider.searchQuery;

        return TextField(
          controller: _searchController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: '유물 이름, 시대, 출토지 검색',
            prefixIcon: Icon(Icons.search),
            suffixIcon: artifactProvider.searchQuery.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                artifactProvider.setSearchQuery('');
              },
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            artifactProvider.setSearchQuery(value);
          },
        );
      },
    );
  }

  Widget _buildArtifactList(List<dynamic> artifacts) {
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<ArtifactProvider>(context, listen: false).fetchArtifacts(status: 'all');
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: artifacts.length,
        itemBuilder: (context, index) {
          final artifact = artifacts[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              onTap: () => _navigateToArtifactDetail(artifact),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 유물 이미지 또는 플레이스홀더
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.museum, size: 40, color: Colors.grey),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artifact['name'] ?? '이름 없음',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              if (artifact['time_period'] != null && artifact['time_period'].toString().isNotEmpty)
                                Text(
                                  artifact['time_period'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade300,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (artifact['origin_location'] != null && artifact['origin_location'].toString().isNotEmpty)
                                Text(
                                  artifact['origin_location'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade300,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (artifact['description'] != null && artifact['description'].toString().isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        artifact['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.image, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              '${artifact['image_count'] ?? 0}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.feed, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              '${artifact['feed_count'] ?? 0}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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

  // 유물 상세 페이지로 이동
  void _navigateToArtifactDetail(dynamic artifact) {
    if (artifact != null && artifact['id'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArtifactDetailScreen(artifactId: artifact['id'].toString()),
        ),
      );
    }
  }
}