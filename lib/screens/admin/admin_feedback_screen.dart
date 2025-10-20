import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/feedback.dart' as app_models;
import '../../theme/app_theme.dart';
import '../../widgets/custom_card.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadFeedbacks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  List<app_models.Feedback> _getFilteredFeedbacks(List<app_models.Feedback> feedbacks) {
    var filtered = feedbacks;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((feedback) =>
          (feedback.userEmail?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (feedback.message?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    // Filter by status
    switch (_selectedFilter) {
      case 'pending':
        filtered = filtered.where((feedback) => !feedback.isRead).toList();
        break;
      case 'read':
        filtered = filtered.where((feedback) => feedback.isRead).toList();
        break;
      case 'all':
      default:
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý phản hồi'),
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm phản hồi...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: const InputDecoration(
                          labelText: 'Lọc theo trạng thái',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'pending', child: Text('Chưa đọc')),
                          DropdownMenuItem(value: 'read', child: Text('Đã đọc')),
                        ],
                        onChanged: (value) => _onFilterChanged(value ?? 'all'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Feedback List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final feedbacks = _getFilteredFeedbacks(chatProvider.feedbacks);

                if (feedbacks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'Chưa có phản hồi nào'
                              : 'Không tìm thấy phản hồi',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    final feedback = feedbacks[index];
                    return CustomCard(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  feedback.userEmail ?? 'N/A',
                                  style: AppTheme.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  if (!feedback.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(feedback.timestamp ?? DateTime.now()),
                                    style: AppTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            feedback.message ?? feedback.content ?? 'N/A',
                            style: AppTheme.bodyMedium,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: feedback.isRead ? AppTheme.successColor : AppTheme.warningColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  feedback.isRead ? 'Đã đọc' : 'Chưa đọc',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  if (!feedback.isRead)
                                    TextButton(
                                      onPressed: () => _markAsRead(feedback),
                                      child: const Text('Đánh dấu đã đọc'),
                                    ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.reply, color: AppTheme.primaryColor),
                                    onPressed: () => _replyToFeedback(feedback),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _markAsRead(app_models.Feedback feedback) {
    // TODO: Implement mark as read
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đánh dấu là đã đọc')),
    );
  }

  void _replyToFeedback(app_models.Feedback feedback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Phản hồi từ ${feedback.userEmail ?? 'N/A'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nội dung:',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(feedback.message ?? feedback.content ?? 'N/A'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Trả lời',
                border: OutlineInputBorder(),
                hintText: 'Nhập phản hồi...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gửi phản hồi')),
              );
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
