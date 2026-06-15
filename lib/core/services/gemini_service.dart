import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import 'dart:convert';

class GeminiService {
  late final GenerativeModel? _model;
  final bool isAvailable;

  GeminiService()
      : isAvailable = dotenv.env["GEMINI_API_KEY"] != null &&
            dotenv.env["GEMINI_API_KEY"]!.isNotEmpty {
    if (isAvailable) {
      try {
        _model = GenerativeModel(
          model: "gemini-2.5-flash",
          apiKey: dotenv.env["GEMINI_API_KEY"]!,
        );
      } catch (_) {
        _model = null;
      }
    } else {
      _model = null;
    }
  }

  String get _unavailableMsg =>
      "AI assistant is not configured. Please add your GEMINI_API_KEY to the .env file.";

  String _cleanJson(String value) {
    return value
        .replaceAll("```json", "")
        .replaceAll("```JSON", "")
        .replaceAll("```", "")
        .trim();
  }

  Future<List<Map<String, dynamic>>> planActions(String userMessage) async {
    if (_model == null) {
      return [
        {"type": "chat", "message": userMessage}
      ];
    }

    final prompt = """
You are the action planner for an AI finance assistant app.

Convert the user's message into a list of executable actions.

Supported action types:
- expense: record a transaction expense or income
- budget: set a category budget to a specific amount or add an amount to an existing category budget
- saving_plan: create or update the user's long-term saving goal plan
- reminder: save a reminder
- analysis: analyze spending or generate financial insight
- planner: create a budget plan from habits
- weekly: generate weekly coaching insight
- reset: delete/reset current monthly budget
- chat: normal conversation when no finance action is needed

Return ONLY valid JSON in this exact structure:
{
  "actions": [
    {"type":"expense","transactionType":"expense","category":"Food","amount":120,"description":"Lunch","date":"2026-06-14"},
    {"type":"budget","operation":"set","category":"Food","limit":3000},
    {"type":"budget","operation":"add","category":"Food","limit":500},
    {"type":"saving_plan","goalText":"Save 5000 in three months"},
    {"type":"analysis"},
    {"type":"chat","message":"..."}
  ]
}

Rules:
- If the user asks multiple things, return multiple actions in the same order.
- Do not collapse compound instructions into only one action.
- Budget requests may be written as "set budget", "add budget", "increase budget", "reset budget", "新增預算", "設定預算", "調整預算", "增加預算", or "重設預算".
- If the user asks to set/create a budget amount but does not specify a category, create a budget action with category "Other" and operation "set". Do NOT turn it into chat.
- For budget actions, always include an "operation" field: "set" means replace the category budget with the amount; "add" means increase the existing category budget by the amount.
- Use operation "add" only for phrases like "add to budget", "increase budget by", "多加", "加上", "增加", "提高", or "調高".
- Use operation "set" for phrases like "set to", "change to", "設定成", "設為", "改成", "調成", "調低到", or "新增預算".
- If the user asks to reset/clear/delete budgets, return a reset action instead of a budget action.
- For budget actions, choose the amount that belongs to the budget request. If the message also includes an expense amount, do not use the expense amount as the budget limit.
- Saving plan requests may be written as "saving plan", "saving goal", "制定計畫", "幫我做計畫", "存錢計畫", "省錢計畫", "消費目標", "我想省", or "我想存". Do NOT turn these into chat.
- If the user asks for financial insight, spending insight, analysis, 分析, 洞察, or 建議, create an analysis action. Do NOT turn it into chat.
- For expense actions, use "transactionType" as either "expense" or "income".
- If the user specifies a transaction date, include a "date" field in YYYY-MM-DD format.
- Relative dates should be resolved using today as the current date: today = ${DateTime.now().toIso8601String().split('T').first}.
- Examples: "昨天" means yesterday, "今天" means today, "14號" means the 14th day of the current month, and "6/14" means June 14 of the current year.
- Allowed categories: Food, Transportation, Shopping, Entertainment, Salary, Other.
- Do NOT create categories such as Fuel, Gas, Utilities, Health, Rent, Education.
- Fuel, petrol, gasoline, gas station should be Other.
- If an action needs an amount but the amount is unclear, do not create that action; create a chat action asking for clarification.
- If the message is normal conversation, return one chat action.

Examples:
User: I spent 120 on lunch and set my Food budget to 3000
Output:
{"actions":[{"type":"expense","transactionType":"expense","category":"Food","amount":120,"description":"Lunch"},{"type":"budget","operation":"set","category":"Food","limit":3000}]}

User: 午餐 450，新增預算 5000
Output:
{"actions":[{"type":"expense","transactionType":"expense","category":"Food","amount":450,"description":"Lunch"},{"type":"budget","operation":"set","category":"Other","limit":5000}]}

User: 14號午餐 200
Output:
{"actions":[{"type":"expense","transactionType":"expense","category":"Food","amount":200,"description":"Lunch","date":"${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-14"}]}

User: 幫我設一個三個月省 5000 元的計畫，然後把食物預算調低到 3000
Output:
{"actions":[{"type":"saving_plan","goalText":"三個月省 5000 元"},{"type":"budget","operation":"set","category":"Food","limit":3000}]}

User: 午餐 200，幫我制定計畫
Output:
{"actions":[{"type":"expense","transactionType":"expense","category":"Food","amount":200,"description":"Lunch"},{"type":"saving_plan","goalText":"午餐 200，幫我制定計畫"}]}

User: 幫我把 Food 預算增加 500
Output:
{"actions":[{"type":"budget","operation":"add","category":"Food","limit":500}]}

User: reset budget
Output:
{"actions":[{"type":"reset"}]}

User message:
$userMessage
""";

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final raw = _cleanJson(response.text ?? "");
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic> && decoded["actions"] is List) {
        return (decoded["actions"] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}

    return [
      {"type": "chat", "message": userMessage}
    ];
  }

