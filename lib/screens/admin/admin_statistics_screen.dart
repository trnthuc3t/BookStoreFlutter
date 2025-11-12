import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/statistics.dart';
import '../../services/api_service.dart';
import '../../widgets/sortable_data_table.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({Key? key}) : super(key: key);

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _period = 'day';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Thống kê chi tiết',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.grey.shade900,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue.shade400,
              indicatorWeight: 3,
              labelColor: Colors.blue.shade400,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 15,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.monetization_on_outlined, size: 20),
                  text: 'Doanh thu',
                ),
                Tab(
                  icon: Icon(Icons.book_outlined, size: 20),
                  text: 'Sách',
                ),
                Tab(
                  icon: Icon(Icons.category_outlined, size: 20),
                  text: 'Thể loại',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RevenueStatisticsTab(
                  period: _period,
                  startDate: _formatDate(_startDate),
                  endDate: _formatDate(_endDate),
                ),
                BookStatisticsTab(
                  period: _period,
                  startDate: _formatDate(_startDate),
                  endDate: _formatDate(_endDate),
                ),
                CategoryStatisticsTab(
                  period: _period,
                  startDate: _formatDate(_startDate),
                  endDate: _formatDate(_endDate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list, size: 20, color: Colors.blue.shade400),
              const SizedBox(width: 8),
              const Text(
                'Xem theo:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade700),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _period,
                icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade400),
                dropdownColor: Colors.grey.shade800,
                style: TextStyle(
                  color: Colors.blue.shade300,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'day',
                    child: Text('Ngày', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'month',
                    child: Text('Tháng', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'year',
                    child: Text('Năm', style: TextStyle(color: Colors.white)),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _period = value;
                    });
                  }
                },
              ),
            ),
          ),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(minWidth: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _startDate != null && _endDate != null
                          ? 'Từ ${_formatDate(_startDate)} đến ${_formatDate(_endDate)}'
                          : 'Chọn khoảng thời gian',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.date_range, size: 18),
            label: const Text(
              'Chọn ngày',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            onPressed: _selectDateRange,
          ),
        ],
      ),
    );
  }
}

// Revenue Statistics Tab
class RevenueStatisticsTab extends StatefulWidget {
  final String period;
  final String? startDate;
  final String? endDate;

  const RevenueStatisticsTab({
    Key? key,
    required this.period,
    this.startDate,
    this.endDate,
  }) : super(key: key);

  @override
  State<RevenueStatisticsTab> createState() => _RevenueStatisticsTabState();
}

