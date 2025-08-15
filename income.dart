import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
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
        title: const Text("Income Report"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('income')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allIncomeDocs = snapshot.data!.docs;

          
          final filteredIncome = allIncomeDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['date'] as Timestamp?;
            if (timestamp == null) return false;
            final date = timestamp.toDate();
            return date.month == selectedMonthIndex;
          }).toList();

          double monthlyIncome = 0;
          for (var doc in filteredIncome) {
            monthlyIncome += (doc['total'] as num).toDouble();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Colors.deepPurple,
                padding: const EdgeInsets.all(16),
                width: double.infinity,
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
                      'Total Income in $selectedMonth',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳ ${monthlyIncome.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Income History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: filteredIncome.isEmpty
                    ? const Center(child: Text("No income for this month"))
                    : ListView.builder(
                        itemCount: filteredIncome.length,
                        itemBuilder: (context, index) {
                          final data = filteredIncome[index];
                          final date = (data['date'] as Timestamp).toDate();
                          final formattedDate =
                              DateFormat('dd MMM yyyy, hh:mm a').format(date);
                          return ListTile(
                            leading: const Icon(Icons.monetization_on, color: Colors.green),
                            title: Text(
                                '${data['productName']} - ৳${data['total'].toStringAsFixed(2)}'),
                            subtitle:
                                Text('Qty: ${data['quantity']}  •  $formattedDate'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
