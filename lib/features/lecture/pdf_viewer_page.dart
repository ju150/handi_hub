import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../app/theme.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/handi_scaffold.dart';
import 'lecture_data.dart';

class PdfViewerPage extends StatefulWidget {
  const PdfViewerPage({super.key, required this.bookId});
  final String bookId;

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late final PdfViewerController _controller;
  BookEntry? _book;
  int _totalPages = 0;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    _book = kLocalBooks.firstWhere(
      (b) => b.id == widget.bookId,
      orElse: () => BookEntry(id: widget.bookId, title: widget.bookId),
    );
    _currentPage = StorageService.instance.getLastPage(widget.bookId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    final page = details.newPageNumber;
    setState(() => _currentPage = page);
    StorageService.instance.saveLastPage(widget.bookId, page);
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    return HandiScaffold(
      title: book?.title ?? 'Lecture',
      actions: [
        if (_totalPages > 0)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$_currentPage / $_totalPages',
                style: const TextStyle(fontSize: 18, color: HandiTheme.onPrimary),
              ),
            ),
          ),
      ],
      body: Column(
        children: [
          Expanded(
            child: book == null
                ? const Center(child: Text('Livre introuvable'))
                : book.isLocal
                    ? SfPdfViewer.asset(
                        book.localAssetPath,
                        controller: _controller,
                        initialPageNumber: _currentPage,
                        onPageChanged: _onPageChanged,
                        onDocumentLoaded: (details) {
                          setState(() => _totalPages = details.document.pages.count);
                          if (_currentPage > 1) {
                            _controller.jumpToPage(_currentPage);
                          }
                        },
                      )
                    : SfPdfViewer.network(
                        book.pdfUrl!,
                        controller: _controller,
                        initialPageNumber: _currentPage,
                        onPageChanged: _onPageChanged,
                        onDocumentLoaded: (details) {
                          setState(() => _totalPages = details.document.pages.count);
                        },
                      ),
          ),
          _NavBar(
            controller: _controller,
            currentPage: _currentPage,
            totalPages: _totalPages,
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.controller, required this.currentPage, required this.totalPages});
  final PdfViewerController controller;
  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavButton(
            icon: Icons.arrow_back_ios,
            label: 'Précédent',
            enabled: currentPage > 1,
            onTap: controller.previousPage,
          ),
          _NavButton(
            icon: Icons.arrow_forward_ios,
            label: 'Suivant',
            enabled: totalPages == 0 || currentPage < totalPages,
            onTap: controller.nextPage,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  const _NavButton({required this.icon, required this.label, required this.enabled, required this.onTap});
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  DateTime? _lastTap;

  void _handleTap() {
    if (!widget.enabled) return;
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) < const Duration(milliseconds: 800)) return;
    _lastTap = now;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: widget.enabled ? _handleTap : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size(160, HandiTheme.buttonHeight),
        backgroundColor: widget.enabled ? HandiTheme.primary : Colors.grey,
      ),
      icon: Icon(widget.icon),
      label: Text(widget.label),
    );
  }
}
