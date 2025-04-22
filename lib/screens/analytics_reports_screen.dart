import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class AnalyticsReportsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final financialData = Provider.of<FinancialData>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _generateReport(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTimePeriodSelector(context),
            const SizedBox(height: 20),
            _buildChartContainer(
              'Income vs Expenses',
              200,
              financialData.getChartData() as List<Map<String, dynamic>>,
              financialData.selectedPeriod,
            ),
            const SizedBox(height: 20),
            _buildChartContainer(
              'Expense Breakdown',
              150,
              financialData.getPieChartData(),
              financialData.selectedPeriod,
              isPieChart: true,
            ),
            const SizedBox(height: 20),
            _buildLegend(financialData.getPieChartData()),
          ],
        ),
      ),
    );
  }


  Widget _buildTimePeriodSelector(BuildContext context) {
    final financialData = Provider.of<FinancialData>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTimeButton('Week', 'week', financialData),
        _buildTimeButton('Month', 'month', financialData),
        _buildTimeButton('Year', 'year', financialData),
      ],
    );
  }

  Widget _buildTimeButton(String label, String period, FinancialData financialData) {
    final isSelected = financialData.selectedPeriod == period;

    return ElevatedButton(
      onPressed: () => financialData.changePeriod(period),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildChartContainer(String title, double height, List<Map<String, dynamic>> data,
      String period, {bool isPieChart = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: height,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isPieChart
                  ? _buildPieChart(data)
                  : _buildBarChart(data, period),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, String period) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((item) {
          double income = item['income'] ?? 0.0;
          double expenses = item['expenses'] ?? 0.0;
          String label = _getLabel(item, period);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 50,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          height: income / 100, // scale down
                          width: 20,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          height: expenses / 100,
                          width: 20,
                          margin: const EdgeInsets.only(left: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text("↑", style: TextStyle(fontSize: 10)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }


  String _getLabel(Map<String, dynamic> item, String period) {
    switch(period) {
      case 'week':
        return item['day']; // Mon, Tue, etc.
      case 'month':
        return item['day']; // '01', '02', ...
      case 'year':
        return item['month'].substring(0, 3); // 'Jan', 'Feb', ...
      default:
        return '';
    }
  }



  Widget _buildPieChart(List<Map<String, dynamic>> data) {
    return SizedBox(
      height: 150,
      width: 150,
      child: CustomPaint(
        painter: PieChartPainter(data),
        child: Center(
          child: Text(
            "${data.length} Categories",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }


  Widget _buildLegend(List<Map<String, dynamic>> categories) {
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      children: categories.map((category) =>
          _buildLegendItem(category['category'], category['color'])
      ).toList(),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  void _generateReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report generated successfully'),
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    double total = data.fold(0, (sum, item) => sum + item['percentage']);
    double startRadian = -90 * 3.14159265 / 180; // start at top

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var item in data) {
      final sweepRadian = (item['percentage'] / total) * 2 * 3.14159265;
      paint.color = item['color'];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startRadian,
        sweepRadian,
        true,
        paint,
      );
      startRadian += sweepRadian;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
