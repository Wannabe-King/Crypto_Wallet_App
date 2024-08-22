import 'package:crypto_eth_wallet/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:crypto_eth_wallet/models/transaction_model.dart';
import 'package:crypto_eth_wallet/utils/colors.dart';
import 'package:flutter/material.dart';

class DepositPage extends StatefulWidget {
  final DashboardBloc dashboardBloc;
  const DepositPage({super.key, required this.dashboardBloc});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController reasonsController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greenAccent,
      body: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            Text(
              "Deposit Details",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // TextField(
            //   controller: addressController,
            //   decoration: InputDecoration(hintText: "Enter the Address"),
            // ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(hintText: "Enter the Amount"),
            ),
            TextField(
              controller: reasonsController,
              decoration: InputDecoration(hintText: "Enter the Reason"),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                widget.dashboardBloc.add(DashboardDepositEvent(
                    transactionModel: TransactionModel(
                        "0xdcBf0f0be025e0E7af5E93F8bC69c92C59960c8D",
                        int.parse(amountController.text),
                        reasonsController.text,
                        DateTime.now())));
                Navigator.pop(context);
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green),
                child: const Center(
                  child: Text(
                    "+ DEPOSIT",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}