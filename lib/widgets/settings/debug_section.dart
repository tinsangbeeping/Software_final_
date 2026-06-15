import 'package:flutter/material.dart';
import '../../core/services/date_override_service.dart';

class DebugSection extends StatefulWidget {
  const DebugSection({super.key});

  @override
  State<DebugSection> createState() => _DebugSectionState();
}

class _DebugSectionState extends State<DebugSection> {
  bool _isEnabled = false;
  String _currentOverride = 'None';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final service = await DateOverrideService.getInstance();
    setState(() {
      _isEnabled = service.isEnabled;
      _currentOverride = service.overrideString ?? 'None';
    });
  }

  Future<void> _pickDate() async {
    final service = await DateOverrideService.getInstance();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: service.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      await service.setOverride(picked);
      setState(() {
        _isEnabled = true;
        _currentOverride = picked.toIso8601String().split('T')[0];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Date override set to $_currentOverride'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _clearOverride() async {
    final service = await DateOverrideService.getInstance();
    await service.clearOverride();
    setState(() {
      _isEnabled = false;
      _currentOverride = 'None';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Date override cleared — using real date'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF00BFA6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report_rounded, color: Colors.orange.shade700, size: 22),
              const SizedBox(width: 8),
              Text(
                'Debug Tools',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: Colors.grey[600], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date Override', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      _isEnabled ? 'Active: $_currentOverride' : 'Using real date',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isEnabled,
                activeColor: Colors.orange.shade700,
                onChanged: (value) {
                  if (value) {
                    _pickDate();
                  } else {
                    _clearOverride();
                  }
                },
              ),
            ],
          ),

          if (_isEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                    label: const Text('Change Date'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearOverride,
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          Text(
            'Override the app date to test weekly coaching with different time ranges.',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
