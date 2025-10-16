import 'package:flutter/material.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  TextStyle style = const TextStyle(fontSize: 20.0);
  final TextEditingController _itemCodeController = TextEditingController();

  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _ammountController = TextEditingController();
  final TextEditingController _priceListRateController =
      TextEditingController();
  final TextEditingController _discountAmountController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Add Items',
        onBackTap: () {
          Navigator.pop(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              CommonTextField(
                controller: _itemCodeController,
                hintText: "Item Code",
                borderRadius: 10,
                style: style,
                obscureText: false,
              ),
              const SizedBox(height: 25.0),
              CommonTextField(
                controller: _itemNameController,
                hintText: "Item Name",
                borderRadius: 10,
                style: style,
                obscureText: false,
              ),
              const SizedBox(height: 25.0),
              CommonTextField(
                controller: _quantityController,
                hintText: "Quantity",
                borderRadius: 10,
                style: style,
              ),
              const SizedBox(height: 25.0),
              CommonTextField(
                controller: _rateController,
                hintText: "Rate",
                borderRadius: 10,
                style: style,
              ),
              const SizedBox(height: 25.0),
              CommonTextField(
                controller: _priceListRateController,
                hintText: "Price List Rate",
                borderRadius: 10,
                style: style,
              ),
              const SizedBox(height: 25.0),
              CommonTextField(
                controller: _discountController,
                hintText: "Discount in %",
                borderRadius: 10,
                style: style,
              ),
              const SizedBox(height: 25.0),
              CommonTextField(
                controller: _discountAmountController,
                hintText: "Discount Amount",
                borderRadius: 10,
                style: style,
              ),
              const SizedBox(height: 25.0),
              CommonTextField(
                controller: _ammountController,
                hintText: "Amount",
                borderRadius: 10,
                style: style,
              ),
              const SizedBox(
                height: 30,
              ),
              CommonButton(
                buttonText: "Add Items",
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddItemScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