  Future<String> sendMessage(String message) async {
    if (_model == null) return _unavailableMsg;
    final response = await _model!.generateContent([Content.text(message)]);
    return response.text ?? "";
  }

  Future<String> extractExpense(String userMessage) async {
    if (_model == null) return _unavailableMsg;

    final prompt = """
You are an AI financial assistant.
Extract transaction information from the user's message.
Return ONLY valid JSON.
Schema:
{"type":"expense","category":"Food","amount":0,"description":""}

Allowed categories: Food, Transportation, Shopping, Entertainment, Salary, Other.
You MUST choose exactly one category from the allowed list.
Do NOT create new categories such as Fuel, Gas, Utilities, Health, Rent, or Education.
Gasoline, petrol, fuel, and gas station should be categorized as Other.
Salary or income should use type "income" and category "Salary".

User message:
$userMessage
""";

    final response = await _model!.generateContent([Content.text(prompt)]);
    return response.text ?? "";
  }

  Future<String> detectIntent(String userMessage) async {
    if (_model == null) return "chat";
    final actions = await planActions(userMessage);
    if (actions.isEmpty) return "chat";
    return actions.first["type"]?.toString().toLowerCase() ?? "chat";
  }

  Future<String> extractBudgetAmount(String userMessage) async {
    if (_model == null) return _unavailableMsg;
    final prompt = """
Extract the total monthly budget amount from the user's message.
Return ONLY valid JSON.
Schema: {"amount": 0}
User message:
$userMessage
""";
    final response = await _model!.generateContent([Content.text(prompt)]);
    return response.text ?? "";
  }

  Future<String> extractBudget(String userMessage) async {
    if (_model == null) return _unavailableMsg;

    final prompt = """
You are an AI financial assistant.
Extract the budget information from the user's message.
Return ONLY valid JSON.
Schema: {"category":"","limit":0,"operation":"set"}

Allowed categories: Food, Transportation, Shopping, Entertainment, Other.
Rules:
- Use exactly one category from the allowed list.
- If the user says food, meals, lunch, dinner, breakfast, restaurant, coffee, 食物, 餐飲, 午餐, 晚餐, 早餐, use Food.
- If the user says transport, bus, train, taxi, MRT, Uber, 交通, use Transportation.
- If the user says shopping, clothes, online shopping, 購物, use Shopping.
- If the user says entertainment, movie, game, 娛樂, use Entertainment.
- If the user asks to add/set a budget but does not specify a category, use Other.
- Always include operation: use "set" to replace the budget amount, and "add" to increase the existing budget by this amount.
- Use operation "add" only when the user says increase/add/more/加上/增加/多加/提高/調高.
- Use operation "set" when the user says set/change to/新增預算/設定成/改成/調成/調低到.
- If the message also contains a transaction amount, choose the amount that belongs to the budget request, not the transaction amount.

Examples:
User: Set my Food budget to 3000
Output: {"category":"Food","limit":3000,"operation":"set"}
User: 午餐 450，新增預算 5000
Output: {"category":"Other","limit":5000,"operation":"set"}

User: 幫我把 Food 預算增加 500
Output: {"category":"Food","limit":500,"operation":"add"}

User message:
$userMessage
""";

    final response = await _model!.generateContent([Content.text(prompt)]);
    return response.text ?? "";
  }

