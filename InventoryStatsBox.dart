import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventoryStatsBox extends StatefulWidget {
  const InventoryStatsBox({Key? key}) : super(key: key);

  @override
  State<InventoryStatsBox> createState() => _InventoryStatsBoxState();
}

class _InventoryStatsBoxState extends State<InventoryStatsBox> {
  int totalProducts = 0;
  int totalStock = 0;
  int lowStock = 0;
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  bool isLoading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    checkUserRoleAndFetchData();
  }

  Future<void> checkUserRoleAndFetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData != null && userData['role'] == 'admin') {
        setState(() {
          isAdmin = true;
        });
        await fetchInventoryStats();
      } else {
        setState(() {
          isAdmin = false;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking role: $e');
      setState(() {
        isLoading = false;
        isAdmin = false;
      });
    }
  }

  Future<void> fetchInventoryStats() async {
    try {
      final productsSnapshot = await FirebaseFirestore.instance.collection('products').get();
      final salesSnapshot = await FirebaseFirestore.instance.collection('sales').get();
      final expenseSnapshot = await FirebaseFirestore.instance.collection('expense').get();

      int stockSum = 0;
      int lowStockCount = 0;

      for (var doc in productsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        int qty = 0;
        if (data['quantity'] != null) {
          if (data['quantity'] is int) qty = data['quantity'];
          else qty = int.tryParse(data['quantity'].toString()) ?? 0;
        }

        stockSum += qty;
        if (qty < 5) lowStockCount++;
      }

      double incomeSum = 0.0;
      for (var saleDoc in salesSnapshot.docs) {
        final saleData = saleDoc.data() as Map<String, dynamic>;
        if (saleData['total'] != null) {
          final val = saleData['total'];
          if (val is int) incomeSum += val.toDouble();
          else if (val is double) incomeSum += val;
          else incomeSum += double.tryParse(val.toString()) ?? 0.0;
        }
      }

      double expenseSum = 0.0;
      for (var expDoc in expenseSnapshot.docs) {
        final expData = expDoc.data() as Map<String, dynamic>;
        if (expData['amount'] != null) {
          final val = expData['amount'];
          if (val is int) expenseSum += val.toDouble();
          else if (val is double) expenseSum += val;
          else expenseSum += double.tryParse(val.toString()) ?? 0.0;
        }
      }

      setState(() {
        totalProducts = productsSnapshot.size;
        totalStock = stockSum;
        lowStock = lowStockCount;
        totalIncome = incomeSum;
        totalExpense = expenseSum;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching stats: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!isAdmin) {
      return const Center(
        child: Text(''),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchInventoryStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _statCard('Total Products', totalProducts.toString(), Icons.inventory, Colors.deepPurple),
                _statCard('Total Stock', totalStock.toString(), Icons.storage, Colors.teal),
                _statCard('Low Stock (<5)', lowStock.toString(), Icons.warning_amber, Colors.orange),
                _statCard('Total Income', '৳${totalIncome.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
                _statCard('Total Expense', '৳${totalExpense.toStringAsFixed(2)}', Icons.money_off, Colors.redAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
