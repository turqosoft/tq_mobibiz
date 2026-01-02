
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:sales_ordering_app/view/new_Transcation/sales_order.dart';
import 'package:sales_ordering_app/view/sales_invoice.dart/SalesInvoice.dart';

class SalesInvoiceCreateScreen extends StatefulWidget {
  const SalesInvoiceCreateScreen({Key? key}) : super(key: key);

  @override
  State<SalesInvoiceCreateScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceCreateScreen> {
  String? _selectedCustomer;
  String? _searchCustomerName;
  final TextEditingController _searchController = TextEditingController();
  bool _customerSelected = false;
  String? _currency;
  bool isSubmitting = false;

  final TextEditingController _itemSearchController = TextEditingController();
  String? _selectedItem;
  bool _itemSelected = false;

  final TextEditingController customerController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();
  final TextEditingController itemCodeController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController priceListRateController = TextEditingController();
  final TextEditingController totalController = TextEditingController(); // NEW
  final TextEditingController postingDateController = TextEditingController();
  DateTime? _selectedPostingDate;


  final FocusNode totalFocusNode = FocusNode(); // NEW

  String currency = "INR";

  void _recalculateTotal() {
    final qty = double.tryParse(qtyController.text) ?? 0.0;
    final rate = double.tryParse(rateController.text) ?? 0.0;
    final total = qty * rate;
    totalController.text = total.toStringAsFixed(3);
  }

  void _handleTotalEdit() {
    if (!totalFocusNode.hasFocus) return;

    final total = double.tryParse(totalController.text) ?? 0.0;
    final qty = double.tryParse(qtyController.text) ?? 0.0;
    if (qty > 0) {
      final newRate = total / qty;
      rateController.text = newRate.toStringAsFixed(3);
      priceListRateController.text = newRate.toStringAsFixed(3);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _itemSearchController.dispose();
    customerController.dispose();
    dueDateController.dispose();
    itemCodeController.dispose();
    qtyController.dispose();
    rateController.dispose();
    discountController.dispose();
    priceListRateController.dispose();
    totalController.dispose(); // dispose new controller
    totalFocusNode.dispose(); // dispose new focus node
    postingDateController.dispose();


    super.dispose();
  }



    Future<void> _searchCustomer(String customer) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.searchCustomer(customer, context);
    } catch (e) {
      print('Error searching customer: $e');
    }
  }


  Future<void> _searchItemList(String item) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.itemSearchList(item, context, false);
    } catch (e) {
      print('Error fetching item details: $e');
    }
  }
  Future<void> _selectPostingDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedPostingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedPostingDate = pickedDate;
        postingDateController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
      });
    }
  }

  void resetForm() {
  setState(() {
    _selectedCustomer = null;
    _searchCustomerName = null;
    _searchController.clear();
    _customerSelected = false;

    _selectedItem = null;
    _itemSearchController.clear();
    _itemSelected = false;
    _itemSelected = false;

    customerController.clear();
  _selectedDueDate = DateTime.now();
  dueDateController.text = DateFormat('dd-MM-yyyy').format(_selectedDueDate!);    itemCodeController.clear();
    qtyController.clear();
    rateController.clear();
    discountController.clear();
    priceListRateController.clear();
    _selectedPostingDate = DateTime.now();
    postingDateController.text = DateFormat('dd-MM-yyyy').format(_selectedPostingDate!);

  });

  final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  provider.clearItem();
  provider.clearSearchResults(); // You’ll add this next
}



