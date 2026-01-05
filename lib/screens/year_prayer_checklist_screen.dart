import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../services/firestore_service.dart';
import '../models/year_prayer_item.dart';

class YearPrayerChecklistScreen extends StatefulWidget {
  const YearPrayerChecklistScreen({super.key});

  @override
  State<YearPrayerChecklistScreen> createState() =>
      _YearPrayerChecklistScreenState();
}

class _YearPrayerChecklistScreenState extends State<YearPrayerChecklistScreen> {
  late int currentYear;
  late String userId;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode();
  final FirestoreService firestoreService = FirestoreService();
  bool _isAdding = false;
  YearPrayerItem? editingItem;
  bool _hasEdited = false;

  @override
  void initState() {
    super.initState();
    currentYear = DateTime.now().year;
    userId = FirebaseAuth.instance.currentUser!.uid;
    _editFocusNode.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_editFocusNode.hasFocus && editingItem != null) {
          _finishEditing(_editController.text);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _saveItem(String title, List<YearPrayerItem> items) {
    if (title.trim().isEmpty) {
      setState(() => _isAdding = false);
      return;
    }
    _addItem(title.trim(), items);
    _controller.clear();
    setState(() => _isAdding = false);
  }

  void _addItem(String title, List<YearPrayerItem> items) {
    final nextOrder = items.isEmpty
        ? 1
        : (items.map((e) => e.order).reduce((a, b) => a > b ? a : b) + 1);
    if (nextOrder > 10) return;

    final newItem = YearPrayerItem(
      userId: userId,
      year: currentYear,
      order: nextOrder,
      title: title,
      isAnswered: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    firestoreService.addYearPrayerItem(newItem);
  }

  void _toggleAnswered(YearPrayerItem item, bool value) {
    final updatedItem = item.copyWith(
      isAnswered: value,
      updatedAt: DateTime.now(),
    );
    firestoreService.updateYearPrayerItem(updatedItem);
  }

  void _deleteItem(BuildContext context, YearPrayerItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 기도제목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await firestoreService.deleteYearPrayerItem(
                  userId, currentYear, item.id!);
              await firestoreService.reorderYearPrayerItems(
                  userId, currentYear);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _finishEditing(String value) async {
    final trimmed = value.trim();
    if (editingItem != null) {
      if (trimmed.isEmpty) {
        // 빈 입력이면 삭제
        await firestoreService.deleteYearPrayerItem(
            userId, currentYear, editingItem!.id!);
        await firestoreService.reorderYearPrayerItems(userId, currentYear);
      } else if (trimmed != editingItem!.title) {
        // 변경되었으면 업데이트
        final updated = editingItem!.copyWith(
          title: trimmed,
          updatedAt: DateTime.now(),
        );
        await firestoreService.updateYearPrayerItem(updated);
      }
      // 변경 없음이면 아무것도 안 함
    }
    setState(() {
      editingItem = null;
      _editController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => currentYear--),
            ),
            Text('$currentYear년'),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => setState(() => currentYear++),
            ),
          ],
        ),
        backgroundColor: Colors.blue[100],
      ),
      body: StreamBuilder<List<YearPrayerItem>>(
        stream: firestoreService.getYearPrayerItemsStream(userId, currentYear),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('오류가 발생했습니다'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty && !_isAdding) {
            return Center(
              child: IconButton(
                iconSize: 80,
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _isAdding = true),
              ),
            );
          }

          final nextOrder = items.isEmpty
              ? 1
              : (items.map((e) => e.order).reduce((a, b) => a > b ? a : b) + 1);

          return Column(
            children: [
              if (_isAdding)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(fontSize: 30),
                    decoration: InputDecoration(
                      hintText: '$nextOrder. 기도제목을 입력하세요',
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _saveItem(value, items),
                  ),
                ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (editingItem?.id == item.id) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _editController,
                        focusNode: _editFocusNode,
                        autofocus: false,
                        style: const TextStyle(fontSize: 30),
                        decoration: InputDecoration(
                          hintText: '${item.order}. 기도제목을 입력하세요',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => _hasEdited = true,
                        onSubmitted: (value) {
                          if (!_hasEdited) return;
                          _finishEditing(value);
                        },
                      ),
                    );
                  }
                  return Slidable(
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) {
                            _hasEdited = false;
                            _editController.text = item.title;
                            setState(() => editingItem = item);
                            _editFocusNode.requestFocus();
                          },
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.edit,
                          label: '수정',
                        ),
                        SlidableAction(
                          onPressed: (context) => _deleteItem(context, item),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: '삭제',
                        ),
                      ],
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        '${item.order}. ${item.title}',
                        style: const TextStyle(fontSize: 30),
                      ),
                      value: item.isAnswered,
                      onChanged: (value) => _toggleAnswered(item, value!),
                    ),
                  );
                },
              ),
              if (items.length < 10 && !_isAdding)
                Padding(
                  padding: const EdgeInsets.only(
                      top: 10, left: 16, right: 16, bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => _isAdding = true),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
