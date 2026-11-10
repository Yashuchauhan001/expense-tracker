import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A86B))),
      home: const ExpensePage(),
    );
  }
}

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});
  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  List<Map<String, dynamic>> transactions = [];
  TextEditingController titleController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  String selectedType = "Expense";
  String selectedCategory = "Food";
  List<String> categories = ["Food", "Shopping", "Travel", "Bills", "Salary", "Other"];

  // New Colors
  final Color primaryGreen = const Color(0xFF00A86B);
  final Color darkGreen = const Color(0xFF0B3D2E);
  final Color lightBg = const Color(0xFFE6F4EA);

  @override
  void initState() { super.initState(); loadData(); }
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('expenses');
    if (data!= null) setState(() => transactions = List<Map<String, dynamic>>.from(jsonDecode(data)));
  }
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('expenses', jsonEncode(transactions));
  }
  double get totalIncome => transactions.where((e) => e['type'] == 'Income').fold(0.0, (sum, item) => sum + (item['amount'] as double));
  double get totalExpense => transactions.where((e) => e['type'] == 'Expense').fold(0.0, (sum, item) => sum + (item['amount'] as double));
  double get balance => totalIncome - totalExpense;

  void addTransaction() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Add Transaction'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title', border: const OutlineInputBorder(), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryGreen)))),
              const SizedBox(height: 10),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Amount', prefixText: '₹ ', border: const OutlineInputBorder(), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryGreen)))),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(value: selectedType, items: ["Income", "Expense"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setDialogState(() => selectedType = val!), decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Type')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(value: selectedCategory, items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setDialogState(() => selectedCategory = val!), decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Category')),
            ],
            ),
          ),
          actions: [
            TextButton(onPressed: () { titleController.clear(); amountController.clear(); Navigator.pop(context); }, child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white),
              onPressed: () {
                if (titleController.text.isEmpty || amountController.text.isEmpty) return;
                setState(() { transactions.add({'title': titleController.text, 'amount': double.tryParse(amountController.text)?? 0, 'type': selectedType, 'category': selectedCategory, 'date': DateFormat('dd MMM yyyy').format(DateTime.now())}); });
                saveData(); titleController.clear(); amountController.clear(); Navigator.pop(context);
              },
              child: const Text('Add'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(title: const Text('Expense Tracker', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, backgroundColor: darkGreen, foregroundColor: Colors.white, elevation: 0),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [darkGreen, primaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))]
            ),
            child: Column(children: [
              const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
              Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(children: [const Row(children: [Icon(Icons.arrow_upward, color: Colors.white, size: 18), Text(' Income', style: TextStyle(color: Colors.white70))]), Text('₹${totalIncome.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))]),
                    Container(width: 1, height: 40, color: Colors.white24),
                    Column(children: [const Row(children: [Icon(Icons.arrow_downward, color: Colors.white, size: 18), Text(' Expense', style: TextStyle(color: Colors.white70))]), Text('₹${totalExpense.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))]),
                  ],
                  ))
            ],
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text('No transactions yet!\nTap + to add', textAlign: TextAlign.center))
                : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                var t = transactions[index];
                bool isIncome = t['type'] == 'Income';
                return Card(
                  color: Colors.white, elevation: 2, margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: isIncome? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), child: Icon(isIncome? Icons.trending_up : Icons.trending_down, color: isIncome? primaryGreen : Colors.red)),
                    title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${t['category']} • ${t['date']}'),
                    trailing: Text('${isIncome? '+' : '-'}₹${t['amount']}', style: TextStyle(fontWeight: FontWeight.bold, color: isIncome? primaryGreen : Colors.red, fontSize: 16)),
                    onLongPress: () { setState(() => transactions.removeAt(index)); saveData(); },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: addTransaction, backgroundColor: darkGreen, icon: const Icon(Icons.add, color: Colors.white), label: const Text('Add New', style: TextStyle(color: Colors.white))),
    );
  }
}