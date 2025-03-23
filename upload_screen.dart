import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' show basename;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../providers/feed_provider.dart';
import '../../screens/main/main_tab.dart';

class UploadScreenPage extends StatefulWidget {
  const UploadScreenPage({Key? key}) : super(key: key);

  @override
  _UploadScreenPageState createState() => _UploadScreenPageState();
}

class _UploadScreenPageState extends State<UploadScreenPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _artifactNameController = TextEditingController();
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String _uploadStatus = '';
  double _uploadProgress = 0.0;
  List<File> _tempFiles = []; // 임시 파일 관리용

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _artifactNameController.dispose();
    _cleanupTempFiles();
    super.dispose();
  }

  // 임시 파일 정리
  Future<void> _cleanupTempFiles() async {
    for (var file in _tempFiles) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('임시 파일 삭제 중 오류 발생: $e');
      }
    }
  }

  // 이미지 압축 함수
  Future<File> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final path = tempDir.path;
      final fileName = basename(file.path);
      final compressedFile = File('$path/compressed_$fileName');

      // 이미지 압축
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        compressedFile.absolute.path,
        quality: 70, // 품질 조정 (0-100)
        minWidth: 1024, // 최대 너비
        minHeight: 1024, // 최대 높이
      );

      if (result != null) {
        final compressedPath = File(result.path);
        _tempFiles.add(compressedPath); // 임시 파일 목록에 추가
        return compressedPath;
      }
      return file;
    } catch (e) {
      print('이미지 압축 중 오류 발생: $e');
      return file;
    }
  }

  // 이미지 선택 함수
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var pickedFile in pickedFiles) {
            _selectedImages.add(File(pickedFile.path));
          }
        });
      }
    } catch (e) {
      print('이미지 선택 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // 카메라로 사진 촬영
  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
        });
      }
    } catch (e) {
      print('사진 촬영 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 촬영 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // 선택한 이미지 제거
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // 폼 제출 및 피드 업로드 (개선된 함수)
  Future<void> _submitForm() async {
    print("디버그[1]: 폼 제출 시작");
    if (!_formKey.currentState!.validate()) {
      print("디버그[2]: 폼 유효성 검사 실패");
      return;
    }

    // 이미지가 없는 경우 경고
    if (_selectedImages.isEmpty) {
      print("디버그[3]: 이미지 없음");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 한 장 이상의 이미지를 업로드해 주세요')),
      );
      return;
    }

    print("디버그[4]: 로딩 상태로 변경 전");
    // 이전 상태에서 UI가 멈추는 것을 방지하기 위해 microtask 사용
    await Future.microtask(() {
      if (mounted) {
        setState(() {
          _isUploading = true;
          _uploadStatus = '이미지 압축 준비 중...';
          _uploadProgress = 0.0;
        });
      }
    });

    print("디버그[5]: 로딩 상태로 변경 후");
    // 약간의 시간 차를 두어 UI 업데이트가 적용되도록 함
    await Future.delayed(Duration(milliseconds: 100));

    try {
      print("디버그[6]: 이미지 압축 시작");
      // 먼저 이미지 압축 처리
      List<File> compressedImages = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        if (!mounted) {
          print("디버그[7-${i}]: 위젯 dispose됨");
          return;
        }

        setState(() {
          _uploadStatus = '이미지 압축 중 (${i+1}/${_selectedImages.length})...';
          _uploadProgress = (i + 1) / _selectedImages.length * 0.5;
        });

        print("디버그[8-${i}]: 이미지 압축 시작 - ${_selectedImages[i].path}");
        final compressedImage = await _compressImage(_selectedImages[i]);
        print("디버그[9-${i}]: 이미지 압축 완료 - ${compressedImage.path}");
        compressedImages.add(compressedImage);

        await Future.delayed(Duration(milliseconds: 50));
      }

      if (!mounted) {
        print("디버그[10]: 위젯 dispose됨");
        return;
      }

      print("디버그[11]: 모든 이미지 압축 완료, 피드 업로드 시작");
      setState(() {
        _uploadStatus = '피드 업로드 중...';
      });

      final feedProvider = Provider.of<FeedProvider>(context, listen: false);

      print("디버그[12]: feedProvider.createFeed 호출 전");
      // 피드 생성 함수 호출
      final success = await feedProvider.createFeed(
        title: _titleController.text,
        content: _contentController.text,
        artifactName: _artifactNameController.text,
        images: compressedImages,
        onProgress: (progress) {
          if (mounted) {
            print("디버그[13]: 업로드 진행률 - ${(progress * 100).toInt()}%");
            setState(() {
              _uploadProgress = 0.5 + (progress * 0.5);
              _uploadStatus = '이미지 업로드 중 (${(progress * 100).toInt()}%)...';
            });
          }
        },
      );
      print("디버그[14]: feedProvider.createFeed 호출 후, 결과: $success");

      if (!mounted) {
        print("디버그[15]: 위젯 dispose됨");
        return;
      }

      if (success) {
        print("디버그[16]: 업로드 성공, 메시지 표시");
        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('피드가 성공적으로 업로드되었습니다')),
        );

        print("디버그[17]: 딜레이 시작");
        // UI 업데이트를 위한 딜레이 추가 - 검은 화면 방지를 위해 중요
        await Future.delayed(Duration(milliseconds: 300));
        print("디버그[18]: 딜레이 종료");

        if (mounted) {
          print("디버그[19]: 상태 초기화 전");
          // 상태 초기화
          setState(() {
            _isUploading = false;
            _uploadStatus = '';
            _uploadProgress = 0.0;
          });

          print("디버그[20]: 상태 초기화 후, 네비게이션 전");

          // 네비게이션 방식 변경 - 애니메이션 없이 전환
          Future.delayed(Duration(milliseconds: 100), () {
            if (mounted) {
              print("디버그[21]: 네비게이션 실행 전");
              // 이전 화면으로 명시적인 이동
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) => MainTabPage(), // 메인 탭 페이지로 이동
                  transitionDuration: Duration.zero, // 애니메이션 없음
                ),
              );
              print("디버그[22]: 네비게이션 실행 후");
            }
          });
        }
      } else {
        print("디버그[23]: 업로드 실패");
        // 실패 메시지
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('업로드 실패: ${feedProvider.error}')),
          );

          setState(() {
            _isUploading = false;
            _uploadStatus = '';
            _uploadProgress = 0.0;
          });
        }
      }
    } catch (e) {
      print("디버그[24]: 오류 발생 - $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업로드 중 오류 발생: $e')),
        );

        setState(() {
          _isUploading = false;
          _uploadStatus = '';
          _uploadProgress = 0.0;
        });
      }
    }
    print("디버그[25]: _submitForm 함수 종료");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return !_isUploading;
      },
      child: Scaffold(
        body: Column(
          children: [
            // ✅ 상단 고정 이미지 (앱바처럼)
            Image.asset(
              'assets/images/eaves.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            // ✅ 스크롤 가능한 콘텐츠
            Expanded(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: _isUploading
                    ? Center(
                  key: ValueKey('loading'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _uploadProgress > 0 ? _uploadProgress : null,
                      ),
                      SizedBox(height: 16),
                      Text(_uploadStatus),
                      SizedBox(height: 8),
                      Text('${(_uploadProgress * 100).toInt()}%'),
                    ],
                  ),
                )
                    : SingleChildScrollView(
                  key: ValueKey('form'),
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이미지 미리보기 영역
                        if (_selectedImages.isNotEmpty) ...[
                          const Text(
                            '선택한 이미지',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (ctx, index) {
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: FileImage(_selectedImages[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 5,
                                      right: 13,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 이미지 추가 버튼
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.photo_library, color: Colors.black,),
                              label: const Text('갤러리에서 선택'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black, // ✅ 텍스트 색상 (자동 적용)
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12), // ✅ 버튼 모서리 둥글기 조정 (12 정도 추천)
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _takePicture,
                              icon: const Icon(Icons.camera_alt, color: Colors.black),
                              label: const Text('카메라로 촬영'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black, // ✅ 텍스트 색상 (자동 적용)
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12), // ✅ 버튼 모서리 둥글기 조정 (12 정도 추천)
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 유물 이름 입력 필드
                        TextFormField(
                          controller: _artifactNameController,
                          decoration: const InputDecoration(
                            labelText: '유물 이름',
                            hintText: '사진 속 유물의 이름을 입력하세요',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '유물 이름을 입력해 주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 제목 입력 필드
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: '제목',
                            hintText: '피드 제목을 입력하세요',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '제목을 입력해 주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 내용 입력 필드
                        TextFormField(
                          controller: _contentController,
                          decoration: const InputDecoration(
                            labelText: '내용',
                            hintText: '피드 내용을 입력하세요',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '내용을 입력해 주세요';
                            }
                            return null;
                          },
                          minLines: 3,
                          maxLines: 10,
                        ),
                        const SizedBox(height: 24),

                        // 제출 버튼
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isUploading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black, // ✅ 텍스트 색상 (자동 적용)
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12), // ✅ 버튼 모서리 둥글기 조정 (12 정도 추천)
                              ),
                            ),
                            child: const Text(
                              '등록',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      ),
    );
  }

}