class _RevenueStatisticsTabState extends State<RevenueStatisticsTab> {
  bool _isLoading = false;
  RevenueStatistic? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(RevenueStatisticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getRevenueStatistics(
        period: widget.period,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

      if (response != null) {
        print('📊 Revenue response data: $response');
        setState(() {
          _data = RevenueStatistic.fromJson(response);
          print('📊 Revenue data parsed: totalOrders=${_data!.totalOrders}, totalRevenue=${_data!.totalRevenue}');
          _isLoading = false;
        });
      } else {
        print('⚠️ Revenue response is null');
        setState(() {
          _error = 'Không thể tải dữ liệu';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_data == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Không có dữ liệu\nVui lòng kiểm tra kết nối và thử lại',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Check if all values are zero
    final hasData = _data!.totalOrders > 0 || 
                    _data!.totalBooksSold > 0 || 
                    _data!.totalRevenue > 0 || 
                    _data!.totalProfit > 0;

    final tableData = [
      {
        'label': 'Số đơn bán ra',
        'value': _data!.totalOrders,
      },
      {
        'label': 'Số sách bán ra',
        'value': _data!.totalBooksSold,
      },
      {
        'label': 'Doanh thu trước khuyến mãi',
        'value': _data!.totalRevenueBeforeDiscount,
      },
      {
        'label': 'Tổng giảm giá (voucher)',
        'value': _data!.totalDiscount,
      },
      {
        'label': 'Doanh thu sau khuyến mãi',
        'value': _data!.totalRevenue,
      },
      {
        'label': 'Lợi nhuận trước khuyến mãi',
        'value': _data!.totalProfit,
      },
      {
        'label': 'Lợi nhuận sau khuyến mãi',
        'value': _data!.totalProfitAfterDiscount,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF424242), Color(0xFF212121)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade700),
            ),
            child: Row(
              children: [
                Icon(Icons.assessment, color: Colors.blue.shade400, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thống kê từ ${_data!.startDate} đến ${_data!.endDate}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!hasData)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade900.withOpacity(0.2),
                border: Border.all(color: Colors.orange.shade700, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade400, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Không có đơn hàng nào đã thanh toán trong khoảng thời gian này',
                      style: TextStyle(
                        color: Colors.orange.shade300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF212121),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade800),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SortableDataTable(
                columns: [
                  DataColumnConfig(
                    key: 'label',
                    label: 'Chỉ số',
                    width: 200,
                  ),
                  DataColumnConfig(
                    key: 'value',
                    label: 'Giá trị',
                    numeric: true,
                    formatter: (value) {
                      if (value is num) {
                        return NumberFormat('#,##0').format(value);
                      }
                      return value.toString();
                    },
                  ),
                ],
                data: tableData,
                allowReorder: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Book Statistics Tab
class BookStatisticsTab extends StatefulWidget {
  final String period;
  final String? startDate;
  final String? endDate;

  const BookStatisticsTab({
    Key? key,
    required this.period,
    this.startDate,
    this.endDate,
  }) : super(key: key);

  @override
  State<BookStatisticsTab> createState() => _BookStatisticsTabState();
}

class _BookStatisticsTabState extends State<BookStatisticsTab> {
  bool _isLoading = false;
  BookStatisticResponse? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(BookStatisticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getBookStatistics(
        period: widget.period,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

      if (response != null) {
        print('📊 Book response data: $response');
        setState(() {
          _data = BookStatisticResponse.fromJson(response);
          print('📊 Book data parsed: ${_data!.books.length} books');
          _isLoading = false;
        });
      } else {
        print('⚠️ Book response is null');
        setState(() {
          _error = 'Không thể tải dữ liệu';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_data == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Không có dữ liệu\nVui lòng kiểm tra kết nối và thử lại',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_data!.books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Không có sách nào được bán',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Trong khoảng thời gian từ ${_data!.startDate} đến ${_data!.endDate}',
                style: TextStyle(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final tableData = _data!.books.map((book) {
      return {
        'book_name': book.bookName,
        'category': book.category,
        'sold_quantity': book.soldQuantity,
        'revenue': book.revenue,
        'profit': book.profit,
        'stock_remaining': book.stockRemaining,
      };
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê từ ${_data!.startDate} đến ${_data!.endDate}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tổng số sách: ${_data!.books.length}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SortableDataTable(
            columns: [
              DataColumnConfig(key: 'book_name', label: 'Tên sách', width: 250),
              DataColumnConfig(key: 'category', label: 'Thể loại', width: 120),
              DataColumnConfig(
                key: 'sold_quantity',
                label: 'Đã bán',
                numeric: true,
                formatter: (value) => NumberFormat('#,##0').format(value),
              ),
              DataColumnConfig(
                key: 'revenue',
                label: 'Doanh thu',
                numeric: true,
                formatter: (value) => NumberFormat('#,##0đ').format(value),
              ),
              DataColumnConfig(
                key: 'profit',
                label: 'Lợi nhuận',
                numeric: true,
                formatter: (value) => NumberFormat('#,##0đ').format(value),
              ),
              DataColumnConfig(
                key: 'stock_remaining',
                label: 'Còn tồn',
                numeric: true,
                formatter: (value) => NumberFormat('#,##0').format(value),
              ),
            ],
            data: tableData,
          ),
        ],
      ),
    );
  }
}

// Category Statistics Tab
class CategoryStatisticsTab extends StatefulWidget {
  final String period;
  final String? startDate;
  final String? endDate;

  const CategoryStatisticsTab({
    Key? key,
    required this.period,
    this.startDate,
    this.endDate,
  }) : super(key: key);

  @override
  State<CategoryStatisticsTab> createState() => _CategoryStatisticsTabState();
}

class _CategoryStatisticsTabState extends State<CategoryStatisticsTab> {
  bool _isLoading = false;
  CategoryStatisticResponse? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(CategoryStatisticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getCategoryStatistics(
        period: widget.period,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

      if (response != null) {
        print('📊 Category response data: $response');
        setState(() {
          _data = CategoryStatisticResponse.fromJson(response);
          print('📊 Category data parsed: ${_data!.categories.length} categories');
          _isLoading = false;
        });
      } else {
        print('⚠️ Category response is null');
        setState(() {
          _error = 'Không thể tải dữ liệu';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_data == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Không có dữ liệu\nVui lòng kiểm tra kết nối và thử lại',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_data!.categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Không có thể loại nào có doanh số',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Trong khoảng thời gian từ ${_data!.startDate} đến ${_data!.endDate}',
                style: TextStyle(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Flatten category data to show books
    final tableData = <Map<String, dynamic>>[];
    for (var category in _data!.categories) {
      for (var book in category.books) {
        tableData.add({
          'category_name': category.categoryName,
          'book_name': book.bookName,
          'sold_quantity': book.soldQuantity,
          'profit': book.profit,
          'stock_remaining': book.stockRemaining,
        });
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê từ ${_data!.startDate} đến ${_data!.endDate}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tổng số thể loại: ${_data!.categories.length}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SortableDataTable(
            columns: [
              DataColumnConfig(key: 'category_name', label: 'Thể loại', width: 150),
              DataColumnConfig(key: 'book_name', label: 'Tên sách', width: 250),
              DataColumnConfig(
                key: 'sold_quantity',
                label: 'Đã bán',
                numeric: true,
                formatter: (value) => NumberFormat('#,##0').format(value),
              ),
              DataColumnConfig(
                key: 'profit',
                label: 'Lợi nhuận',
                numeric: true,
                formatter: (value) => NumberFormat('#,##0đ').format(value),
              ),
              DataColumnConfig(
                key: 'stock_remaining',
                label: 'Còn tồn',
                numeric: true,
                formatter: (value) => NumberFormat('#,##0').format(value),
              ),
            ],
            data: tableData,
          ),
        ],
      ),
    );
  }
}
