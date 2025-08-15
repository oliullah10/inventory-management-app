import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  String? selectedProductId;
  String productName = '';
  bool isOther = false;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  Future<void> _submitExpense() async {
    final amount = double.tryParse(_amountController.text.trim());
    final note = _noteController.text.trim();

    if (amount == null || amount <= 0 || (selectedProductId == null && !isOther)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Fill all fields properly")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('expense').add({
      'productId': isOther ? 'other' : selectedProductId,
      'productName': isOther ? 'Other' : productName,
      'amount': amount,
      'note': note,
      'date': Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Expense"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: isOther,
                  onChanged: (val) {
                    setState(() {
                      isOther = val!;
                      selectedProductId = null;
                      productName = '';
                    });
                  },
                ),
                const Text("Other Expense"),
              ],
            ),
            if (!isOther)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final products = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    hint: const Text("Select Product"),
                    items: products.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedProductId = val;
                        productName = products.firstWhere((doc) => doc.id == val)['name'];
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: "Amount",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: "Note (optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submitExpense,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          child: const Text("Add"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
