// lib/screens/analytics_reports_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../app_state.dart';

class AnalyticsReportsScreen extends StatefulWidget {
  @override
  _AnalyticsReportsScreenState createState() =>
      _AnalyticsReportsScreenState();
}

class _AnalyticsReportsScreenState extends State<AnalyticsReportsScreen> {
  int _touchedPieIndex = -1;
  int _touchedBarGroup = -1;

  @override
  Widget build(BuildContext context) {
    final fd = Provider.of<FinancialData>(context);
    final txs = fd.filteredTransactions;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Analytics & Reports',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.grey[800]),
        actions: [
          IconButton(
            icon: Icon(Icons.download, color: Colors.grey[800]),
            onPressed: _promptDateRangeAndGenerateReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeSelector(fd),
            const SizedBox(height: 24),

            // Bar Chart Section
            Text(
              'Income vs Expenses',
              style: TextStyle(
                color: Colors.grey[900],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 1.7,
                  child: _buildBarChart(txs, fd),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Pie Chart Section
            Text(
              'Expense Breakdown',
              style: TextStyle(
                color: Colors.grey[900],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.3,
                      child: _buildPieChart(txs),
                    ),
                    const SizedBox(height: 16),
                    _buildLegend(_generatePieData(txs)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show date‐range dialog, then generate the PDF report.
  Future<void> _promptDateRangeAndGenerateReport() async {
    DateTime? start;
    DateTime? end;
    final fmt = DateFormat('yyyy-MM-dd');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setState) => AlertDialog(
          title: const Text('Select Date Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'From: ${start != null ? fmt.format(start!) : '—'}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx2,
                    initialDate: start ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => start = d);
                },
              ),
              ListTile(
                title: Text(
                  'To:   ${end != null ? fmt.format(end!) : '—'}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx2,
                    initialDate: end ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => end = d);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx2).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (start != null && end != null)
                  ? () {
                Navigator.of(ctx2).pop();
                _generateReportForRange(start!, end!);
              }
                  : null,
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  /// Filter transactions, build PDF, and share it.
  Future<void> _generateReportForRange(
      DateTime start, DateTime end) async {
    final fd = Provider.of<FinancialData>(context, listen: false);
    final txs = fd.filteredTransactions.where((tx) {
      final d = tx['date'] as DateTime;
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();

    final pdfBytes = await _buildPdf(txs, fd, start: start, end: end);
    final fileName =
        'report_${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}.pdf';
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  Future<Uint8List> _buildPdf(
      List<Map<String, dynamic>> txs,
      FinancialData fd, {
        DateTime? start,
        DateTime? end,
      }) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('yyyy-MM-dd');
    final periodLabel = (start != null && end != null)
        ? '${dateFmt.format(start)} – ${dateFmt.format(end)}'
        : (fd.selectedPeriod == 'month'
        ? DateFormat.yMMM().format(fd.currentBaseDate)
        : fd.currentBaseDate.year.toString());

    final summaryData = [
      ['Income', '₹${fd.budget['income']!.toStringAsFixed(2)}'],
      ['Expenses', '₹${fd.budget['expenses']!.toStringAsFixed(2)}'],
      ['Savings', '₹${fd.budget['savings']!.toStringAsFixed(2)}'],
    ];

    final txRows = txs.map((tx) {
      return [
        dateFmt.format(tx['date'] as DateTime),
        tx['type'] as String,
        tx['category'] as String,
        '₹${(tx['amount'] as double).toStringAsFixed(2)}',
      ];
    }).toList();

    final grouped = _generateBarData(txs, fd);
    final analyticsRows = grouped.map((e) {
      final label = fd.selectedPeriod == 'year' ? e['month'] : e['day'];
      return [
        label,
        '₹${(e['income'] as double).toStringAsFixed(2)}',
        '₹${(e['expenses'] as double).toStringAsFixed(2)}',
      ];
    }).toList();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Header(
            level: 0,
            child: pw.Text('Financial Report',
                style: pw.TextStyle(fontSize: 24))),
        pw.Text('Period: $periodLabel', style: pw.TextStyle(fontSize: 16)),
        pw.SizedBox(height: 12),
        pw.Text('Summary', style: pw.TextStyle(fontSize: 18)),
        pw.Table.fromTextArray(headers: ['Metric', 'Amount'], data: summaryData),
        pw.SizedBox(height: 16),
        pw.Text('Transactions', style: pw.TextStyle(fontSize: 18)),
        pw.Table.fromTextArray(
            headers: ['Date', 'Type', 'Category', 'Amount'], data: txRows),
        pw.SizedBox(height: 16),
        pw.Text('Analytics', style: pw.TextStyle(fontSize: 18)),
        pw.Table.fromTextArray(
            headers: [
              fd.selectedPeriod == 'year' ? 'Month' : 'Day',
              'Income',
              'Expenses'
            ],
            data: analyticsRows),
      ],
    ));

    return pdf.save();
  }

  // ─── Chart Builders & Helpers ────────────────────────────────────────────

  Widget _buildTimeSelector(FinancialData fd) {
    final date = fd.currentBaseDate;
    final label = fd.selectedPeriod == 'month'
        ? DateFormat.yMMM().format(date)
        : date.year.toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            icon: Icon(Icons.chevron_left, color: Colors.grey[800]),
            onPressed: () => fd.goToPreviousPeriod()),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ['month', 'year'].map((period) {
              final sel = fd.selectedPeriod == period;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    period == 'month' ? 'Month' : 'Year',
                    style: TextStyle(
                        color: sel ? Colors.white : Colors.grey[800],
                        fontWeight: FontWeight.w500),
                  ),
                  selected: sel,
                  selectedColor: Colors.teal[400],
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                          color: sel
                              ? Colors.teal[400]!
                              : Colors.grey[300]!)),
                  onSelected: (_) => fd.changePeriod(period),
                ),
              );
            }).toList()
              ..insert(
                  0,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(label,
                        style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600)),
                  )),
          ),
        ),
        IconButton(
            icon: Icon(Icons.chevron_right, color: Colors.grey[800]),
            onPressed: () => fd.goToNextPeriod()),
      ],
    );
  }

  BarChart _buildBarChart(List<Map<String, dynamic>> txs, FinancialData fd) {
    final grouped = _generateBarData(txs, fd);
    final maxVal = grouped
        .map((e) {
      final i = e['income'] as double;
      final ex = e['expenses'] as double;
      return i > ex ? i : ex;
    })
        .fold(0.0, (a, b) => a > b ? a : b);

    return BarChart(BarChartData(
      maxY: maxVal * 1.2,
      barTouchData: BarTouchData(
        touchCallback: (evt, resp) {
          setState(() =>
          _touchedBarGroup = resp?.spot?.touchedBarGroupIndex ?? -1);
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= grouped.length) return const SizedBox();
              final label = fd.selectedPeriod == 'year'
                  ? grouped[idx]['month']
                  : grouped[idx]['day'];
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 4,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(label,
                      style:
                      TextStyle(fontSize: 12, color: Colors.grey[700])),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              final text = value >= 1000
                  ? '${(value / 1000).toStringAsFixed(1)}K'
                  : value.toInt().toString();
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(text,
                      style:
                      TextStyle(color: Colors.grey[700], fontSize: 12)),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: grouped.asMap().entries.map((entry) {
        final idx = entry.key;
        final e = entry.value;
        final y1 = e['income'] as double;
        final y2 = e['expenses'] as double;
        final touched = idx == _touchedBarGroup;
        return BarChartGroupData(x: idx, barsSpace: 6, barRods: [
          BarChartRodData(
              toY: touched ? y1 * 1.1 : y1,
              color: Colors.teal,
              width: 8,
              borderRadius: BorderRadius.circular(4)),
          BarChartRodData(
              toY: touched ? y2 * 1.1 : y2,
              color: Colors.deepOrange,
              width: 8,
              borderRadius: BorderRadius.circular(4)),
        ]);
      }).toList(),
    ));
  }

  List<Map<String, dynamic>> _generateBarData(
      List<Map<String, dynamic>> txs, FinancialData fd) {
    final m = <String, Map<String, double>>{};
    for (var tx in txs) {
      final date = tx['date'] as DateTime;
      final key = fd.selectedPeriod == 'year'
          ? DateFormat('MMM').format(date)
          : DateFormat('dd').format(date);
      m.putIfAbsent(key, () => {'income': 0.0, 'expenses': 0.0});
      final amt = tx['amount'] as double;
      if (tx['type'] == 'income')
        m[key]!['income'] = m[key]!['income']! + amt;
      else
        m[key]!['expenses'] = m[key]!['expenses']! + amt;
    }
    return m.entries.map((e) {
      return fd.selectedPeriod == 'year'
          ? {
        'month': e.key,
        'income': e.value['income']!,
        'expenses': e.value['expenses']!
      }
          : {
        'day': e.key,
        'income': e.value['income']!,
        'expenses': e.value['expenses']!
      };
    }).toList();
  }

  Widget _buildPieChart(List<Map<String, dynamic>> txs) {
    final data = _generatePieData(txs);
    final sections = data.asMap().entries.map((e) {
      final idx = e.key;
      final item = e.value;
      final touched = idx == _touchedPieIndex;
      return PieChartSectionData(
        color: item['color'] as Color,
        value: item['percentage'] as double,
        radius: touched ? 70 : 60,
        title:
        '${(item['percentage'] as double).toStringAsFixed(1)}%',
        titleStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: touched ? 18 : 14,
        ),
      );
    }).toList();

    return PieChart(PieChartData(
      sections: sections,
      centerSpaceRadius: 30,
      sectionsSpace: 4,
      pieTouchData: PieTouchData(
        touchCallback: (evt, resp) {
          setState(() {
            _touchedPieIndex =
                resp?.touchedSection?.touchedSectionIndex ?? -1;
          });
        },
      ),
    ));
  }

  List<Map<String, dynamic>> _generatePieData(List<Map<String, dynamic>> txs) {
    final totals = <String, double>{};
    double sum = 0;
    for (var tx in txs) {
      if (tx['type'] == 'expense') {
        final cat = tx['category'] as String;
        final amt = tx['amount'] as double;
        totals[cat] = (totals[cat] ?? 0) + amt;
        sum += amt;
      }
    }
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple
    ];
    var i = 0;
    return totals.entries.map((e) {
      final perc = sum > 0 ? (e.value / sum * 100) : 0.0;
      return {
        'category': e.key,
        'percentage': perc,
        'color': colors[i++ % colors.length],
      };
    }).toList();
  }

  Widget _buildLegend(List<Map<String, dynamic>> data) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: data.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: e['color'] as Color),
            const SizedBox(width: 4),
            Text(e['category'] as String,
                style: TextStyle(color: Colors.grey[800])),
          ],
        );
      }).toList(),
    );
  }
}
