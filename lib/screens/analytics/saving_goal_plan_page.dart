import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/saving_plan_model.dart';
import '../../repositories/saving_plan_repository.dart';

class SavingGoalPlanPage extends StatelessWidget {
  const SavingGoalPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SavingPlanRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saving Goal Plan'),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: repository.getCurrentPlanStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final data = snapshot.data?.data();

            if (!snapshot.hasData || data == null) {
              return const _NoPlanView();
            }

            final plan = SavingPlanModel.fromMap(data);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎯 Saving Goal Plan',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This plan is saved in Firebase and will be used by AI Financial Insight.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _PlanSectionCard(
                    icon: Icons.flag_rounded,
                    title: 'Goal',
                    content: plan.goalText.isEmpty
                        ? 'No goal description provided.'
                        : plan.goalText,
                  ),
                  const SizedBox(height: 16),
                  _PlanSectionCard(
                    icon: Icons.savings_rounded,
                    title: 'Target',
                    content: plan.targetAmount <= 0
                        ? 'No fixed target amount\nTimeframe: ${plan.timeframe}'
                        : '\$${plan.targetAmount.toStringAsFixed(0)}\nTimeframe: ${plan.timeframe}',
                  ),
                  const SizedBox(height: 16),
                  _PlanSectionCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'AI Plan Summary',
                    content: plan.planSummary,
                  ),
                  const SizedBox(height: 16),
                  _PlanSectionCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'Weekly Target',
                    content: plan.weeklyTarget,
                  ),
                  const SizedBox(height: 16),
                  _PlanSectionCard(
                    icon: Icons.category_rounded,
                    title: 'Focus Categories',
                    content: plan.focusCategories,
                  ),
                  const SizedBox(height: 16),
                  _PlanSectionCard(
                    icon: Icons.checklist_rounded,
                    title: 'Action Steps',
                    content: plan.actionSteps,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await repository.deleteCurrentPlan();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saving goal plan removed.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Remove current plan'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NoPlanView extends StatelessWidget {
  const _NoPlanView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFDFF7F1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.flag_rounded,
                size: 42,
                color: Color(0xFF00BFA5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No saving plan yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Go to AI Chat and tell the AI your goal, such as “I want to save \$5000 in three months.” The AI will create a plan and save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.smart_toy_rounded),
              label: const Text('Go back and open AI Chat'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _PlanSectionCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF7F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF00BFA5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content.trim().isEmpty ? 'No content yet.' : content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
