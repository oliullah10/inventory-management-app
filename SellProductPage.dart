import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellProductPage extends StatefulWidget {
  const SellProductPage({super.key});

  @override
  State<SellProductPage> createState() => _SellProductPageState();
}

class _SellProductPageState extends State<SellProductPage> {
  String? selectedProductId;
  Map<String, dynamic>? selectedProductData;

  final TextEditingController _sellQtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool isLoading = false;

  Future<void> _sellProduct() async {
  print(' Sell button pressed');

  if (selectedProductId == null ||
      _sellQtyController.text.isEmpty ||
      _priceController.text.isEmpty) {
    print(' Missing required fields');
    return;
  }

  final sellQty = int.tryParse(_sellQtyController.text.trim());
  final pricePerUnit = double.tryParse(_priceController.text.trim());
  final note = _noteController.text.trim();

  print('🧮 Parsed values -> Qty: $sellQty, Price per unit: $pricePerUnit');

  if (sellQty == null ||
      sellQty <= 0 ||
      pricePerUnit == null ||
      pricePerUnit < 0 ||
      sellQty > (selectedProductData?['quantity'] ?? 0)) {
    print(' Invalid input or insufficient stock');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(' Invalid input or insufficient stock')),
    );
    return;
  }

  setState(() => isLoading = true);

  try {
    final total = sellQty * pricePerUnit;
    final soldBy = FirebaseAuth.instance.currentUser?.email ?? "Unknown";

    print('Sold By: $soldBy');
    print('Product ID: $selectedProductId');
    print('Product Name: ${selectedProductData?['name']}');
    print('New Quantity: ${(selectedProductData?['quantity'] ?? 0) - sellQty}');
    print('Total Sold: ${(selectedProductData?['totalSold'] ?? 0) + sellQty}');
    print('Total Sale Amount: $total');

    final productRef =
        FirebaseFirestore.instance.collection('products').doc(selectedProductId);

    await productRef.update({
      'quantity': (selectedProductData?['quantity'] ?? 0) - sellQty,
      'totalSold': (selectedProductData?['totalSold'] ?? 0) + sellQty,
      'lastSoldDate': Timestamp.now(),
    });

    print('Product updated successfully in Firestore');

    await FirebaseFirestore.instance.collection('sales').add({
      'productId': selectedProductId,
      'productName': selectedProductData!['name'],
      'quantity': sellQty,
      'pricePerUnit': pricePerUnit,
      'total': total,
      'note': note,
      'soldBy': soldBy,
      'date': Timestamp.now(),
    });

    print('Sale saved to Firestore');

    await FirebaseFirestore.instance.collection('income').add({
      'productId': selectedProductId,
      'productName': selectedProductData!['name'],
      'quantity': sellQty,
      'total': total,
      'date': Timestamp.now(),
    });

    print('Income saved to Firestore');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product Sold')),
    );

    setState(() {
      _sellQtyController.clear();
      _priceController.clear();
      _noteController.clear();
      selectedProductId = null;
      selectedProductData = null;
    });
  } catch (e) {
    print('Error during Firestore operation: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() => isLoading = false);
    print('Sell process complete');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sell Product"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final products = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  value: selectedProductId,
                  items: products.map((doc) {
                    final name = doc['name'];
                    final qty = doc['quantity'];
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text('$name (Stock: $qty)'),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    final doc = await FirebaseFirestore.instance
                        .collection('products')
                        .doc(value)
                        .get();
                    setState(() {
                      selectedProductId = value;
                      selectedProductData = doc.data();
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Product',
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _sellQtyController,
              decoration: const InputDecoration(
                labelText: 'Quantity to Sell',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Selling Price per Unit',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Sale Note (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : _sellProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Sell", style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              "Sales History",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sales')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final sales = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    final date = (sale['date'] as Timestamp).toDate();
                    return ListTile(
                      title: Text(
                        '${sale['productName']} - Qty: ${sale['quantity']} | ৳${sale['total']}',
                      ),
                      subtitle: Text(
                        '${sale['note'] ?? 'No note'}\nBy: ${sale['soldBy']}',
                      ),
                      trailing: Text(
                          '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12),
                        ),

                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sellQtyController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