  Future<String> extractReminder(String userMessage) async {
    if (_model == null) return _unavailableMsg;

    final prompt = """
Return ONLY JSON.
Schema: {"title":"","date":""}
User message:
$userMessage
""";

    final response = await _model!.generateContent([Content.text(prompt)]);
    return response.text ?? "";
  }

  Future<String> extractReceipt(Uint8List imageBytes) async {
    if (_model == null) return _unavailableMsg;

    const prompt = """
You are an AI financial assistant.
Analyze the image and decide whether it is a real purchase receipt, invoice, or transaction proof.
Return ONLY valid JSON.
Schema:
{"isReceipt":true,"type":"expense","category":"Other","amount":0,"description":""}

Allowed categories: Food, Transportation, Shopping, Entertainment, Salary, Other.
You MUST choose exactly one category from the allowed list.
Do NOT create new categories such as Fuel, Gas, Utilities, Health, Rent, or Education.
If the receipt does not clearly fit Food, Transportation, Shopping, Entertainment, or Salary, use Other.
Gasoline, petrol, fuel, and gas station receipts should be categorized as Other.

If the image is NOT a receipt, invoice, or transaction proof, return exactly:
{"isReceipt":false,"type":"","category":"Other","amount":0,"description":"Not a receipt"}

Do NOT guess an amount from non-receipt images.
Do NOT return amount 0 for a valid receipt. If no valid total amount can be found, set "isReceipt" to false.
""";

    final response = await _model!.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart("image/jpeg", imageBytes),
      ]),
    ]);

    return response.text ?? "";
  }

  Future<String> createSavingGoalPlan({
    required String userGoal,
    required String transactionSummary,
    required String budgetSummary,
    required String habitSummary,
  }) async {
    if (_model == null) return _unavailableMsg;
    final prompt = """
You are an AI financial planning assistant.
The user wants to create a long-term saving goal plan. Use the user's goal, past transactions, budgets, and spending habits to create a practical plan.
Return ONLY valid JSON in this exact structure:
{
  "goalText":"",
  "targetAmount":0,
  "timeframe":"",
  "planSummary":"",
  "weeklyTarget":"",
  "focusCategories":"",
  "actionSteps":""
}
Rules:
- Do not wrap the JSON in markdown code fences.
- targetAmount must be a number. If the user did not give a number, use 0.
- Use the user's actual past spending patterns when possible.

User saving goal:
$userGoal
Past transaction summary:
$transactionSummary
Current budget summary:
$budgetSummary
Detected habits:
$habitSummary
""";

    final response = await _model!.generateContent([Content.text(prompt)]);
    return response.text ?? "";
  }

  Future<String> analyzeSpending(String summary) async {
    if (_model == null) return _unavailableMsg;
    final prompt = """
You are a personal finance advisor for a student.
Analyze the user's spending summary WITH budget and saving goal context.
Give concise, specific, actionable advice.
Information:
$summary
""";
    final response = await _model!.generateContent([Content.text(prompt)]);
    return response.text ?? "";
  }

  Future<String> weeklyReflection(String weeklySummary) async {
    if (_model == null) return _unavailableMsg;
    final prompt = """
You are an AI financial coach. Analyze the user's weekly spending.
Provide good habits, problems, and suggestions.
Weekly spending:
$weeklySummary
""";
    final response = await _model!.generateContent([Content.text(prompt)]);
    return response.text ?? "";
  }

  Future<String> createBudgetPlan(String income, String habitSummary) async {
    if (_model == null) return _unavailableMsg;
    final prompt = """
You are an AI financial advisor.
The user has monthly income:
$income
User habits:
$habitSummary
Create practical recommendations for weekday budget, weekend budget, savings target, and emergency reserve.
""";
    final response = await _model!.generateContent([Content.text(prompt)]);
    return response.text ?? "";
  }

  Future<String> generateNotification(String summary) async {
    if (_model == null) return _unavailableMsg;
    final prompt = """
Generate a short financial notification. Keep it friendly.
Information:
$summary
""";
    final response = await _model!.generateContent([Content.text(prompt)]);
    return response.text ?? "";
  }
}