void _showAddItemDialog({
  required String itemName,
  required String itemCode,
  required double rate,
  required double quantity,
  required double priceListRate, // <-- Add this
  required double discountPercentage,
  required VoidCallback onCancel,

}) {
    // Set rateController to priceListRate as default
  rateController.text = priceListRate.toStringAsFixed(3);

  // Set priceListRateController too for display (if needed)
  priceListRateController.text = priceListRate.toStringAsFixed(3);
  showDialog(
    context: context,
    builder: (context) => AddItemDialog(
      itemName: itemName,
      itemCode: itemCode,
      rate: priceListRate,
      quantity: quantity,
      priceListRate: priceListRate, // <-- Pass it here
      discountPercentage: discountPercentage,
      onCancel: onCancel,

    ),
  );
}


  void _showEditDialog(BuildContext context, int index,
      SalesOrderProvider provider, final VoidCallback onCancel) {
    final item = provider.itemsList[index];
    final _rateController = TextEditingController(text: item.rate.toString());
    final _quantityController = TextEditingController(text: item.quantity.toString());
    final _priceListRateController = TextEditingController(text: item.priceListRate?.toString() ?? '');
    final _discountPercentageController = TextEditingController(text: item.discountPercentage?.toString() ?? '');
    final _totalController = TextEditingController(text: (item.rate * item.quantity).toStringAsFixed(3));
    final _totalFocusNode = FocusNode();

    double totalAmount = item.rate * item.quantity;

    void updateTotal() {
      if (_totalFocusNode.hasFocus) return; // Don't auto-update if user is editing total

      final rate = double.tryParse(_rateController.text) ?? 0;
      final qty = double.tryParse(_quantityController.text) ?? 0;
      totalAmount = rate * qty;
      _totalController.text = totalAmount.toStringAsFixed(3);
      (context as Element).markNeedsBuild(); // Triggers rebuild
    }


    void updateRateFromTotal() {
      if (!_totalFocusNode.hasFocus) return;

      final total = double.tryParse(_totalController.text) ?? 0;
      final qty = double.tryParse(_quantityController.text) ?? 0;
      if (qty > 0) {
        final newRate = total / qty;
        _rateController.text = newRate.toStringAsFixed(3);
        _priceListRateController.text = newRate.toStringAsFixed(3);
      }
    }

    _rateController.addListener(updateTotal);
    _quantityController.addListener(updateTotal);
    _totalController.addListener(updateRateFromTotal);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Item: ${item.name}'),
                TextField(
                  controller: _priceListRateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Price List Rate'),
                  readOnly: true,
                ),
                TextField(
                  controller: _rateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Rate'),
                ),
                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Quantity'),
                ),
                TextField(
                  controller: _totalController,
                  focusNode: _totalFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Total'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final newRate = double.tryParse(_rateController.text) ?? 0.0;
                final newQuantity = double.tryParse(_quantityController.text) ?? 0;
                final newPriceListRate =
                    double.tryParse(_priceListRateController.text) ?? 0.0;
                final newDiscountPercentage =
                    double.tryParse(_discountPercentageController.text) ?? 0.0;

                if (newRate <= 0) {
                  Fluttertoast.showToast(
                    msg: "Please enter a valid rate",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                } else if (newQuantity <= 0) {
                  Fluttertoast.showToast(
                    msg: "Please enter a valid quantity",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                } else {
                  provider.editItem(
                    index,
                    newRate,
                    newQuantity,
                    newPriceListRate,
                    newDiscountPercentage,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                onCancel();
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }


  DateTime? _selectedDueDate;

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      if (_selectedPostingDate != null && pickedDate.isBefore(_selectedPostingDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Due date cannot be before posting date."),
            backgroundColor: Colors.red,
          ),
        );
        return; // ❌ Do not update if invalid
      }

      setState(() {
        _selectedDueDate = pickedDate;
        dueDateController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
      });
    }
  }


@override
void initState() {
  super.initState();
  qtyController.addListener(_recalculateTotal);
  rateController.addListener(_recalculateTotal);
  totalController.addListener(_handleTotalEdit);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    resetForm(); // Ensures context is available
  });
}


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalesOrderProvider>(context);
        final items = provider.itemListModel?.data ?? [];
    TextStyle style =
        const TextStyle(fontSize: 15, fontWeight: FontWeight.bold);
        final customerList = provider.customerSearchModel?.data ?? [];


    return Scaffold(

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [

Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: isSubmitting
              ? null
              : () async {
            setState(() {
              isSubmitting = true;
            });

            final provider = Provider.of<SalesOrderProvider>(context, listen: false);
            final customerName = customerController.text.trim();
            final dueDate = dueDateController.text.trim();
            final items = provider.items;

            if (customerName.isEmpty || dueDate.isEmpty || items.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please fill all fields and add items.")),
              );
              setState(() {
                isSubmitting = false;
              });
              return;
            }

            final success = await provider.submitInvoice(
              context,
              customerName,
              _selectedDueDate!,
              _selectedPostingDate!,
            );

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sales Invoice Created"), backgroundColor: Colors.green),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SalesInvoicePage()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(provider.errorMessage ?? "Unknown error occurred")),
              );
            }

            setState(() {
              isSubmitting = false;
            });
          },


          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isSubmitting ? Colors.blueGrey : AppColors.primaryColor,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: isSubmitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Text(
                "Save",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        ),

      ],
    ),
    const SizedBox(height: 8),
    // Container(
    //   padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
    //   decoration: BoxDecoration(
    //     color: Colors.grey[200],
    //     borderRadius: BorderRadius.circular(10.0),
    //   ),
    //   child: TextField(
    //     controller: _searchController,
    //     decoration: const InputDecoration(
    //       labelText: 'Search Customer',
    //       suffixIcon: Icon(Icons.search),
    //       border: InputBorder.none,
    //       contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
    //     ),
    //     onChanged: (content) {
    //       _searchCustomer(_searchController.text);
    //     },
    //     onSubmitted: (query) {
    //       setState(() {
    //         _customerSelected = false;
    //       });
    //       _searchCustomer(_searchController.text);
    //     },
    //   ),
    // ),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search Customer',
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedCustomer = null;
                customerController.clear();
                customerList.clear();
              });
            },
          )
              : const Icon(Icons.search),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          _selectedCustomer = null; // allow reselection
          _searchCustomer(value);
        },
      ),
    ),

  ],
),


