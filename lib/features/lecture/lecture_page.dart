import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/handi_scaffold.dart';
import 'lecture_data.dart';

class LecturePage extends StatefulWidget {
  const LecturePage({super.key});

  @override
  State<LecturePage> createState() => _LecturePageState();
}

class _LecturePageState extends State<LecturePage> {
  List<BookEntry> _books = kLocalBooks;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final remote = await FirebaseService.instance.fetchBooks();
    setState(() {
      _books = remote.isNotEmpty ? remote : kLocalBooks;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HandiScaffold(
      title: 'Bibliothèque',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _books.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final book = _books[index];
                final lastPage = StorageService.instance.getLastPage(book.id);
                return _BookTile(
                  book: book,
                  lastPage: lastPage,
                  onTap: () => context.go('/lecture/pdf/${book.id}'),
                );
              },
            ),
    );
  }
}

class _BookTile extends StatefulWidget {
  const _BookTile({
    required this.book,
    required this.lastPage,
    required this.onTap,
  });
  final BookEntry book;
  final int lastPage;
  final VoidCallback onTap;

  @override
  State<_BookTile> createState() => _BookTileState();
}

class _BookTileState extends State<_BookTile> {
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastTap = now;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
      ),
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 72,
                decoration: BoxDecoration(
                  color: Color(widget.book.coverColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.book.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (widget.book.author.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(widget.book.author,
                          style: const TextStyle(fontSize: 16, color: HandiTheme.textSecondary)),
                    ],
                    if (widget.lastPage > 1) ...[
                      const SizedBox(height: 8),
                      Text('Reprise page ${widget.lastPage}',
                          style: const TextStyle(fontSize: 14, color: HandiTheme.accent)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 36, color: HandiTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
