import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/view/new_Transcation/add_item_screen.dart';

class NewTransaction extends StatelessWidget {
  const NewTransaction({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<SalesOrderProvider>(context);
    final TextEditingController amountController = TextEditingController();

    final List<Map<String, String>> items = [
      {
        'name': 'Item 1',
        'quantity': '10',
        'rate': '5.00',
        'discount': '0.50',
        'totalAmount': '45.00'
      },
      {
        'name': 'Item 2',
        'quantity': '20',
        'rate': '2.50',
        'discount': '0.25',
        'totalAmount': '47.50'
      },
      {
        'name': 'Item 3',
        'quantity': '15',
        'rate': '3.00',
        'discount': '0.30',
        'totalAmount': '42.00'
      },
      {
        'name': 'Item 4',
        'quantity': '5',
        'rate': '10.00',
        'discount': '1.00',
        'totalAmount': '45.00'
      },
      {
        'name': 'Item 5',
        'quantity': '8',
        'rate': '6.00',
        'discount': '0.60',
        'totalAmount': '43.20'
      },
    ];
    TextStyle style =
        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
    TextStyle style1 = const TextStyle(
        fontSize: 16.0, color: Colors.black, fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'New Transaction',
        onBackTap: () {
          Navigator.pop(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CommonLabelText(
                labelText: 'Select Type',
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.borderColor.withOpacity(0.5),
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: const Text('Select Type'),
                    value: transactionProvider.selectedType,
                    icon: const Icon(Icons.arrow_drop_down),
                    iconSize: 24,
                    elevation: 16,
                    style: const TextStyle(color: AppColors.borderColor),
                    items: transactionProvider.items
                        .map<DropdownMenuItem<String>>((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      transactionProvider.setSelectedType(newValue);
                    },
                    isExpanded: true,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const CommonLabelText(
                labelText: 'Select Customer',
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.borderColor.withOpacity(0.5),
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: const Text('Select Customer'),
                    value: transactionProvider.selectedCustomer,
                    icon: const Icon(Icons.arrow_drop_down),
                    iconSize: 24,
                    elevation: 16,
                    style: const TextStyle(color: AppColors.borderColor),
                    items: transactionProvider.customers
                        .map<DropdownMenuItem<String>>((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      transactionProvider.setSelectedCustomer(newValue);
                    },
                    isExpanded: true,
                  ),
                ),
              ),
              if (transactionProvider.selectedType == 'Sales order')
                Column(
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 70),
                      child: CommonButton(
                        buttonText: "Add Items",
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AddItemScreen()));
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    ListView.separated(
                      itemCount: items.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                blurRadius: 2.0,
                                spreadRadius: 2.0,
                              )
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text("Item name : ${item['name']}",
                                        style: style),
                                  ],
                                ),
                                Text("Qauntity :${item['quantity']}",
                                    style: style),
                                Text("Rate :${item['rate']}", style: style),
                                Text("Discount :${item['discount']}",
                                    style: style),
                                Text("Total Amount :${item['totalAmount']}",
                                    style: style)
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const SizedBox(
                          height: 15,
                        );
                      },
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 70),
                      child: CommonButton(
                        buttonText: "Save",
                        onTap: () {
                          // Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: (context) => const ()));
                        },
                      ),
                    ),
                  ],
                ),
              if (transactionProvider.selectedType == 'Receipt')
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),
                    const CommonLabelText(
                      labelText: 'Amount',
                    ),
                    const SizedBox(height: 10),
                    CommonTextField(
                        borderRadius: 6,
                        controller: amountController,
                        hintText: "Amount",
                        style: style1),
                    const SizedBox(height: 25),
                    const CommonLabelText(
                      labelText: 'Payment Type',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.borderColor.withOpacity(0.5),
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          hint: const Text('Payment Type'),
                          value: transactionProvider.selectedPaymentType,
                          icon: const Icon(Icons.arrow_drop_down),
                          iconSize: 24,
                          elevation: 16,
                          style: const TextStyle(color: AppColors.borderColor),
                          items: transactionProvider.paymentType
                              .map<DropdownMenuItem<String>>((String item) {
                            return DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            transactionProvider.setPaymentType(newValue);
                          },
                          isExpanded: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 70),
                      child: CommonButton(
                        buttonText: "Save",
                        onTap: () {
                          // Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: (context) => const ()));
                        },
                      ),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}
