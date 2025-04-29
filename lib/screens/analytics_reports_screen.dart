// analytics_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_state.dart';

class AnalyticsReportsScreen extends StatefulWidget {
  @override
  _AnalyticsReportsScreenState createState() => _AnalyticsReportsScreenState();
}

class _AnalyticsReportsScreenState extends State<AnalyticsReportsScreen> {
  int _touchedPieIndex = -1;
  int _touchedBarGroup = -1;

  @override
  Widget build(BuildContext context) {
    final fd = Provider.of<FinancialData>(context);
    final txs = fd.transactions;

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
            onPressed: () => _generateReport(context),
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
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 1.7,
                  child: _buildBarChart(txs, fd.selectedPeriod),
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
                borderRadius: BorderRadius.circular(24),
              ),
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

  Widget _buildTimeSelector(FinancialData fd) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ['month', 'year'].map((period) {
            final label = period == 'month' ? 'Month' : 'Year';
            final sel = fd.selectedPeriod == period;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    color: sel ? Colors.white : Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: sel,
                selectedColor: Colors.teal[400],
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: sel ? Colors.teal[400]! : Colors.grey[300]!),
                ),
                onSelected: (_) => fd.changePeriod(period),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  BarChart _buildBarChart(List<Map<String, dynamic>> txs, String period) {
    final grouped = _generateBarData(txs, period);
    final maxVal = grouped
        .map((e) => (e['income'] as double).compareTo(e['expenses'] as double) > 0 ? e['income'] : e['expenses'])
        .fold(0.0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.2,
        barTouchData: BarTouchData(
          touchCallback: (evt, resp) {
            setState(() {
              if (resp == null || resp.spot == null) _touchedBarGroup = -1;
              else _touchedBarGroup = resp.spot!.touchedBarGroupIndex;
            });
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, meta) {
                final label = grouped[v.toInt()][period == 'year' ? 'month' : 'day'];
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  space: 4,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => SideTitleWidget(
              axisSide: m.axisSide,
              child: Text(v.toInt().toString(), style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            )),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: grouped.asMap().entries.map((e) {
          final idx = e.key;
          final map = e.value;
          final y1 = map['income'] as double;
          final y2 = map['expenses'] as double;
          final touched = idx == _touchedBarGroup;
          return BarChartGroupData(
            x: idx,
            barsSpace: 6,
            barRods: [
              BarChartRodData(toY: touched ? y1 * 1.1 : y1, color: Colors.teal, width: 8, borderRadius: BorderRadius.circular(4)),
              BarChartRodData(toY: touched ? y2 * 1.1 : y2, color: Colors.deepOrange, width: 8, borderRadius: BorderRadius.circular(4)),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _generateBarData(List<Map<String, dynamic>> txs, String period) {
    final m = <String, Map<String, double>>{};
    for (var tx in txs) {
      final date = tx['date'] as DateTime;
      final key = period == 'year' ? DateFormat('MMM').format(date) : DateFormat('dd').format(date);
      m.putIfAbsent(key, () => {'income': 0.0, 'expenses': 0.0});
      final amt = tx['amount'] as double;
      if (tx['type'] == 'income') m[key]!['income'] = m[key]!['income']! + amt;
      else m[key]!['expenses'] = m[key]!['expenses']! + amt;
    }
    return m.entries.map((e) => {
      if (period == 'year') 'month': e.key else 'day': e.key,
      'income': e.value['income'],
      'expenses': e.value['expenses'],
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
        title: '${item['percentage'].toStringAsFixed(1)}%',
        titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: touched ? 18 : 14),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 30,
        sectionsSpace: 4,
        pieTouchData: PieTouchData(
          touchCallback: (evt, resp) {
            setState(() {
              if (resp == null || resp.touchedSection == null) _touchedPieIndex = -1;
              else _touchedPieIndex = resp.touchedSection!.touchedSectionIndex;
            });
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generatePieData(List<Map<String, dynamic>> txs) {
    final totals = <String, double>{}; double sum=0;
    for(var tx in txs) if(tx['type']=='expense'){ final c=tx['category'] as String; final a=tx['amount'] as double; totals[c]=(totals[c]??0)+a; sum+=a; }
    final colors=[Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple]; var i=0;
    return totals.entries.map((e)=>{'category':e.key,'percentage':sum>0?e.value/sum*100:0,'color':colors[i++%colors.length]}).toList();
  }

  Widget _buildLegend(List<Map<String, dynamic>> data) {
    return Wrap(
      spacing: 12, runSpacing: 8,
      children: data.map((e)=>Row(mainAxisSize:MainAxisSize.min,children:[Container(width:12,height:12,color:e['color']as Color),const SizedBox(width:4),Text(e['category']as String,style:TextStyle(color:Colors.grey[800]))])).toList(),
    );
  }

  void _generateReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report generated successfully')));
  }
}