// List of Matching Customers
// if (!_customerSelected && customerList.isNotEmpty)
              if (customerList.isNotEmpty)

                SizedBox(
    height: 200,
    child: ListView.builder(
      itemCount: customerList.length,
      itemBuilder: (BuildContext context, int index) {
        final customer = customerList[index];

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: RadioListTile<String>(
            title: Text(customer.customerName ?? ''),
            subtitle: Text(
              customer.name ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            value: customer.name ?? '',
            groupValue: _selectedCustomer,
            onChanged: (String? selected) async {
              if (selected == null) return;

              // setState(() {
              //   _selectedCustomer = selected;
              //   _searchCustomerName = customer.customerName;
              //   _customerSelected = true;
              //   customerController.text = customer.name ?? '';
              // });
              setState(() {
                _selectedCustomer = customer.name;
                _searchController.text = customer.customerName ?? '';
                customerController.text = customer.name ?? '';
                customerList.clear(); // hide list after selection
              });

              try {
                final provider = Provider.of<SalesOrderProvider>(context, listen: false);
                final customerDetails = await provider.fetchCustomerDetails(
                  context,
                  customer.customerName ?? '',
                );

                debugPrint('✅ Fetched Customer Details: $customerDetails');

                if (customerDetails != null && customerDetails['message'] != null) {
                  final message = customerDetails['message'];
                  setState(() {
                    _currency = message['currency'] ?? '';
                  });
                  debugPrint('💱 Currency: $_currency');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to fetch customer details')),
                  );
                }
              } catch (e) {
                debugPrint('❌ Error fetching customer details: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error occurred while fetching customer')),
                );
              }
            },
          ),
        );
      },
    ),
  ),

// // Show Selected Customer Details
// if (_selectedCustomer != null)
//   Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       const SizedBox(height: 15),
//       const Text(
//         'Customer:',
//         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//       ),
//       ListTile(
//         title: Text(_searchCustomerName ?? ''),
//         subtitle: Text(_selectedCustomer ?? ''),
//       ),
//     ],
//   ),

// Loading Indicator
if (Provider.of<SalesOrderProvider>(context).isLoading)
  const Center(child: CircularProgressIndicator()),

              const SizedBox(height: 12),

