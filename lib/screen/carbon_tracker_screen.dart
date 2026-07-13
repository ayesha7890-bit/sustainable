import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class carban extends StatefulWidget {
  const carban({super.key});

  @override
  State<carban> createState() => _carbanState();
}

class _carbanState extends State<carban> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _carbonLogs = [];

  // Sliders values (Minutes)
  double _walkMinutes = 15;
  double _bicycleMinutes = 20;
  double _motorcycleMinutes = 15;
  double _carMinutes = 10;

  // Colors
  static const Color forest = Color(0xFF1E3A2F);
  static const Color sage = Color(0xFF5E8570);
  static const Color sand = Color(0xFFF4EAE1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await DatabaseHelper.instance.getCarbonLogs();
    setState(() {
      _carbonLogs = logs;
    });
  }

  double get _walkCo2 => 0.0;
  double get _bicycleCo2 => 0.0;
  double get _motorcycleCo2 => _motorcycleMinutes * 0.12;
  double get _carCo2 => _carMinutes * 0.22;

  double get _totalWeeklyEstimate => _walkCo2 + _bicycleCo2 + _motorcycleCo2 + _carCo2;

  void _saveCurrentLog() async {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    Map<String, dynamic> row = {
      'date': todayStr,
      'transport_co2': _motorcycleCo2 + _carCo2,
      'energy_co2': 0.0,
      'waste_co2': 0.0,
      'total_co2': _totalWeeklyEstimate,
    };

    await DatabaseHelper.instance.insertCarbonLog(row);
    _loadLogs();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ Carbon audit logged successfully!'),
          backgroundColor: forest,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.calculate_outlined), text: "Auditor"), // 💡 FIXED: Standard icon used here
            Tab(icon: Icon(Icons.history_toggle_off), text: "Past Logs"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAuditorTab(),
              _buildPastLogsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuditorTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Weekly Estimate",
                    style: TextStyle(color: Colors.black45, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${_totalWeeklyEstimate.toStringAsFixed(1)} kg CO₂",
                    style: const TextStyle(color: forest, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Icon(Icons.cloud, size: 50, color: sage),
            ],
          ),
        ),

        const SizedBox(height: 25),
        const Text(
          "Transportation",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),

        _buildSliderItem("Walk", _walkMinutes, 0, 60, Icons.directions_walk, Colors.green.withOpacity(0.15), Colors.green, _walkCo2, (val) {
          setState(() => _walkMinutes = val);
        }),
        _buildSliderItem("Bicycle", _bicycleMinutes, 0, 60, Icons.directions_bike, Colors.lightGreen.withOpacity(0.15), Colors.lightGreen, _bicycleCo2, (val) {
          setState(() => _bicycleMinutes = val);
        }),
        _buildSliderItem("Motorcycle", _motorcycleMinutes, 0, 60, Icons.two_wheeler, Colors.amber.withOpacity(0.15), Colors.amber.shade700, _motorcycleCo2, (val) {
          setState(() => _motorcycleMinutes = val);
        }),
        _buildSliderItem("Car Ride", _carMinutes, 0, 120, Icons.directions_car, Colors.red.withOpacity(0.15), Colors.red.shade400, _carCo2, (val) {
          setState(() => _carMinutes = val);
        }),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: forest,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _saveCurrentLog,
            child: const Text("Log Today's Audit", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSliderItem(
      String title,
      double currentVal,
      double min,
      double max,
      IconData icon,
      Color iconBg,
      Color accent,
      double calculatedCo2,
      ValueChanged<double> onChanged
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: iconBg,
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: forest)),
                  Text("${currentVal.toInt()} minutes", style: const TextStyle(color: Colors.black45, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Text(
                "${calculatedCo2.toStringAsFixed(1)} kg CO2",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              )
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accent,
              inactiveTrackColor: sage.withOpacity(0.2),
              thumbColor: accent,
              trackHeight: 4,
            ),
            child: Slider(
              value: currentVal,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPastLogsTab() {
    if (_carbonLogs.isEmpty) {
      return const Center(
        child: Text("No audits recorded yet.", style: TextStyle(color: Colors.white70, fontSize: 15)),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _carbonLogs.length,
      itemBuilder: (context, index) {
        final log = _carbonLogs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log['date'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: forest)),
                  const SizedBox(height: 4),
                  const Text("Transportation Track Log", style: TextStyle(color: Colors.black45, fontSize: 12)),
                ],
              ),
              Text(
                "${double.parse(log['total_co2'].toString()).toStringAsFixed(1)} kg",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 16),
              )
            ],
          ),
        );
      },
    );
  }
}