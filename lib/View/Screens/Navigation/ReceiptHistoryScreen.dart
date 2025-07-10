import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/ReceiptHelper.dart';

class ReceiptHistoryScreen extends StatefulWidget {
  const ReceiptHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ReceiptHistoryScreen> createState() => _ReceiptHistoryScreenState();
}

class _ReceiptHistoryScreenState extends State<ReceiptHistoryScreen> {
  final ReceiptHelper _helper = ReceiptHelper();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  static const int _pageSize = 50;

  List<Map<String, dynamic>> _allReceipts = [];
  List<Map<String, dynamic>> _filteredReceipts = [];
  List<Map<String, dynamic>> _receipts = [];

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isFetchingMore = false;

  DateTimeRange? _dateRange;
  String _selectedType = 'All'; // All, Loan, Cash

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadReceipts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _fetchNextPage();
    }
  }

  Future<void> _loadReceipts() async {
    setState(() {
      _isLoading = true;
      _receipts.clear();
      _currentPage = 0;
      _hasMore = true;
    });

    final all = await _helper.getAllLocalReceipts();
    all.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));
    _allReceipts = all.reversed.toList();
    _applyFilters();
  }

  void _applyFilters() {
    final search = _searchController.text.trim().toLowerCase();

    _filteredReceipts = _allReceipts.where((receipt) {
      final title = (receipt['title'] ?? '').toString().toLowerCase();
      final note = (receipt['note'] ?? '').toString().toLowerCase();
      final date = DateTime.tryParse(receipt['date'] ?? '');
      

      final match = RegExp(r'\b(Loan|Cash)\b', caseSensitive: false).firstMatch(title);

      String? type = match?.group(0);

// Capitalize (just in case the match was lowercase or mixed)
      if (type != null && type.isNotEmpty) {
        type = type[0].toUpperCase() + type.substring(1).toLowerCase();
      }

      print('Type: $type');




      final matchesSearch = title.contains(search) || note.contains(search);
      final matchesDate = _dateRange == null ||
          (date != null &&
              date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
              date.isBefore(_dateRange!.end.add(const Duration(days: 1))));
      final matchesType = _selectedType == 'All' || type == _selectedType;

      return matchesSearch && matchesDate && matchesType;
    }).toList();

    _receipts.clear();
    _currentPage = 0;
    _hasMore = true;
    _fetchNextPage();
  }

  void _fetchNextPage() {
    if (_isFetchingMore || !_hasMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    final start = _currentPage * _pageSize;
    final end = (_currentPage + 1) * _pageSize;

    final nextBatch = _filteredReceipts.sublist(
      start,
      end > _filteredReceipts.length ? _filteredReceipts.length : end,
    );

    setState(() {
      _receipts.addAll(nextBatch);
      _currentPage++;
      _hasMore = end < _filteredReceipts.length;
      _isFetchingMore = false;
      _isLoading = false;
    });
  }

  String _formatDate(String iso) {
    try {
      final date = DateTime.parse(iso);
      return DateFormat('MMM dd, yyyy – hh:mm a').format(date);
    } catch (_) {
      return iso;
    }
  }

  void _showReceiptDetailDialog(Map<String, dynamic> receipt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(receipt['title'] ?? 'Receipt Detail'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Amount: ₱${(receipt['amount'] ?? 0.0).toStringAsFixed(2)}"),
            Text("Date: ${_formatDate(receipt['date'] ?? '')}"),
            if ((receipt['note'] ?? '').isNotEmpty)
              Text("Note: ${receipt['note']}"),
            Text("Type: ${receipt['type'] ?? 'N/A'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (result != null) {
      setState(() => _dateRange = result);
      _applyFilters();
    }
  }

  void _clearDateFilter() {
    setState(() => _dateRange = null);
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final showFilter = _dateRange != null;

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text('Receipt History'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
          ),
          if (showFilter)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearDateFilter,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search by title or note...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
    SizedBox(height: 10,),
          // Dropdown Filter for Type
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                  _applyFilters();
                }
              },
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Loan', child: Text('Loan')),
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
              ],
              decoration: InputDecoration(
                labelText: "Filter by Type",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                "Filtered: ${DateFormat.yMMMd().format(_dateRange!.start)} → ${DateFormat.yMMMd().format(_dateRange!.end)}",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),

          // Receipt List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _loadReceipts,
              child: _receipts.isEmpty
                  ? const Center(child: Text('No receipts found.'))
                  : ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: _receipts.length + (_hasMore ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index >= _receipts.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final receipt = _receipts[index];
                  final amount = receipt['amount'] ?? 0.0;
                  final date = _formatDate(receipt['date'] ?? '');
                  final title = receipt['title'] ?? 'Untitled';
                 

                  return ListTile(
                    onTap: () => _showReceiptDetailDialog(receipt),
                    leading: CircleAvatar(
                      backgroundColor: AppColor.primary.withOpacity(0.8),
                      child: const Icon(Icons.receipt_long, color: Colors.white),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${amount.toStringAsFixed(2)} – $date'),
                    trailing: Icon(Icons.arrow_forward_ios, color: AppColor.primary.withOpacity(0.8)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