const SizedBox(height: 15),

              Row(
                children: [
                  // Posting Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 5.0, bottom: 5),
                          child: Text(
                            "Posting Date",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _selectPostingDate(context),
                          child: AbsorbPointer(
                            child: CommonTextField(
                              controller: postingDateController,
                              hintText: "Select",
                              borderRadius: 10,
                              style: style,
                              obscureText: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Due Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 5.0, bottom: 5),
                          child: Text(
                            "Due Date",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _selectDueDate(context),
                          child: AbsorbPointer(
                            child: CommonTextField(
                              controller: dueDateController,
                              hintText: "Select",
                              borderRadius: 10,
                              style: style,
                              obscureText: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),


                  const Divider(height: 32),
              const Text("Add Item", style: TextStyle(fontWeight: FontWeight.bold)),

// Input field styled like reference
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
  decoration: BoxDecoration(
    color: Colors.grey[200],
    borderRadius: BorderRadius.circular(10.0),
  ),
  child: TextField(
    controller: _itemSearchController,
    decoration: const InputDecoration(
      labelText: 'Search Item',
      suffixIcon: Icon(Icons.search),
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
    ),
    onChanged: (content) {
      setState(() {
        _itemSelected = false;
      });
      _searchItemList(content);
    },
    onSubmitted: (query) {
      setState(() {
        _itemSelected = false;
      });
      _searchItemList(query);
    },
  ),
),

// List of matching items
if (!_itemSelected && items.isNotEmpty)
  SizedBox(
    height: 200,
    child: ListView.builder(
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        var item = items[index];
        bool isAlreadySelected = _selectedItem == item.itemName;

        return Padding(
          padding: const EdgeInsets.only(top: 15),
          child: RadioListTile<String>(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  item.itemCode ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            value: item.itemName ?? '',
            groupValue: _selectedItem,

              onChanged: (String? selected) async {
                if (selected == null) return;

                final provider = Provider.of<SalesOrderProvider>(context, listen: false);
                final customer = customerController.text.trim();

                // 🔐 Check if customer is filled in
                if (customer.isEmpty) {
                  Fluttertoast.showToast(msg: "Please enter/select a customer first.");
                  return;
                }

                // 🔁 Ensure customer details are fetched
                if (provider.invoiceCustomerDetails == null ||
                    provider.invoiceCustomerDetails?["customer_name"] != customer) {
                  try {
                    await provider.fetchCustomer(context, customer);
                  } catch (e) {
                    Fluttertoast.showToast(msg: "Failed to fetch customer details.");
                    return;
                  }
                }

                // final priceList = provider.invoiceCustomerDetails?["selling_price_list"];
                // if (priceList == null) {
                //   Fluttertoast.showToast(msg: "Selling Price List not found in customer details.");
                //   return;
                // }
                final customerDetails = provider.invoiceCustomerDetails ??
                    await provider.fetchCustomer(context, customer);

                if (customerDetails == null) {
                  Fluttertoast.showToast(msg: "Failed to load customer details.");
                  return;
                }

                final priceList = provider.sellingPriceList;

                if (priceList == null || priceList.isEmpty) {
                  Fluttertoast.showToast(
                    msg: "Selling Price List is not configured for this customer.",
                  );
                  return;
                }

                try {
                  final item = items[index];

                  // 🚫 Check if item already exists in the list
                  final isDuplicate = provider.itemsList.any(
                        (existingItem) => existingItem.itemCode == item.itemCode,
                  );

                  if (isDuplicate) {
                    Fluttertoast.showToast(msg: "Item '${item.itemName}' already added.");
                    return; // Exit early, don't proceed to fetch or show dialog
                  }

                  final itemDetails = await provider.fetchItem(
                    context: context,
                    itemCode: item.itemCode ?? '',
                    itemName: item.itemName ?? '',
                    quantity: 1.0,
                    currency: currency,
                    customer: customer,
                    priceList: priceList,
                  );

                  if (itemDetails != null) {
                    final rate = itemDetails['rate'] ?? 0.0;
                    final priceListRate = itemDetails['price_list_rate'] ?? 0.0;
                    final discount = itemDetails['discount_percentage'] ?? 0.0;

                    setState(() {
                      _selectedItem = selected;
                      _itemSelected = true;
                      _itemSearchController.clear();
                    });

                    _showAddItemDialog(
                      itemName: item.itemName ?? "",
                      itemCode: item.itemCode ?? "",
                      rate: rate,
                      quantity: 1,
                      priceListRate: priceListRate,
                      discountPercentage: discount,
                      onCancel: () {
                        setState(() {
                          _selectedItem = null;
                          _itemSelected = false;
                        });
                      },
                    );
                  } else {
                    Fluttertoast.showToast(msg: "Failed to fetch item details.");
                  }
                } catch (e) {
                  Fluttertoast.showToast(msg: "Error fetching item: $e");
                }

              }

          ),
        );
      },
    ),
  ),

              if (provider.isLoadingItem)
                const Center(
                  child: CircularProgressIndicator(),
                ),

SizedBox(
  height: 250, // Increased height to fit the total amount text
  child: Consumer<SalesOrderProvider>(
    builder: (context, itemProvider, child) {
      // Calculate grand total of all items
      final grandTotal = itemProvider.itemsList.fold<double>(
        0,
        (sum, item) => sum + ((item.rate ?? 0) * (item.quantity ?? 0)),
      );

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // List of items
    Expanded(
      child: ListView.builder(
        itemCount: itemProvider.itemsList.length,
        itemBuilder: (context, index) {
          final item = itemProvider.itemsList[index];
          final totalAmount = (item.rate ?? 0) * (item.quantity ?? 0);

          return ListTile(
            title: Text('${item.name}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rate: ${item.rate}, Quantity: ${item.quantity}'),
                Text('Total: ₹$totalAmount'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.black),
                  onPressed: () {
                    _showEditDialog(context, index, itemProvider, () {
                      setState(() {
                        _selectedItem = null;
                      });
                      _itemSearchController.clear();
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _selectedItem = null;
                    });
                    _itemSearchController.clear();
                    itemProvider.deleteItem(index);
                  },
                ),
              ],
            ),
          );
        },
      ),
    ),

    // Total amount at the bottom
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        'Total Amount: ₹${itemProvider.itemsList.fold<double>(
          0,
          (sum, item) => sum + ((item.rate ?? 0) * (item.quantity ?? 0)),
        ).toStringAsFixed(2)}',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  ],
);

    },
  ),
),


              SizedBox(height: 15),

              SizedBox(height: 15),
              const SizedBox(height: 20),

             Consumer<SalesOrderProvider>(
  builder: (context, provider, _) {
    if (provider.item.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Items Added:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...provider.item.map((item) {
return ListTile(
  title: Text("${item["item_code"]} - ${item["item_name"]}"),
  subtitle: Text("Qty: ${item["qty"]}, Rate: ${item["rate"]}"),
);

        }).toList(),
      ],
    );
  },
),

              const SizedBox(height: 30),

              if (provider.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
