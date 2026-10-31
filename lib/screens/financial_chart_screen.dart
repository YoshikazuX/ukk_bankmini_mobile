import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../services/nasabah_api_service.dart';
import '../widgets/common/app_states.dart';

/// Halaman Grafik & Analisis Keuangan Nasabah
/// Menggunakan Backend Laravel sebagai Single Source of Truth — Zero Dummy Data
class FinancialChartScreen extends StatefulWidget {
  const FinancialChartScreen({super.key});

  @override
  State<FinancialChartScreen> createState() => _FinancialChartScreenState();
}

class _FinancialChartScreenState extends State<FinancialChartScreen> {
  // Chart view mode: 0 = Bar Chart (Setoran vs Penarikan), 1 = Line Chart (Pertumbuhan Saldo)
  int _chartMode = 0;
  // Period filter: 0 = 6 Bulan Terakhir, 1 = 3 Bulan Terakhir
  int _periodFilter = 0;

  List<Map<String, dynamic>> _monthlyTrend = [];
  double _avgMonthlyBackend = 0.0;
  double _totalSaldoReal = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLiveData();
  }

  Future<void> _fetchLiveData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await NasabahApiService.getRingkasan();

      if (!mounted) return;

      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        _totalSaldoReal = (data['total_saldo'] as num?)?.toDouble() ?? 0.0;
        _avgMonthlyBackend =
            (data['average_monthly_deposit'] as num?)?.toDouble() ?? 0.0;

        if (data['monthly_trend_6_months'] is List) {
          _monthlyTrend = List<Map<String, dynamic>>.from(
            (data['monthly_trend_6_months'] as List).map(
              (item) => Map<String, dynamic>.from(item as Map),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res.message.isNotEmpty
              ? res.message
              : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.accentTealHover,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ErrorState(
              title: 'Gagal Memuat Analisis',
              message: _errorMessage!,
              onRetry: _fetchLiveData,
            ),
          ),
        ),
      );
    }

    // Bangun data keuangan berdasarkan monthlyTrend backend
    List<Map<String, dynamic>> displayedTrend = List.from(_monthlyTrend);

    if (_periodFilter == 1 && displayedTrend.length > 3) {
      displayedTrend = displayedTrend.sublist(displayedTrend.length - 3);
    }

    final List<String> months = displayedTrend
        .map((m) => m['month_name']?.toString() ?? '')
        .toList();
    final List<double> setoran = displayedTrend
        .map((m) => (m['setoran'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final List<double> penarikan = displayedTrend
        .map((m) => (m['penarikan'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final List<double> runningBalances = displayedTrend
        .map((m) => (m['running_balance'] as num?)?.toDouble() ?? 0.0)
        .toList();

    double totalSetoran = setoran.fold(0, (a, b) => a + b);
    double totalPenarikan = penarikan.fold(0, (a, b) => a + b);
    double netTabungan = totalSetoran - totalPenarikan;
    double avgMonthly = _avgMonthlyBackend > 0
        ? _avgMonthlyBackend
        : (months.isNotEmpty ? (totalSetoran / months.length) : 0);
    double savingsRate = totalSetoran > 0
        ? ((totalSetoran - totalPenarikan) / totalSetoran * 100).clamp(0, 100)
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accentTealHover,
          onRefresh: _fetchLiveData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                _buildSummaryCards(
                  totalSetoran: totalSetoran,
                  totalPenarikan: totalPenarikan,
                  netTabungan: netTabungan,
                  savingsRate: savingsRate,
                  avgMonthly: avgMonthly,
                ),
                const SizedBox(height: 16),

                // Filter Controls & View Switcher
                _buildFilterAndSwitcher(),
                const SizedBox(height: 14),

                // Main Chart Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _chartMode == 0
                                    ? 'Perbandingan Arus Kas'
                                    : 'Tren Akumulasi Saldo',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                _chartMode == 0
                                    ? 'Setoran (Hijau) vs Penarikan (Merah)'
                                    : 'Pertumbuhan tabungan berjalan',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          _buildLegend(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: months.isNotEmpty &&
                                (totalSetoran > 0 || totalPenarikan > 0 || _totalSaldoReal > 0)
                            ? (_chartMode == 0
                                ? _buildBarChart(setoran, penarikan, months)
                                : _buildLineChart(runningBalances, months))
                            : _buildEmptyChartState(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Financial Literacy Insight Card
                _buildInsightCard(savingsRate),
                const SizedBox(height: 16),

                // Monthly Breakdown List
                _buildMonthlyBreakdown(setoran, penarikan, months),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grafik & Analisis Keuangan',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Pertumbuhan saldo dan arus kas siswa',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
          tooltip: 'Panduan Grafik',
          onPressed: () => _showChartInfoDialog(context),
        ),
      ],
    );
  }

  Widget _buildSummaryCards({
    required double totalSetoran,
    required double totalPenarikan,
    required double netTabungan,
    required double savingsRate,
    required double avgMonthly,
  }) {
    return Column(
      children: [
        // Top 2 Cards
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Total Setoran',
                value: formatRupiah(totalSetoran),
                icon: Icons.arrow_downward_rounded,
                color: AppColors.success,
                subtext: 'Pemasukan kas siswa',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                title: 'Total Penarikan',
                value: formatRupiah(totalPenarikan),
                icon: Icons.arrow_upward_rounded,
                color: AppColors.danger,
                subtext: 'Pengeluaran tunai',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Bottom 3 Mini stats
        Row(
          children: [
            Expanded(
              child: _miniMetricCard(
                label: 'Tabungan Bersih',
                value: formatRupiah(netTabungan),
                color: AppColors.accentTealHover,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _miniMetricCard(
                label: 'Rata-rata/Bulan',
                value: formatRupiah(avgMonthly),
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _miniMetricCard(
                label: 'Rasio Tabung',
                value: '${savingsRate.toStringAsFixed(0)}%',
                color:
                    savingsRate >= 50 ? AppColors.success : AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMetricCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.insights_rounded,
            color: AppColors.textSecondary,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Belum Ada Mutasi Transaksi',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Grafik perbandingan arus kas bulanan akan terbentuk seiring aktivitas transaksi tabungan Anda di loket Teller.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSwitcher() {
    return Column(
      children: [
        // Chart mode switch tabs
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _switchButton(
                  title: 'Diagram Batang',
                  icon: Icons.bar_chart_rounded,
                  isSelected: _chartMode == 0,
                  onTap: () => setState(() => _chartMode = 0),
                ),
              ),
              Expanded(
                child: _switchButton(
                  title: 'Grafik Garis Tren',
                  icon: Icons.show_chart_rounded,
                  isSelected: _chartMode == 1,
                  onTap: () => setState(() => _chartMode = 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Period Filter Chips
        Row(
          children: [
            Text(
              'Periode:',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            _periodChip(0, '6 Bulan Terakhir'),
            const SizedBox(width: 6),
            _periodChip(1, '3 Bulan Terakhir'),
          ],
        ),
      ],
    );
  }

  Widget _switchButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.accentTealHover : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.accentTealHover : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(int index, String label) {
    final isSelected = _periodFilter == index;
    return InkWell(
      onTap: () => setState(() => _periodFilter = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenLight : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.accentTealHover : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.accentTealHover : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    if (_chartMode == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem(AppColors.success, 'Setor'),
          const SizedBox(width: 8),
          _legendItem(AppColors.danger, 'Tarik'),
        ],
      );
    } else {
      return _legendItem(AppColors.info, 'Saldo Berjalan');
    }
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(
    List<double> setoran,
    List<double> penarikan,
    List<String> months,
  ) {
    double maxVal = 0;
    for (var v in setoran) {
      if (v > maxVal) maxVal = v;
    }
    for (var v in penarikan) {
      if (v > maxVal) maxVal = v;
    }
    if (maxVal == 0) maxVal = 50000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.primaryNavy,
            tooltipRoundedRadius: 6,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final isSetoran = rodIndex == 0;
              final type = isSetoran ? 'Setoran' : 'Penarikan';
              final monthLabel = groupIndex >= 0 && groupIndex < months.length
                  ? months[groupIndex]
                  : '';
              return BarTooltipItem(
                '$type ($monthLabel)\n',
                GoogleFonts.inter(
                  color: isSetoran
                      ? AppColors.accentTeal
                      : const Color(0xFFF87171),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                children: [
                  TextSpan(
                    text: formatRupiah(rod.toY),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      months[index],
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '${(value / 1000).toInt()}k',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal > 0 ? (maxVal / 3) : 20000,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(months.length, (i) {
          final s = i < setoran.length ? setoran[i] : 0.0;
          final p = i < penarikan.length ? penarikan[i] : 0.0;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: s,
                color: AppColors.success,
                width: 7,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(3)),
              ),
              BarChartRodData(
                toY: p,
                color: AppColors.danger,
                width: 7,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(
    List<double> balances,
    List<String> months,
  ) {
    if (balances.isEmpty) return _buildEmptyChartState();

    List<FlSpot> spots = [];
    for (int i = 0; i < balances.length; i++) {
      spots.add(FlSpot(i.toDouble(), balances[i]));
    }

    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (minY == maxY) {
      minY = minY > 0 ? minY * 0.8 : 0;
      maxY = maxY > 0 ? maxY * 1.2 : 50000;
    }

    return LineChart(
      LineChartData(
        minY: (minY * 0.95).clamp(0, double.infinity),
        maxY: maxY * 1.05,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.primaryNavy,
            tooltipRoundedRadius: 6,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                int index = spot.x.toInt();
                final mLabel = index >= 0 && index < months.length
                    ? months[index]
                    : '';
                return LineTooltipItem(
                  'Saldo $mLabel\n',
                  GoogleFonts.inter(
                    color: AppColors.accentTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  children: [
                    TextSpan(
                      text: formatRupiah(spot.y),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      months[index],
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toInt()}k',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.accentTealHover,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: AppColors.accentTealHover,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accentTeal.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(double savingsRate) {
    final isGood = savingsRate >= 50;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isGood
              ? AppColors.success.withValues(alpha: 0.25)
              : AppColors.warning.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isGood ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isGood
                  ? Icons.auto_awesome_rounded
                  : Icons.tips_and_updates_rounded,
              color: isGood ? AppColors.success : AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGood
                      ? 'Kebiasaan Menabung Sangat Bagus!'
                      : 'Yuk Tingkatkan Tabunganmu!',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isGood
                      ? 'Rasio menabung Anda mencapai ${savingsRate.toStringAsFixed(0)}%. Pertahankan kedisiplinan menyetor setiap minggu di loket Bank Mini Sekolah!'
                      : 'Rasio menabung saat ini ${savingsRate.toStringAsFixed(0)}%. Cobalah menyisihkan uang jajan minimal Rp5.000 setiap minggu di loket Teller agar target impian lekas tercapai.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdown(
    List<double> setoran,
    List<double> penarikan,
    List<String> months,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rincian Per Bulan',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${months.length} Bulan Terpilih',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (months.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Belum ada rincian transaksi bulanan',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: months.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: AppColors.border, height: 14),
              itemBuilder: (context, i) {
                final s = i < setoran.length ? setoran[i] : 0.0;
                final p = i < penarikan.length ? penarikan[i] : 0.0;
                final net = s - p;

                return Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        months[i],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '+ ${formatRupiah(s)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: s > 0
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '- ${formatRupiah(p)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: p > 0
                                  ? AppColors.danger
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      net >= 0 ? '+${formatRupiah(net)}' : formatRupiah(net),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: net >= 0 ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  void _showChartInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.insights_rounded,
                color: AppColors.accentTealHover, size: 20),
            const SizedBox(width: 8),
            Text(
              'Info Analisis Finansial',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Grafik ini menyajikan rangkuman mutasi transaksi Anda secara visual.\n\n'
          '• Diagram Batang: Membandingkan total setoran tabungan dan penarikan kas loket per bulan.\n'
          '• Garis Tren: Menggambarkan arah pertumbuhan akumulasi saldo simpanan Anda.\n\n'
          'Data diperbarui secara otomatis setiap kali Teller mengesahkan transaksi di loket sekolah.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Mengerti',
              style: GoogleFonts.inter(
                color: AppColors.accentTealHover,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
