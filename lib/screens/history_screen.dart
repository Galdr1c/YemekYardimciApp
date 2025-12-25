import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/food_analysis.dart';
import '../providers/analysis_provider.dart';
import '../providers/profile_provider.dart';
import '../services/nutrition_report_service.dart';
import '../widgets/nutrition_chart.dart';
import '../utils/helpers.dart';
import 'analysis_detail_screen.dart';

/// Screen displaying food analysis history with delete functionality
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NutritionReportService _reportService = NutritionReportService();
  Map<String, int> _weeklyCalories = {};
  String _suggestion = '';
  bool _isLoadingReport = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load history on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisProvider>().loadHistory();
      _loadReport();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoadingReport = true);
    
    try {
      final weeklyCalories = await _reportService.getWeeklyCalories();
      final profileProvider = context.read<ProfileProvider>();
      final goal = profileProvider.dailyCalorieGoal;
      
      // Get today's calories
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayCalories = weeklyCalories[today] ?? 0;
      
      // Get suggestion
      final suggestion = await _reportService.getSuggestion(todayCalories, goal);
      
      if (mounted) {
        setState(() {
          _weeklyCalories = weeklyCalories;
          _suggestion = suggestion;
          _isLoadingReport = false;
        });
      }
    } catch (e) {
      print('[HistoryScreen] Error loading report: $e');
      if (mounted) {
        setState(() => _isLoadingReport = false);
      }
    }
  }

  Future<void> _exportCSV() async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 6));
      final endDate = now;
      
      final csv = await _reportService.exportToCSV(
        startDate: startDate,
        endDate: endDate,
      );
      
      await Share.share(
        csv,
        subject: 'Beslenme Raporu',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(FoodAnalysis analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: Text('"${analysis.foodName}" kaydı silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAnalysis(analysis);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnalysis(FoodAnalysis analysis) async {
    if (analysis.id != null) {
      final provider = context.read<AnalysisProvider>();
      final foodName = analysis.foodName;
      
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text('"$foodName" siliniyor...'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
      
      // Delete analysis
      await provider.deleteAnalysis(analysis.id!);
      
      // Refresh history and today's data
      await provider.loadHistory();
      await provider.loadTodayData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('"$foodName" silindi'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Geri Al',
              textColor: Colors.white,
              onPressed: () async {
                // Note: Undo would require storing the deleted analysis
                // For now, just show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.info, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text('Geri alma özelliği yakında eklenecek'),
                      ],
                    ),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  void _confirmClearHistory() {
    final provider = context.read<AnalysisProvider>();
    final count = provider.history.length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Geçmişi Temizle'),
          ],
        ),
        content: Text(
          '$count analiz kaydı silinsin mi?\nBu işlem geri alınamaz.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('$count kayıt siliniyor...'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 1),
                ),
              );
              
              // Clear history
              await provider.clearHistory();
              
              // Refresh history and today's data
              await provider.loadHistory();
              await provider.loadTodayData();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.delete_sweep, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Text('$count kayıt silindi'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_sweep, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            label: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Geçmiş',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              text: 'Geçmiş',
              icon: Icon(Icons.history),
            ),
            Tab(
              text: 'Raporlar',
              icon: Icon(Icons.bar_chart),
            ),
          ],
        ),
        actions: [
          Consumer<AnalysisProvider>(
            builder: (context, provider, child) {
              if (provider.history.isEmpty || _tabController.index != 0) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: _confirmClearHistory,
                tooltip: 'Geçmişi Temizle',
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<AnalysisProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (provider.history.isEmpty) {
            return const _EmptyHistoryState();
          }

          // Group analyses by date
          final groupedHistory = _groupByDate(provider.history);

          return RefreshIndicator(
            onRefresh: () => provider.loadHistory(),
            color: Colors.green,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: groupedHistory.length,
              itemBuilder: (context, index) {
                final dateKey = groupedHistory.keys.elementAt(index);
                final analyses = groupedHistory[dateKey]!;
                final totalCalories = analyses.fold<int>(
                  0,
                  (sum, a) => sum + a.estimatedCalories,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header with total calories
                    _DateHeader(
                      date: dateKey,
                      totalCalories: totalCalories,
                      itemCount: analyses.length,
                    ),
                    // Analysis items for this date
                    ...analyses.map((analysis) => _HistoryItemCard(
                          analysis: analysis,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnalysisDetailScreen(
                                  imagePath: analysis.imagePath,
                                  analyses: [analysis],
                                ),
                              ),
                            );
                          },
                          onDelete: () => _confirmDelete(analysis),
                        )),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          );
        },
      );
  }

  Widget _buildReportsTab() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        return RefreshIndicator(
          onRefresh: _loadReport,
          color: Colors.green,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekly chart
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Haftalık Kalori Takibi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.file_download),
                              onPressed: _exportCSV,
                              tooltip: 'CSV Olarak Dışa Aktar',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingReport)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else
                          NutritionChart(
                            dailyCalories: _weeklyCalories,
                            goal: profileProvider.dailyCalorieGoal,
                            isWeekly: true,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Suggestion card
                if (_suggestion.isNotEmpty)
                  Card(
                    elevation: 2,
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _suggestion,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Summary card
                if (profileProvider.hasProfile)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Özet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'Günlük Hedef',
                            '${profileProvider.dailyCalorieGoal} kcal',
                            Colors.green,
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Bugün',
                            '${_weeklyCalories[DateFormat('yyyy-MM-dd').format(DateTime.now())] ?? 0} kcal',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Group analyses by date
  Map<String, List<FoodAnalysis>> _groupByDate(List<FoodAnalysis> analyses) {
    final grouped = <String, List<FoodAnalysis>>{};
    for (final analysis in analyses) {
      final dateKey = DateTimeHelper.formatDate(analysis.analyzedAt);
      grouped.putIfAbsent(dateKey, () => []).add(analysis);
    }
    return grouped;
  }
}

/// Date header showing date, item count, and total calories
class _DateHeader extends StatelessWidget {
  final String date;
  final int totalCalories;
  final int itemCount;

  const _DateHeader({
    required this.date,
    required this.totalCalories,
    required this.itemCount,
  });

  String get _displayDate {
    final today = DateTimeHelper.formatDate(DateTime.now());
    final yesterday = DateTimeHelper.formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    if (date == today) return 'Bugün';
    if (date == yesterday) return 'Dün';
    return date;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                _displayDate,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$itemCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '$totalCalories kcal',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// History item card showing analysis details
class _HistoryItemCard extends StatelessWidget {
  final FoodAnalysis analysis;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryItemCard({
    required this.analysis,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: _buildThumbnail(),
                ),
              ),
              const SizedBox(width: 12),
              
              // Analysis info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            analysis.foodName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _ConfidenceBadge(confidence: analysis.confidence),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.scale,
                          value: '${analysis.estimatedGrams.toStringAsFixed(0)}g',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.local_fire_department,
                          value: '${analysis.estimatedCalories} kcal',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateTimeHelper.formatTime(analysis.analyzedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                onPressed: onDelete,
                tooltip: 'Sil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (analysis.imagePath.isNotEmpty && File(analysis.imagePath).existsSync()) {
      return Image.file(
        File(analysis.imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderImage(),
      );
    }
    return _placeholderImage();
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }
}

/// Confidence badge
class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  Color get _color {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${(confidence * 100).toInt()}%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _color,
        ),
      ),
    );
  }
}

/// Small info chip
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no history
class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 64,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Geçmiş Boş',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Yemek fotoğrafı çekerek kalori\nanalizi yapmaya başlayın.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
