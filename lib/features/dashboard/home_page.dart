// lib/features/dashboard/home_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/auth/auth_gate_page.dart';
import 'package:gasra_monitoring/features/auth/providers/auth_provider.dart';
import 'package:gasra_monitoring/features/history/history_page.dart';
import 'package:gasra_monitoring/features/maintanance/pages/maintanance_history_page.dart';
import 'package:gasra_monitoring/features/maintanance/pages/maintenance_detail_page.dart';
import 'package:gasra_monitoring/features/maintanance/pages/maintenance_list_page.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

// Halaman-halaman untuk Aksi Cepat
import 'package:gasra_monitoring/features/report/pages/report_type_selection_page.dart';
import 'package:gasra_monitoring/features/washing/pages/washing_log_page.dart';

class HomePage extends StatefulWidget {
  final Function(int) onNavigateToTab;
  const HomePage({super.key, required this.onNavigateToTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _fetchDashboardData();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    try {
      return await SupabaseManager.client.rpc('get_full_dashboard_data');
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      throw Exception('Gagal menjalankan fungsi RPC: $e');
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Ya, Keluar',
                  style: TextStyle(color: Colors.red.shade700))),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await SupabaseManager.client.auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGatePage()),
          (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Selamat Datang,",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            Text(authProvider.userName ?? 'Pengguna',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardDataFuture = _fetchDashboardData();
              });
            },
            child: _buildBody(snapshot),
          );
        },
      ),
    );
  }

  Widget _buildBody(AsyncSnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    "Gagal memuat data dashboard.\nCoba tarik layar ke bawah untuk refresh.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ),
          )
        ],
      );
    }

    final data = snapshot.data!;
    final stats = data['stats'] ?? {};
    final tugas = List<Map<String, dynamic>>.from(data['tugas_mendesak'] ?? []);

    return AnimationLimiter(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0, child: FadeInAnimation(child: widget)),
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.8,
              children: [
                _buildStatCard(
                    "Inspeksi Bulan Ini",
                    stats['inspeksi_bulan_ini'].toString(),
                    Icons.calendar_today,
                    Colors.blue,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HistoryPage()))),
                _buildStatCard(
                    "Perlu Perbaikan",
                    stats['perlu_perbaikan'].toString(),
                    Icons.warning_amber_rounded,
                    Colors.orange,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MaintenanceListPage()))),
                _buildStatCard(
                    "Perbaikan Selesai",
                    stats['perbaikan_bulan_ini'].toString(),
                    Icons.check_circle,
                    Colors.green,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MaintenanceHistoryPage()))),
                _buildStatCard(
                  "Laporan Baru (24j)",
                  stats['laporan_24_jam'].toString(),
                  Icons.new_releases,
                  Colors.red,
                ),
              ],
            ),
            _buildSectionTitle("Aksi Cepat"),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton("Mulai Inspeksi",
                    Icons.fact_check_rounded, () => widget.onNavigateToTab(1)),
                _buildQuickActionButton(
                    "Lapor Masalah",
                    Icons.report_problem_rounded,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ReportTypeSelectionPage()))),
                _buildQuickActionButton(
                    "Catat Pencucian",
                    Icons.wash_rounded,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WashingLogPage()))),
              ],
            ),
            if (tugas.isNotEmpty) ...[
              _buildSectionTitle("Perlu Perhatian Segera"),
              ...tugas.map((t) => _buildTaskCard(t)),
            ],
            _buildSectionTitle("Analisis"),
            _buildChartCard("Tren Masalah Harian",
                _buildBarChart(data['chart_tren_harian'])),
            const SizedBox(height: 16),
            _buildChartCard("Aset Bermasalah",
                _buildAssetBreakdownChart(data['chart_aset_bermasalah'])),
          ],
        ),
      ),
    );
  }

  // WIDGET BUILDERS

  Widget _buildSectionTitle(String title) {
    return Padding(
        padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
        child:
            Text(title, style: AppTextStyles.subtitle.copyWith(fontSize: 18)));
  }

  // Di dalam kelas _HomePageState

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              // [FIX] Using a Stack for perfect, non-overflowing layout
              child: Stack(
                children: [
                  // Number in the top left
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Icon in the top right
                  Align(
                    alignment: Alignment.topRight,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                  ),
                  // Title in the bottom left
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      String label, IconData icon, VoidCallback onTap) {
    return Column(children: [
      Material(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Icon(icon, color: AppTheme.primary, size: 28)))),
      const SizedBox(height: 8),
      Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))
    ]);
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final date = DateTime.parse(task['reported_at']).toLocal();
    final allItemsForDetail = [task];
    final reportedBy = task['reported_by'] ?? 'N/A';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.red),
        title: Text(
            task['custom_title'] ?? task['item_name'] ?? 'Item tidak diketahui',
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text("${task['unit_code']} • Dilaporkan oleh: $reportedBy",
            style: const TextStyle(fontSize: 12)),
        trailing: Text(DateFormat('d MMM').format(date),
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MaintenanceDetailPage(
                        unitCode: task['unit_code'],
                        items: allItemsForDetail,
                      )));
        },
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              SizedBox(height: 150, child: chart)
            ])));
  }

  Widget _buildBarChart(List<dynamic>? data) {
    if (data == null || data.isEmpty)
      return const Center(child: Text("Data tidak cukup"));
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String day = data[group.x.toInt()]['tanggal'];
            return BarTooltipItem(
              '$day\n',
              const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
              children: <TextSpan>[
                TextSpan(
                  text: (rod.toY).toInt().toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(data[value.toInt()]['tanggal'].split(' ')[0],
                        style: const TextStyle(fontSize: 10))))),
        leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(
          show: true, drawVerticalLine: false, horizontalInterval: 5),
      borderData: FlBorderData(show: false),
      // [FIX] Menghapus properti 'borderRadius' yang menyebabkan error
      barGroups: List.generate(
          data.length,
          (index) => BarChartGroupData(x: index, barRods: [
                BarChartRodData(
                    toY: data[index]['jumlah'].toDouble(),
                    color: AppTheme.primary,
                    width: 14)
              ])),
    ));
  }

  Widget _buildAssetBreakdownChart(List<dynamic>? data) {
    if (data == null || data.isEmpty)
      return const Center(child: Text("Tidak ada aset bermasalah."));
    final colors = [
      AppTheme.logoRed,
      AppTheme.logoAbu,
      AppTheme.logoBiru,
      Colors.red
    ];
    return Row(
      children: [
        Expanded(
            flex: 2,
            child: PieChart(PieChartData(
                sections: List.generate(data.length, (index) {
                  final item = data[index];
                  return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: item['jumlah'].toDouble(),
                      title: '${item['jumlah']}',
                      radius: 40,
                      titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white));
                }),
                sectionsSpace: 2,
                centerSpaceRadius: 30))),
        Expanded(
            flex: 3,
            child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(data.length, (index) {
                      final item = data[index];
                      return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(children: [
                            Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    borderRadius: BorderRadius.circular(4))),
                            const SizedBox(width: 8),
                            Text("${item['kategori']} (${item['jumlah']})")
                          ]));
                    })))),
      ],
    );
  }
}
