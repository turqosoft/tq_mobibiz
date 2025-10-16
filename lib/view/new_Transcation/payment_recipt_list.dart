import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/model/get_payement_receipt_model.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/view/new_Transcation/receipt_screen.dart';

class PaymentReciptScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryColor,
          title: Text(
            'Payment Receipt',
            style: TextStyle(color: Colors.white),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Payment Recipt'),
              Tab(text: 'Payment Recipt List'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ReceiptScreen(),
            GetPaymentReciptScreen(),

            // Center(child: Text('Content of Tab 1')),
            // Center(child: Text('Content of Tab 2')),
          ],
        ),
      ),
    );
  }
}

class GetPaymentReciptScreen extends StatefulWidget {
  @override
  State<GetPaymentReciptScreen> createState() => _GetPaymentReciptScreenState();
}

class _GetPaymentReciptScreenState extends State<GetPaymentReciptScreen> {
  String _toDate = '';
  String _fromDate = '';

  String _searchQuery = '';
  String _searchCustomerQuery = '';
  String _searchCustomerName = '';
  TextEditingController _searchController = TextEditingController();
  TextEditingController _searchCustomerController = TextEditingController();
  TextEditingController _searchCustomerNameController = TextEditingController();
  TextEditingController _fromDateController = TextEditingController();
  TextEditingController _toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getPaymentList();
  }

  Future<void> _getPaymentList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      Future.microtask(() async {
        await provider.getPaymentRecipt(context);
      });
    } catch (e) {
      print('Error fetching item details: $e');
    }
  }

  Future<void> _getReceptDateFilterList(
      String startDate, String endDate) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.getReceiptDateFilter(context, startDate, endDate);
    } catch (e) {
      print('Error fetching item details: $e');
    }
  }

  Future<void> _selectDate(BuildContext context,
      TextEditingController controller, bool isFromDate) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(3000),
    );
    if (picked != null) {
      setState(() {
        // Display date in dd-MM-yyyy format
        String displayDate = DateFormat('dd-MM-yyyy').format(picked);
        controller.text = displayDate;

        // Keep the date in yyyy-MM-dd format for API calls
        String apiDate = DateFormat('yyyy-MM-dd').format(picked);
        if (isFromDate) {
          _fromDate = apiDate; // Pass this to API
        } else {
          _toDate = apiDate; // Pass this to API
          _getReceptDateFilterList(_fromDate, _toDate);
        }
      });
    }
  }

  Future<void> _fetchCustomerNameSearch(
      String customerName, BuildContext content) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.getReceiptSearchName(context, customerName);
    } catch (e) {
      print('Error fetching customer details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: CommonAppBar(
      //   title: 'Payment Received List',
      //   onBackTap: () {
      //     Navigator.pop(context);
      //   },
      //   backgroundColor: AppColors.primaryColor,
      // ),
      body: Column(
        children: [
          // Date Filters
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fromDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'From Date',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () =>
                            _selectDate(context, _fromDateController, true),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _toDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'To Date',
                      suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () {
                            _selectDate(context, _toDateController, false);
                            // _getSalesDateFilterList(_fromDate, _toDate);
                          }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search name',
                          suffixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                        onSubmitted: (query) {
                          _fetchCustomerNameSearch(
                              _searchController.text, context);
                        },
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    _getPaymentList();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<SalesOrderProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (provider.errorMessage != null) {
                  return Center(child: Text('Error: ${provider.errorMessage}'));
                } else if (provider.getPaymentReciptList == null) {
                  return Center(child: Text('No data available'));
                } else {
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemCount: provider.getPaymentReciptList!.data!.length,
                    itemBuilder: (context, index) {
                      final data = provider.getPaymentReciptList!.data![index];
                      return PaymentReceiptCard(data: data);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentReceiptCard extends StatelessWidget {
  final Data data;

  const PaymentReceiptCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Name', data.name, Icons.person),
            _buildRow('Posting Date', data.postingDate, Icons.date_range),
            _buildRow('Mode of Payment', data.modeOfPayment, Icons.payment),
            _buildRow('Paid To', data.paidTo, Icons.account_balance),
            // _buildRow('Party Name', data.partyName, Icons.business),

            _buildRow('Amount', data.paidAmount.toString(), Icons.attach_money),
            _buildRow('Amount', data.receivedAmount.toString(), Icons.money),
            _buildRow(' Reference Number', data.referenceNo,
                Icons.confirmation_number),
            _buildRow(
                'Reference Date', data.referenceDate, Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String? value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor),
          SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
