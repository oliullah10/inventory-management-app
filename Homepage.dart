import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventory/helper/InventoryStatsBox.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userRole = '';
  int totalProducts = 0;
  bool isLoading = true;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }
    final uid = currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final productSnapshot = await FirebaseFirestore.instance.collection('products').get();

    setState(() {
      userRole = userDoc['role'] ?? '';
      totalProducts = productSnapshot.size;
      isLoading = false;
    });
  }

  void _logout() async {
    Navigator.of(context).pop();
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: Text('Do you want to logout from ${currentUser?.email ?? 'your account'}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _logout,
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "GRH Online",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            InventoryStatsBox(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: _buildDashboardCards(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDashboardCards() {
    List<Widget> cards = [];

    cards.add(_dashboardCard("View Products", Icons.inventory, () {
      Navigator.pushNamed(context, '/products');
    }));
    cards.add(_dashboardCard("Sell Product", Icons.shopping_cart, () {
      Navigator.pushNamed(context, '/sellProduct');
    }));

    if (userRole == 'admin' || userRole == 'manager') {
      cards.add(_dashboardCard("Add Product", Icons.add_box, () {
        Navigator.pushNamed(context, '/addProduct');
      }));
    }

    if (userRole == 'admin') {
      cards.add(_dashboardCard("View Income", Icons.attach_money, () {
        Navigator.pushNamed(context, '/income');
      }));

      cards.add(_dashboardCard("View Expense", Icons.money_off, () {
        Navigator.pushNamed(context, '/expense');
      }));
    }

    return cards;
  }

  Widget _dashboardCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.black),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
