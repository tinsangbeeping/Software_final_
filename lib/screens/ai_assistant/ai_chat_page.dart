import 'package:flutter/material.dart';

import '../../core/services/gemini_service.dart';
import '../../models/message_model.dart';
import '../../widgets/ai_assistant/chat_bubble.dart';
import '../../widgets/ai_assistant/message_input.dart';

import 'dart:convert';

import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../core/services/image_service.dart';
import '../../core/services/speech_service.dart';

import '../../repositories/budget_repository.dart';
import '../../models/budget_model.dart';
import '../../models/saving_plan_model.dart';
import '../../repositories/saving_plan_repository.dart';
import '../../core/services/budget_allocation_service.dart';

import '../../models/reminder_model.dart';
import '../../repositories/reminder_repository.dart';
import '../../widgets/chat/chat_header.dart';
import '../../core/services/habit_analyzer_service.dart';
import '../../core/services/date_override_service.dart';
import '../../core/services/spending_analyzer_service.dart';
import '../../models/weekly_snapshot_model.dart';
import '../../repositories/weekly_snapshot_repository.dart';


class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController messageController = TextEditingController();
  final GeminiService geminiService = GeminiService();
  final ImageService imageService = ImageService();
  final SpeechService speechService =
    SpeechService();
  final BudgetRepository budgetRepository =
    BudgetRepository();
  final ReminderRepository reminderRepository =
    ReminderRepository();
  final SavingPlanRepository savingPlanRepository = SavingPlanRepository();

  final TransactionRepository transactionRepository =
    TransactionRepository();

  bool isLoading = false;
  bool isListening = false;

  final List<MessageModel> messages = [
    MessageModel(
      text: "Hello! Ready to take control of your finances? 🚀 let's establish your baseline. What is the total budget you've allocated for this month?",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];
  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add(
        MessageModel(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );

      isLoading = true;
    });

    messageController.clear();

    try {
      final actions = await geminiService.planActions(text);
      final normalizedActions = await _ensureRequiredActions(text, actions);

      for (final action in normalizedActions) {
        await executeAction(action, originalText: text);
      }
    } catch (e) {
      setState(() {
        messages.add(
          MessageModel(
            text: "Sorry, I couldn't connect to Gemini.\n$e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _ensureRequiredActions(
    String text,
    List<Map<String, dynamic>> actions,
  ) async {
    final result = List<Map<String, dynamic>>.from(actions);
    final lower = text.toLowerCase();

    bool hasType(String type) => result.any(
          (a) => a["type"]?.toString().toLowerCase() == type,
        );

    final asksResetBudget = lower.contains('reset budget') ||
        lower.contains('clear budget') ||
        lower.contains('delete budget') ||
        text.contains('重設預算') ||
        text.contains('重置預算') ||
        text.contains('清空預算') ||
        text.contains('刪除預算') ||
        text.contains('删除预算');
    final asksBudget = lower.contains('budget') ||
        text.contains('預算') ||
        text.contains('预算');
    final asksPlan = lower.contains('saving plan') ||
        lower.contains('saving goal') ||
        text.contains('制定計畫') ||
        text.contains('制定计划') ||
        text.contains('幫我做計畫') ||
        text.contains('帮我做计划') ||
        text.contains('存錢計畫') ||
        text.contains('省錢計畫') ||
        text.contains('消費目標') ||
        text.contains('我想省') ||
        text.contains('我想存');
    final asksAnalysis = lower.contains('insight') ||
        lower.contains('analysis') ||
        lower.contains('analyze') ||
        text.contains('分析') ||
        text.contains('洞察') ||
        text.contains('建議');

    if (asksResetBudget && !hasType('reset')) {
      result.add({'type': 'reset'});
    } else if (asksBudget && !hasType('budget')) {
      try {
        String response = await geminiService.extractBudget(text);
        response = cleanAiJson(response);
        final data = jsonDecode(response);
        final limit = double.tryParse(data['limit'].toString()) ?? 0;
        if (limit > 0) {
          result.add({
            'type': 'budget',
            'category': data['category'] ?? 'Other',
            'limit': limit,
            'operation': inferBudgetOperation(
              Map<String, dynamic>.from(data),
              originalText: text,
            ),
          });
        }
      } catch (_) {}
    }

    if (asksPlan && !hasType('saving_plan')) {
      result.add({
        'type': 'saving_plan',
        'goalText': text,
      });
    }

    if (asksAnalysis && !hasType('analysis')) {
      result.add({'type': 'analysis'});
    }

    return result;
  }

  Future<void> executeAction(
    Map<String, dynamic> action, {
    required String originalText,
  }) async {
    final type = action["type"]?.toString().toLowerCase() ?? "chat";

    switch (type) {
      case "expense":
        await recordExpenseFromAction(action, originalText: originalText);
        break;
      case "budget":
        await recordBudgetFromAction(action, originalText: originalText);
        break;
      case "saving_plan":
        await createSavingPlanFromAction(action, originalText);
        break;
      case "reminder":
        await recordReminderFromAction(action);
        break;
      case "analysis":
        await analyzeMonthlySpending();
        break;
      case "planner":
        await createBudgetPlan(originalText);
        break;
      case "weekly":
        await generateWeeklyCoach();
        break;
      case "reset":
        await resetBudget();
        break;
      case "chat":
      default:
        final message = action["message"]?.toString().trim();
        final reply = await geminiService.sendMessage(
          message == null || message.isEmpty ? originalText : message,
        );
        setState(() {
          messages.add(
            MessageModel(
              text: reply,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
    }
  }

  String cleanAiJson(String response) {
    return response
        .replaceAll("```json", "")
        .replaceAll("```JSON", "")
        .replaceAll("```", "")
        .trim();
  }

  String normalizeCategory(dynamic rawCategory, [dynamic rawDescription]) {
    final category = rawCategory?.toString().trim().toLowerCase() ?? "";
    final description = rawDescription?.toString().trim().toLowerCase() ?? "";
    final combined = "$category $description";

    if (combined.contains("fuel") ||
        combined.contains("gasoline") ||
        combined.contains("petrol") ||
        combined.contains("gas station")) {
      return "Other";
    }

    switch (category) {
      case "food":
      case "meal":
      case "meals":
      case "restaurant":
      case "coffee":
        return "Food";
      case "transportation":
      case "transport":
      case "transit":
      case "bus":
      case "train":
      case "taxi":
      case "uber":
        return "Transportation";
      case "shopping":
        return "Shopping";
      case "entertainment":
        return "Entertainment";
      case "salary":
      case "income":
        return "Salary";
      case "other":
        return "Other";
      default:
        return "Other";
    }
  }

  bool isValidReceiptData(Map<String, dynamic> data) {
    final isReceipt = data["isReceipt"];
    final amount = double.tryParse(data["amount"]?.toString() ?? "") ?? 0;
    final type = data["type"]?.toString().toLowerCase() ?? "";

    if (isReceipt == false) return false;
    if (amount <= 0) return false;
    if (type != "expense" && type != "income") return false;
    return true;
  }

  DateTime parseTransactionDate(
    Map<String, dynamic> data, {
    String originalText = '',
  }) {
    final now = DateTime.now();
    final rawDate = data["date"] ??
        data["transactionDate"] ??
        data["createdAt"];

    DateTime? parseTextDate(String text) {
      final value = text.trim().toLowerCase();
      if (value.isEmpty) return null;

      if (value.contains('yesterday') ||
          text.contains('昨天')) {
        return now.subtract(const Duration(days: 1));
      }
      if (value.contains('today') || text.contains('今天')) {
        return now;
      }
      if (text.contains('前天')) {
        return now.subtract(const Duration(days: 2));
      }

      final iso = DateTime.tryParse(value);
      if (iso != null) return iso;

      final slashDate = RegExp(
        r'(\d{1,4})\s*[/-]\s*(\d{1,2})(?:\s*[/-]\s*(\d{1,4}))?',
      ).firstMatch(value);
      if (slashDate != null) {
        final first = int.tryParse(slashDate.group(1) ?? '');
        final second = int.tryParse(slashDate.group(2) ?? '');
        final third = int.tryParse(slashDate.group(3) ?? '');

        if (first != null && second != null) {
          if (first > 31) {
            return DateTime(first, second, third ?? now.day);
          }
          final year = third == null
              ? now.year
              : (third < 100 ? 2000 + third : third);
          return DateTime(year, first, second);
        }
      }

      final monthDay = RegExp(
        r'(\d{1,2})\s*月\s*(\d{1,2})\s*(?:日|號|号)?',
      ).firstMatch(text);
      if (monthDay != null) {
        final month = int.tryParse(monthDay.group(1) ?? '');
        final day = int.tryParse(monthDay.group(2) ?? '');
        if (month != null && day != null) {
          return DateTime(now.year, month, day);
        }
      }

      final dayOnlyMatches = RegExp(
        r'(?:^|[^\d])(\d{1,2})\s*(?:日|號|号)(?:$|[^\d])',
      ).allMatches(text).toList();
      if (dayOnlyMatches.isNotEmpty) {
        final day = int.tryParse(dayOnlyMatches.last.group(1) ?? '');
        if (day != null) {
          return DateTime(now.year, now.month, day);
        }
      }

      return null;
    }

    if (rawDate is DateTime) return rawDate;
    if (rawDate != null) {
      final parsed = parseTextDate(rawDate.toString());
      if (parsed != null) return parsed;
    }

    final parsedFromMessage = parseTextDate(originalText);
    return parsedFromMessage ?? now;
  }

  Future<void> recordExpenseFromAction(
    Map<String, dynamic> data, {
    String originalText = '',
  }) async {
    final amount = double.tryParse(data["amount"]?.toString() ?? "") ?? 0;

    if (amount <= 0) {
      setState(() {
        messages.add(
          MessageModel(
            text: "I couldn't find a valid transaction amount.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      return;
    }

    final transactionType = data["transactionType"]?.toString() ??
        data["type"]?.toString() ??
        "expense";

    final normalizedType = transactionType.toLowerCase() == "income"
        ? "income"
        : "expense";

    final transaction = TransactionModel(
      type: normalizedType,
      category: normalizeCategory(
        data["category"],
        data["description"],
      ),
      amount: amount,
      description: data["description"]?.toString().trim().isNotEmpty == true
          ? data["description"].toString()
          : "Transaction",
      createdAt: parseTransactionDate(data, originalText: originalText),
    );

    await transactionRepository.addTransaction(transaction);

    setState(() {
      messages.add(
        MessageModel(
          text: normalizedType == "income"
              ? "Income recorded."
              : "I've recorded your expense!",
          isUser: false,
          timestamp: DateTime.now(),
          card: ExpenseRecordedCard(
            description: transaction.description,
            amount: transaction.amount.toStringAsFixed(2),
            category: transaction.category,
            date:
                "${transaction.createdAt.month}/${transaction.createdAt.day}/${transaction.createdAt.year}",
          ),
        ),
      );
    });
  }

  String inferBudgetOperation(
    Map<String, dynamic> data, {
    String originalText = '',
  }) {
    final rawOperation = (data["operation"] ?? data["mode"] ?? data["action"])
        ?.toString()
        .trim()
        .toLowerCase();

    if (rawOperation == 'add' ||
        rawOperation == 'increase' ||
        rawOperation == 'increment') {
      return 'add';
    }

    if (rawOperation == 'reset' ||
        rawOperation == 'delete' ||
        rawOperation == 'clear') {
      return 'reset';
    }

    if (rawOperation == 'set' ||
        rawOperation == 'update' ||
        rawOperation == 'create') {
      return 'set';
    }

    final text = originalText.toLowerCase();

    if (text.contains('reset budget') ||
        text.contains('clear budget') ||
        text.contains('delete budget') ||
        originalText.contains('重設預算') ||
        originalText.contains('重置預算') ||
        originalText.contains('清空預算') ||
        originalText.contains('刪除預算') ||
        originalText.contains('删除预算')) {
      return 'reset';
    }

    if (text.contains('increase') ||
        text.contains('add to') ||
        text.contains('add ') ||
        text.contains('raise') ||
        text.contains('more') ||
        originalText.contains('增加') ||
        originalText.contains('加上') ||
        originalText.contains('多加') ||
        originalText.contains('提高') ||
        originalText.contains('調高') ||
        originalText.contains('调高')) {
      return 'add';
    }

    return 'set';
  }

  Future<void> recordBudgetFromAction(
    Map<String, dynamic> data, {
    String originalText = '',
  }) async {
    final operation = inferBudgetOperation(
      data,
      originalText: originalText,
    );

    if (operation == 'reset') {
      await resetBudget();
      return;
    }

    final limit = double.tryParse(data["limit"]?.toString() ?? "") ?? 0;

    if (limit <= 0) {
      setState(() {
        messages.add(
          MessageModel(
            text: "Please specify a budget amount greater than zero.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      return;
    }

    final now = DateTime.now();
    final budget = BudgetModel(
      category: normalizeCategory(data["category"] ?? "Other"),
      limit: limit,
      month: now.month,
      year: now.year,
    );

    if (operation == 'add') {
      await budgetRepository.incrementBudget(budget);
    } else {
      await budgetRepository.setBudget(budget);
    }

    final isAddOperation = operation == 'add';
    final title = isAddOperation ? "Budget Increased" : "Budget Saved";
    final message = isAddOperation
        ? "Added \$${budget.limit.toStringAsFixed(0)} to ${budget.category} budget."
        : "Budget saved: ${budget.category} \$${budget.limit.toStringAsFixed(0)}.";
    final amountFieldName = isAddOperation ? "Added" : "Limit";
    final fields = <String, String>{
      "Category": budget.category,
      amountFieldName: "\$${budget.limit.toStringAsFixed(0)}",
      "Month": "${now.month}/${now.year}",
    };

    setState(() {
      messages.add(
        MessageModel(
          text: message,
          isUser: false,
          timestamp: DateTime.now(),
          card: _buildInfoCard(
            icon: isAddOperation
                ? Icons.add_card_rounded
                : Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF00BFA6),
            bgColor: const Color(0xFFE0F7F4),
            borderColor: const Color(0xFF9ADFD6),
            title: title,
            fields: fields,
          ),
        ),
      );
    });
  }

  Future<void> recordReminderFromAction(Map<String, dynamic> data) async {
    final reminder = ReminderModel(
      title: data["title"]?.toString() ?? "Reminder",
      date: data["date"]?.toString() ?? "",
    );

    await reminderRepository.addReminder(reminder);

    setState(() {
      messages.add(
        MessageModel(
          text: "Reminder saved!",
          isUser: false,
          timestamp: DateTime.now(),
          card: _buildInfoCard(
            icon: Icons.notifications_active_rounded,
            iconColor: const Color(0xFFFF8F00),
            bgColor: const Color(0xFFFFF8E1),
            borderColor: const Color(0xFFFFE082),
            title: "Reminder Set",
            fields: {
              "Title": reminder.title,
              "Date": reminder.date,
            },
          ),
        ),
      );
    });
  }
 
  Future<void> createSavingPlanFromAction(
    Map<String, dynamic> action,
    String originalText,
  ) async {
    try {
      final goalText = action["goalText"]?.toString().trim().isNotEmpty == true
          ? action["goalText"].toString()
          : originalText;

      final transactions = await transactionRepository.fetchTransactions();
      final budgets = await budgetRepository.fetchBudgets();
      final habitResult = HabitAnalyzerService().analyzeSpendingHabits(
        transactions,
      );

      final transactionSummary = transactions.isEmpty
          ? "No past transactions."
          : transactions
              .take(30)
              .map(
                (t) =>
                    "${t.type} | ${t.category} | \$${t.amount.toStringAsFixed(2)} | ${t.description} | ${t.createdAt.month}/${t.createdAt.day}",
              )
              .join("\n");

      final budgetSummary = budgets.isEmpty
          ? "No budgets set."
          : budgets
              .map(
                (b) =>
                    "${b.category}: \$${b.limit.toStringAsFixed(0)} for ${b.month}/${b.year}",
              )
              .join("\n");

      String response = await geminiService.createSavingGoalPlan(
        userGoal: goalText,
        transactionSummary: transactionSummary,
        budgetSummary: budgetSummary,
        habitSummary: habitResult.toPromptText(),
      );

      response = cleanAiJson(response);
      final data = Map<String, dynamic>.from(jsonDecode(response));
      final plan = SavingPlanModel.fromMap(data);

      await savingPlanRepository.saveCurrentPlan(plan);

      setState(() {
        messages.add(
          MessageModel(
            text:
                "Saving goal plan saved. You can view it from the Analytics page.",
            isUser: false,
            timestamp: DateTime.now(),
            card: _buildInfoCard(
              icon: Icons.flag_rounded,
              iconColor: const Color(0xFF00BFA6),
              bgColor: const Color(0xFFE0F7F4),
              borderColor: const Color(0xFF9ADFD6),
              title: "Saving Goal Plan Saved",
              fields: {
                "Goal": plan.goalText.isEmpty ? goalText : plan.goalText,
                "Target": plan.targetAmount <= 0
                    ? "Not specified"
                    : "\$${plan.targetAmount.toStringAsFixed(0)}",
                "Timeframe": plan.timeframe,
              },
            ),
          ),
        );
      });
    } catch (e) {
      setState(() {
        messages.add(
          MessageModel(
            text: "Failed to create saving goal plan.\n$e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  Future<void> recordExpense(String text) async {
    try {
      String response = await geminiService.extractExpense(text);
      response = cleanAiJson(response);
      final data = Map<String, dynamic>.from(jsonDecode(response));
      await recordExpenseFromAction(data);
    } catch (e) {
      setState(() {
        messages.add(
          MessageModel(
            text: "Failed to record expense.\n$e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }


  Future<void> processReceipt() async {
    try {
      final image = await imageService.pickImage();

      if (image == null) return;

      setState(() {
        messages.add(
          MessageModel(
            text: "Receipt image selected. Reading receipt...",
            isUser: true,
            timestamp: DateTime.now(),
          ),
        );
        isLoading = true;
      });

      final imageBytes = await image.readAsBytes();

      String response = await geminiService.extractReceipt(imageBytes);
      response = cleanAiJson(response);

      final data = Map<String, dynamic>.from(jsonDecode(response));

      if (!isValidReceiptData(data)) {
        setState(() {
          messages.add(
            MessageModel(
              text:
                  "This image does not look like a valid receipt, so no transaction was recorded.",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        return;
      }

      await recordExpenseFromAction(data);
    } catch (e) {
      setState(() {
        messages.add(
          MessageModel(
            text: "Failed to read receipt.\n$e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


    Future<void> toggleVoiceInput() async {
      if (isListening) {
        await speechService.stopListening();
        if (!mounted) return;
        setState(() {
          isListening = false;
        });
        return;
      }

      final available = await speechService.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() {
              isListening = false;
            });
          }
        },
      );

      if (!available) {
        if (!mounted) return;
        setState(() {
          messages.add(
            MessageModel(
              text: "Speech recognition is not available on this device.",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        isListening = true;
      });

      await speechService.startListening(
        (recognizedText) {
          if (!mounted) return;
          setState(() {
            messageController.text = recognizedText;
          });
        },
      );
    }
    Future<void> setMonthlyBudget(String text) async {
      try {
        // 1. Extract total amount via Gemini
        String response = await geminiService.extractBudgetAmount(text);
        response = response
            .replaceAll("```json", "")
            .replaceAll("```JSON", "")
            .replaceAll("```", "")
            .trim();

        final data = jsonDecode(response);
        final double totalAmount = double.parse(data["amount"].toString());

        if (totalAmount <= 0) {
          setState(() {
            messages.add(MessageModel(
              text: "Please specify a budget amount greater than zero.",
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
          return;
        }

        // 2. Fetch recent transactions for smart allocation
        final transactions = await transactionRepository.fetchTransactions();
        final now = DateTime.now();

        // 3. Generate suggested allocation
        final allocationService = BudgetAllocationService();
        final suggestedBudgets = allocationService.suggestAllocation(
          totalAmount,
          now.month,
          now.year,
          recentTransactions: transactions,
        );

        // 4. Build allocations data for the card
        final allocations = suggestedBudgets.map((b) {
          return {
            'category': b.category,
            'amount': b.limit,
            'percent': totalAmount > 0
                ? (b.limit / totalAmount * 100)
                : 0.0,
          };
        }).toList();

        // 5. Show confirmation card
        setState(() {
          messages.add(MessageModel(
            text: "Here's a suggested budget breakdown for \$${totalAmount.toStringAsFixed(0)}/month. You can confirm or edit:",
            isUser: false,
            timestamp: DateTime.now(),
            card: BudgetAllocationCard(
              totalBudget: totalAmount.toStringAsFixed(0),
              allocations: allocations,
              onConfirm: () => _confirmBudget(suggestedBudgets, totalAmount),
              onEdit: () {
                setState(() {
                  messages.add(MessageModel(
                    text: "You can say things like 'Set food budget to \$300' to adjust individual categories.",
                    isUser: false,
                    timestamp: DateTime.now(),
                  ));
                });
              },
            ),
          ));
        });
      } catch (e) {
        setState(() {
          messages.add(MessageModel(
            text: "Failed to set budget. Please try again.\n$e",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    }

    void _confirmBudget(List<BudgetModel> allocations, double totalAmount) async {
      try {
        final now = DateTime.now();
        final budgetsWithMonth = allocations.map((b) => BudgetModel(
          category: b.category,
          limit: b.limit,
          month: now.month,
          year: now.year,
        )).toList();

        await budgetRepository.saveMonthlyBudgets(budgetsWithMonth);

        // Build the allocations data for the confirmed card
        final allocationsData = allocations.map((b) {
          return {
            'category': b.category,
            'amount': b.limit,
            'percent': totalAmount > 0
                ? (b.limit / totalAmount * 100)
                : 0.0,
          };
        }).toList();

        // Find the message with the BudgetAllocationCard and replace it
        setState(() {
          final cardIndex = messages.lastIndexWhere((m) => m.card is BudgetAllocationCard);
          if (cardIndex != -1) {
            final old = messages[cardIndex];
            messages[cardIndex] = MessageModel(
              text: old.text,
              isUser: old.isUser,
              timestamp: old.timestamp,
              card: BudgetAllocationCard(
                totalBudget: totalAmount.toStringAsFixed(0),
                allocations: allocationsData,
                isConfirmed: true,
              ),
            );
          }

          // Add the success message
          messages.add(MessageModel(
            text: "Budget set! Your \$${totalAmount.toStringAsFixed(0)}/month allocation has been saved.",
            isUser: false,
            timestamp: DateTime.now(),
            card: _buildInfoCard(
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF2E7D32),
              bgColor: const Color(0xFFE8F5E9),
              borderColor: const Color(0xFFA5D6A7),
              title: "Budget Confirmed",
              fields: {
                "Total": "\$${totalAmount.toStringAsFixed(2)}",
                "Categories": "${allocations.length} categories",
                "Month": "${now.month}/${now.year}",
              },
            ),
          ));
        });
      } catch (e) {
        setState(() {
          messages.add(MessageModel(
            text: "Failed to save budget.\n$e",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    }

    Future<void> resetBudget() async {
      try {
        final deleted = await budgetRepository.deleteAllBudgets();

        setState(() {
          messages.add(MessageModel(
            text: deleted > 0
                ? "Budget reset! Deleted $deleted budget categories."
                : "No budget found. Say \"Set budget \$2000\" to create one.",
            isUser: false,
            timestamp: DateTime.now(),
            card: deleted > 0
                ? _buildInfoCard(
                    icon: Icons.delete_sweep_rounded,
                    iconColor: const Color(0xFFE53935),
                    bgColor: const Color(0xFFFFEBEE),
                    borderColor: const Color(0xFFEF9A9A),
                    title: "Budget Reset",
                    fields: {
                      "Deleted": "$deleted categories",
                    },
                  )
                : null,
          ));
        });
      } catch (e) {
        setState(() {
          messages.add(MessageModel(
            text: "Failed to reset budget.\n$e",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    }

    Future<void> recordReminder(String text) async {
      try {
        String response = await geminiService.extractReminder(text);
        response = response
            .replaceAll("```json", "")
            .replaceAll("```JSON", "")
            .replaceAll("```", "")
            .trim();

        final data = jsonDecode(response);
        final reminder = ReminderModel(
          title: data["title"],
          date: data["date"],
        );

        await reminderRepository.addReminder(reminder);

        setState(() {
          messages.add(
            MessageModel(
              text: "Reminder saved!",
              isUser: false,
              timestamp: DateTime.now(),
              card: _buildInfoCard(
                icon: Icons.notifications_active_rounded,
                iconColor: const Color(0xFFFF8F00),
                bgColor: const Color(0xFFFFF8E1),
                borderColor: const Color(0xFFFFE082),
                title: "Reminder Set",
                fields: {
                  "Title": reminder.title,
                  "Date": reminder.date,
                },
              ),
            ),
          );
        });
      } catch (e) {
        setState(() {
          messages.add(
            MessageModel(
              text: "Failed to save reminder. Please try again.\n$e",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    }

  Future<void> analyzeMonthlySpending() async {

    try {

      final transactions =
          await transactionRepository
              .fetchTransactions();

      double total = 0;

      final Map<String, double> categories = {};

      for (final t in transactions) {

        if (t.type == "expense") {
          total += t.amount;

          categories[t.category] =
              (categories[t.category] ?? 0)
                  + t.amount;
        }

      }

      final now = DateTime.now();
      final budgets =
          await budgetRepository.fetchBudgetsForMonth(
              now.month, now.year);

      String summary =
          "Total spending: \$${total.toStringAsFixed(2)}\n";

      if (budgets.isNotEmpty) {
        summary += "Budget allocations:\n";
        for (final b in budgets) {
          summary +=
              "  ${b.category}: \$${b.limit.toStringAsFixed(0)} allocated\n";
        }
      }

      summary += "Category breakdown:\n";
      categories.forEach(
        (key, value) {
          final budgeted = budgets.firstWhere(
            (b) => b.category == key,
            orElse: () => BudgetModel(
                category: key, limit: 0),
          );
          final remaining = budgeted.limit - value;
          summary +=
              "  $key: \$${value.toStringAsFixed(2)} spent";
          if (budgeted.limit > 0) {
            summary +=
                " / \$${budgeted.limit.toStringAsFixed(0)} budget (\$${remaining.toStringAsFixed(0)} remaining)";
          }
          summary += "\n";
        },
      );

      final reply =
          await geminiService
              .analyzeSpending(summary);

      setState(() {

        messages.add(
          MessageModel(
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );

      });

    } catch (e) {

      setState(() {
        messages.add(
          MessageModel(
            text: "Failed to analyze spending.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });

    }

  }

  Future<void> createBudgetPlan(
      String text) async {

    try {

      final transactions =
          await transactionRepository
              .fetchTransactions();

      final profile =
          HabitAnalyzerService()
              .analyze(transactions);

      final summary = """

  Weekday budget:

  ${profile.weekdayBudget}

  Weekend budget:

  ${profile.weekendBudget}

  Wake hour:

  ${profile.wakeHour}

  Sleep hour:

  ${profile.sleepHour}

  """;

      final reply =
          await geminiService
              .createBudgetPlan(
                  text,
                  summary);

      setState(() {

        messages.add(
          MessageModel(
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );

      });

    } catch (e) {

      setState(() {

        messages.add(
          MessageModel(
            text:
                "Failed to create budget plan.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );

      });

    }
  }

  Future<void> generateWeeklyCoach() async {
    try {
      final dateService = await DateOverrideService.getInstance();
      final now = dateService.now();
      final daysFromMonday = now.weekday - 1;
      final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysFromMonday));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final transactions = await transactionRepository.fetchTransactions();
      final weekTransactions = transactions.where((t) =>
        t.createdAt.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
        t.createdAt.isBefore(weekEnd.add(const Duration(days: 1)))
      ).toList();

      final snapshotRepo = WeeklySnapshotRepository();
      final existingSnapshots = await snapshotRepo.fetchSnapshots();

      final currentSnapshot = WeeklySnapshotModel.fromTransactions(
        weekStart: weekStart,
        weekEnd: weekEnd,
        transactions: weekTransactions.map((t) =>
          TransactionData(amount: t.amount, category: t.category, date: t.createdAt)
        ).toList(),
      );

      await snapshotRepo.saveSnapshot(currentSnapshot);

      final allSnapshots = [currentSnapshot, ...existingSnapshots];
      final analyzer = SpendingAnalyzerService();
      final trends = analyzer.analyze(allSnapshots);

      final buffer = StringBuffer();
      buffer.writeln("=== Spending History (${allSnapshots.length} weeks) ===\n");

      for (final s in allSnapshots.take(6)) {
        buffer.writeln("Week of ${s.weekStart.month}/${s.weekStart.day}: \$${s.totalSpent.toStringAsFixed(2)} (${s.transactionCount} transactions)");
        final cats = s.categoryBreakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        for (final c in cats.take(3)) {
          buffer.writeln("  ${c.key}: \$${c.value.toStringAsFixed(2)}");
        }
        buffer.writeln();
      }

      buffer.writeln("=== Trends ===");
      if (trends.weekOverWeekChange != null) {
        final change = trends.weekOverWeekChange!;
        buffer.writeln("Week-over-week: ${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%");
      }
      buffer.writeln("Average weekly: \$${trends.averageWeeklySpending.toStringAsFixed(2)}");
      buffer.writeln("Savings streak: ${trends.savingsStreak} weeks");
      if (trends.peakDay != null) buffer.writeln("Peak spending day: ${trends.peakDay}");
      buffer.writeln("Consistency score: ${trends.spendingConsistency.toStringAsFixed(1)}% variation");

      if (trends.categoryTrends.isNotEmpty) {
        buffer.writeln("\nCategory trends:");
        for (final entry in trends.categoryTrends.entries) {
          final arrow = entry.value > 0 ? '↑' : '↓';
          buffer.writeln("  ${entry.key}: ${arrow}${entry.value.abs().toStringAsFixed(1)}%");
        }
      }

      final contextStr = buffer.toString();
      final reply = await geminiService.weeklyReflection(contextStr);

      setState(() {
        messages.add(MessageModel(
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      setState(() {
        messages.add(MessageModel(
          text: "Failed to generate weekly coaching insight.\n$e",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  @override
  void dispose() {
    speechService.stopListening();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
  child: Column(
    children: [
      const ChatHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return ChatBubble(
                            message: "Thinking...",
                            isUser: false,
                            timestamp: DateTime.now(),
                          );
                        }

                        final message = messages[index];

                        return ChatBubble(
                          message: message.text,
                          isUser: message.isUser,
                          timestamp: message.timestamp,
                          card: message.card,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  MessageInput(
                    controller: messageController,
                    onSend: sendMessage,
                    onAttachImage: processReceipt,
                    onVoiceInput: toggleVoiceInput,
                    isListening: isListening,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required Map<String, String> fields,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...fields.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                Text(
                  entry.value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}