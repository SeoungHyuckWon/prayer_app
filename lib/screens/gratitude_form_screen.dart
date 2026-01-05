import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/gratitude.dart';
import '../services/firestore_service.dart';

class GratitudeFormScreen extends StatefulWidget {
  final Gratitude? gratitude;

  const GratitudeFormScreen({super.key, this.gratitude});

  @override
  State<GratitudeFormScreen> createState() => _GratitudeFormScreenState();
}

class _GratitudeFormScreenState extends State<GratitudeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.gratitude != null) {
      _titleController.text = widget.gratitude!.title;
      _contentController.text = widget.gratitude!.content;
      _isEditMode = false; // 수정 모드지만 초기에는 수정 불가능
    } else {
      _isEditMode = true; // 새로 작성 시 바로 수정 가능
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveGratitude() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('감사 저장: 폼 검증 실패');
      return;
    }

    debugPrint('감사 저장: 시작');
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();

      if (widget.gratitude != null) {
        // 수정
        debugPrint('감사 저장: 수정 모드');
        final updatedGratitude = widget.gratitude!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          updatedAt: now,
        );
        debugPrint('감사 저장: Firestore 업데이트 시작');
        await _firestoreService.updateGratitude(updatedGratitude);
        debugPrint('감사 저장: Firestore 업데이트 완료');

        // update()가 예외 없이 완료되면 성공
        if (context.mounted) {
          debugPrint('감사 저장: 화면 닫기 (성공)');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('수정이 완료되었습니다'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop(true); // true는 수정 성공을 의미
        }
      } else {
        // 새로 작성
        debugPrint('감사 저장: 새로 작성 모드');
        final newGratitude = Gratitude(
          userId: FirebaseAuth.instance.currentUser!.uid,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        debugPrint('감사 저장: Firestore 추가 시작');
        final docId = await _firestoreService.addGratitude(newGratitude);
        debugPrint('감사 저장: Firestore 추가 완료 - 문서 ID: $docId');

        // 저장 성공 확인: Document ID가 반환되면 성공
        if (docId.isNotEmpty) {
          if (context.mounted) {
            debugPrint('감사 저장: 화면 닫기 (성공)');
            Navigator.of(context).pop(true); // true는 저장 성공을 의미
          }
        } else {
          throw Exception('저장은 완료되었지만 Document ID를 받지 못했습니다');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('감사 저장: 에러 발생 - $e');
      debugPrint('감사 저장: 스택 트레이스 - $stackTrace');
      if (context.mounted) {
        // 에러 발생 시 false 반환하여 실패 메시지 표시
        Navigator.of(context).pop(false);
      }
    } finally {
      debugPrint('감사 저장: finally 블록 실행');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gratitude != null
            ? (_isEditMode ? '감사 수정' : '감사 보기')
            : '감사 작성'),
        backgroundColor: Colors.purple[100],
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: () {
                if (_isEditMode) {
                  _saveGratitude();
                } else {
                  setState(() {
                    _isEditMode = true;
                  });
                }
              },
              child: Text(
                _isEditMode ? '저장' : '수정',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              enabled: _isEditMode,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '감사의 제목을 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '제목을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              enabled: _isEditMode,
              decoration: const InputDecoration(
                labelText: '내용',
                hintText: '감사한 내용을 자세히 작성해주세요',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              maxLength: 500,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '내용을 입력해주세요';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
