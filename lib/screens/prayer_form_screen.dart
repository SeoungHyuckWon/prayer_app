import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/prayer.dart';
import '../services/firestore_service.dart';

class PrayerFormScreen extends StatefulWidget {
  final Prayer? prayer;

  const PrayerFormScreen({super.key, this.prayer});

  @override
  State<PrayerFormScreen> createState() => _PrayerFormScreenState();
}

class _PrayerFormScreenState extends State<PrayerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _firestoreService = FirestoreService();
  PrayerStatus _selectedStatus = PrayerStatus.ongoing;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.prayer != null) {
      _titleController.text = widget.prayer!.title;
      _contentController.text = widget.prayer!.content;
      _selectedStatus = widget.prayer!.status;
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

  Future<void> _savePrayer() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('기도제목 저장: 폼 검증 실패');
      return;
    }

    debugPrint('기도제목 저장: 시작');
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();

      if (widget.prayer != null) {
        // 수정
        debugPrint('기도제목 저장: 수정 모드');
        final updatedPrayer = widget.prayer!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          status: _selectedStatus,
          updatedAt: now,
          answeredAt: _selectedStatus == PrayerStatus.answered &&
                  widget.prayer!.answeredAt == null
              ? now
              : widget.prayer!.answeredAt,
        );
        debugPrint('기도제목 저장: Firestore 업데이트 시작');
        await _firestoreService.updatePrayer(updatedPrayer);
        debugPrint('기도제목 저장: Firestore 업데이트 완료');

        // update()가 예외 없이 완료되면 성공
        if (context.mounted) {
          debugPrint('기도제목 저장: 화면 닫기 (성공)');
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
        debugPrint('기도제목 저장: 새로 작성 모드');
        final userId = FirebaseAuth.instance.currentUser?.uid;
        debugPrint('기도제목 저장: userId = $userId');
        if (userId == null) {
          throw Exception('사용자가 로그인되어 있지 않습니다');
        }

        final newPrayer = Prayer(
          userId: userId,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          status: _selectedStatus,
          createdAt: now,
          updatedAt: now,
          answeredAt: _selectedStatus == PrayerStatus.answered ? now : null,
        );
        debugPrint('기도제목 저장: Firestore 추가 시작');
        final docId = await _firestoreService.addPrayer(newPrayer);
        debugPrint('기도제목 저장: Firestore 추가 완료 - 문서 ID: $docId');

        // 저장 성공 확인: Document ID가 반환되면 성공
        if (docId.isNotEmpty) {
          if (context.mounted) {
            debugPrint('기도제목 저장: 화면 닫기 (성공)');
            Navigator.of(context).pop(true); // true는 저장 성공을 의미
          }
        } else {
          throw Exception('저장은 완료되었지만 Document ID를 받지 못했습니다');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('기도제목 저장: 에러 발생 - $e');
      debugPrint('기도제목 저장: 스택 트레이스 - $stackTrace');
      if (context.mounted) {
        // 에러 발생 시 false 반환하여 실패 메시지 표시
        Navigator.of(context).pop(false);
      }
    } finally {
      debugPrint('기도제목 저장: finally 블록 실행');
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
        title: Text(widget.prayer != null
            ? (_isEditMode ? '기도제목 수정' : '기도제목 보기')
            : '기도제목 작성'),
        backgroundColor: Colors.blue[100],
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
                  _savePrayer();
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
                hintText: '기도제목을 입력하세요',
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
                hintText: '기도제목의 내용을 자세히 작성해주세요',
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
            const SizedBox(height: 16),
            const Text(
              '상태',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PrayerStatus.values.map((status) {
                return ChoiceChip(
                  label: Text(status.displayName),
                  selected: _selectedStatus == status,
                  onSelected: _isEditMode
                      ? (selected) {
                          if (selected) {
                            setState(() {
                              _selectedStatus = status;
                            });
                          }
                        }
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
