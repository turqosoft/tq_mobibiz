import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/view/home/home.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  String? _selectedModeOfPayment;
  List<String> _modeOfPaymentList = [];
  List<String> _customerNames = [];
  String? _selectedCustomer;

  final TextEditingController postingDateController = TextEditingController();
  final TextEditingController chequeReferenceDateController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController partyBalanceController = TextEditingController();
  final TextEditingController partyNameController = TextEditingController();
  final TextEditingController paidToController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController chequeReferenceNoController =
      TextEditingController();
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');
  SalesOrderProvider? _salesOrderProvider;
  bool _customerSelected = false;

  String? _searchCustomerName;
  String? accountValue;

  @override
  void initState() {
    super.initState();

    // Get the current date
    DateTime currentDate = DateTime.now();

    // Set the current date for display and API formats
    postingDateController.text = _displayDateFormat.format(currentDate);
    chequeReferenceDateController.text = _displayDateFormat.format(currentDate);

    // If needed, store the API format date separately
    String apiFormattedDate = _apiDateFormat.format(currentDate);
    print("API Date format for posting date: $apiFormattedDate");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCustomerGroupList();
      _fetchModeOfPaymentList();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _salesOrderProvider =
        Provider.of<SalesOrderProvider>(context, listen: false);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _salesOrderProvider?.clearCustomerList();
      _salesOrderProvider?.clearItemList();
    });
    super.dispose();
  }

  Future<void> _fetchCustomerGroupList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      final customerGroupList = await provider.customerGroupList(context);
      setState(() {});
    } catch (e) {
      print('Error fetching customer groups: $e');
    }
  }

  Future<void> _fetchModeOfPaymentList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      final modeOfPaymentList = await provider.modeOfPayment(context);
      setState(() {
        _modeOfPaymentList =
            modeOfPaymentList?.data?.map((e) => e.name ?? '').toList() ?? [];
      });
    } catch (e) {
      print('Error fetching mode of payments: $e');
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        // Display the date in dd/MM/yyyy format in the UI
        controller.text = _displayDateFormat.format(picked);

        // Store the API format date separately if needed
        String apiFormattedDate = _apiDateFormat.format(picked);
        print(
            "Date for API::::$apiFormattedDate"); // This value can be sent to the API
      });
    }
  }

  Future<void> _searchCustomer(String customer) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.searchCustomer(customer, context);
    } catch (e) {
      print('Error searching customer: $e');
    }
  }

  // Fetch the account value based on the selected mode of payment
  Future<void> _fetchAccountValue(String modeOfPayment) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      final response =
          await provider.payymentTypePaidTo(context, modeOfPayment);
      setState(() {
        accountValue = response?.data?.account ?? 'No account data';
      });
    } catch (e) {
      print('Error fetching account value: $e');
      setState(() {
        accountValue = 'Error fetching data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalesOrderProvider>(context);
    final items = provider.itemListModel?.data ?? [];
    final customerList = provider.customerSearchModel?.data ?? [];

    TextStyle style =
        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
    TextStyle style1 = const TextStyle(
        fontSize: 16.0, color: Colors.black, fontWeight: FontWeight.bold);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Consumer<SalesOrderProvider>(
                  builder: (context, provider, child) {
                    return GestureDetector(
                        onTap: () async {
                          print(
                              "test post date:::${postingDateController.text}");
                          print(
                              "test cheque date:::${chequeReferenceDateController.text}");

                          final customer = await provider.searchCustomerId(
                              _selectedCustomer!, context);

                          if (customer != null &&
                              customer.data != null &&
                              customer.data!.isNotEmpty) {
                            // Access the customer name from the 'name' field in the first Data object
                            print(
                                "Customer name from response: ${customer.data![0].name}");
                            String postingDateForApi = _apiDateFormat.format(
                              _displayDateFormat
                                  .parse(postingDateController.text),
                            );

                            String chequeDateForApi = _apiDateFormat.format(
                              _displayDateFormat
                                  .parse(chequeReferenceDateController.text),
                            );

                            // Proceed with the receipt API call
                            await provider.receipt(
                              customer.data![0].name ?? "",
                              _selectedCustomer!,
                              postingDateForApi,
                              accountValue!,
                              double.parse(paidAmountController.text),
                              double.parse(paidAmountController.text),
                              _selectedModeOfPayment!,
                              chequeReferenceNoController.text,
                              chequeDateForApi,
                              context,
                            );

                            if (provider.recieptModel != null) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) => HomeScreen()),
                              );
                            } else if (provider.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(provider.errorMessage!)),
                              );
                            }
                          } else {
                            // Handle error if customer is not found or other issues arise
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "Customer not found or error occurred.")),
                            );
                          }
                        },
                        child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.primaryColor,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                "Save",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            )));
                  },
                ),
              ),
              const SizedBox(height: 25),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Customer',
                    suffixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  onChanged: (content) {
                    // setState(() {
                    //      _customerSelected = false;
                    // });
                    _searchCustomer(_searchController.text);
                  },
                  onSubmitted: (query) {
                    setState(() {
                      _customerSelected = false;
                    });
                    _searchCustomer(_searchController.text);
                  },
                ),
              ),
              if (!_customerSelected && customerList.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: customerList.length,
                    shrinkWrap: true,
                    //   physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      final customer = customerList[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: RadioListTile<String>(
                          title: Text(customer.customerName ?? ''),
                          subtitle: Text(
                            customer.name ?? '',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          value: customer.name ?? '',
                          groupValue: _selectedCustomer,
                          onChanged: (String? selected) {
                            setState(() {
                              _selectedCustomer = selected;
                              _searchCustomerName = customer.customerName;
                              _customerSelected = true;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              if (_selectedCustomer != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15),
                    Text(
                      'Customer:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ListTile(
                      title: Text(_searchCustomerName!),
                      subtitle: Text(_selectedCustomer!),
                    ),
                  ],
                ),
              if (provider.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              const SizedBox(height: 25),
              _customerNames.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CommonLabelText(
                          labelText: 'Select Customer',
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Customer',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          value: _selectedCustomer,
                          items: _customerNames.map((String customer) {
                            return DropdownMenuItem<String>(
                              value: customer,
                              child: Text(customer),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCustomer = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 25),
                      ],
                    )
                  : const SizedBox.shrink(),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  const CommonLabelText(
                    labelText: 'Mode of Payment',
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Filter',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    value: _selectedModeOfPayment,
                    items: _modeOfPaymentList.map((String filter) {
                      return DropdownMenuItem<String>(
                        value: filter,
                        child: Text(filter),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedModeOfPayment = newValue;
                      });
                      if (newValue != null) {
                        _fetchAccountValue(newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  if (accountValue != null)
                    Text(
                      'Paid To: $accountValue',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 25),
                  const CommonLabelText(
                    labelText: 'Posting Date',
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _selectDate(context, postingDateController),
                    child: AbsorbPointer(
                      child: CommonTextField(
                        borderRadius: 6,
                        controller: postingDateController,
                        hintText: "Select Date",
                        style: style1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const CommonLabelText(
                    labelText: 'Reference No',
                  ),
                  const SizedBox(height: 10),
                  CommonTextField(
                    borderRadius: 6,
                    controller: chequeReferenceNoController,
                    hintText: "Reference No",
                    style: style1,
                  ),
                  const SizedBox(height: 25),
                  const CommonLabelText(
                    labelText: 'Reference Date',
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () =>
                        _selectDate(context, chequeReferenceDateController),
                    child: AbsorbPointer(
                      child: CommonTextField(
                        borderRadius: 6,
                        controller: chequeReferenceDateController,
                        hintText: "Select Date",
                        style: style1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const CommonLabelText(
                    labelText: 'Amount',
                  ),
                  const SizedBox(height: 10),
                  CommonTextField(
                      borderRadius: 6,
                      controller: paidAmountController,
                      hintText: "Amount",
                      style: style1),
                  const SizedBox(height: 25),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BuildCustomerDetail extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;

  const BuildCustomerDetail({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value ?? '',
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
