import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory/helper/AddExpenseDialog.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  String selectedMonth = DateFormat('MMMM').format(DateTime.now()); 
  int selectedMonthIndex = DateTime.now().month;

  final List<String> months = List.generate(
    12,
    (index) => DateFormat('MMMM').format(DateTime(0, index + 1)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expense Details"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expense')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allExpenses = snapshot.data!.docs;

         
          final filteredExpenses = allExpenses.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['date'] as Timestamp?;
            if (timestamp == null) return false;
            final date = timestamp.toDate();
            return date.month == selectedMonthIndex;
          }).toList();

          // Total of selected month
          double monthlyTotal = 0;
          for (var doc in filteredExpenses) {
            monthlyTotal += (doc['amount'] as num).toDouble();
          }

          return Column(
            children: [
              // Month selector dropdown
              Container(
                width: double.infinity,
                color: Colors.deepPurple,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Month',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedMonth,
                      dropdownColor: Colors.deepPurple,
                      iconEnabledColor: Colors.white,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      underline: Container(height: 1, color: Colors.white),
                      items: months.map((month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text(month),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMonth = value!;
                          selectedMonthIndex = months.indexOf(value) + 1;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Total Expense in $selectedMonth',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳ ${monthlyTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Expense list
              Expanded(
                child: filteredExpenses.isEmpty
                    ? const Center(child: Text("No expenses for this month"))
                    : ListView.builder(
                        itemCount: filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final data = filteredExpenses[index];
                          final date = (data['date'] as Timestamp).toDate();
                          final formattedDate = DateFormat('dd MMM yyyy').format(date);
                          return ListTile(
                            leading: const Icon(Icons.money_off, color: Colors.red),
                            title: Text('${data['productName']} - ৳${data['amount']}'),
                            subtitle: Text('${data['note']} • $formattedDate'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddExpenseDialog(),
        ),
        child: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
