import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

import 'ledger_pdf_builder.dart';
import 'map_screen.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  _CustomersListScreenState createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  String? _selectedFilter;
  List<String> _filters = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCustomerList();
      _fetchCustomerGroupList();
    });
  }

  Future<void> _fetchCustomerList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.customerList(context);
    } catch (e) {
      print('Error fetching customer details: $e');
    }
  }

  Future<void> _fetchCustomerGroupList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      final customerGroupList = await provider.customerGroupList(context);
      setState(() {
        _filters =
            customerGroupList?.data?.map((e) => e.name ?? '').toList() ?? [];
      });
    } catch (e) {
      print('Error fetching customer groups: $e');
    }
  }
  Future<Position?> _getDeviceLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return null;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied.")),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission permanently denied.")),
      );
      return null;
    }

    // ✅ Get device position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
  Future<void> _fetchCustomerGroupFilter(
      String customerGroup, BuildContext content) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.customerGroupFilter(customerGroup, content);
    } catch (e) {
      print('Error fetching customer details: $e');
    }
  }
  Future<void> saveAndOpenPdf(List<int> pdfBytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$fileName.pdf");
    await file.writeAsBytes(pdfBytes, flush: true);
    await OpenFilex.open(file.path);
  }

  Future<void> _fetchCustomerNameSearch(
      String customerName, BuildContext content) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.customerNameSearch(customerName, content);
    } catch (e) {
      print('Error fetching customer details: $e');
    }
  }

  DateTime safeSubtractOneMonth(DateTime date) {
    // Move back one month, keeping the year correct
    int year = date.year;
    int month = date.month - 1;

    if (month == 0) {
      month = 12;
      year -= 1;
    }

    // Find the last day of the new month
    int lastDayOfPrevMonth = DateTime(year, month + 1, 0).day;

    // Clamp the day (e.g., 31 -> 28/29 if February)
    int day = date.day > lastDayOfPrevMonth ? lastDayOfPrevMonth : date.day;

    return DateTime(year, month, day);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter Items'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Filter',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                ),
                value: _selectedFilter,
                items: _filters.map((String filter) {
                  return DropdownMenuItem<String>(
                    value: filter,
                    child: Text(filter),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFilter = newValue;
                  });
                  _fetchCustomerGroupFilter(_selectedFilter!, context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // final provider = Provider.of<SalesOrderProvider>(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Customers',
        onBackTap: () {
          Navigator.pop(context);
        },
        actions: Row(
          children: [
            IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
                // onPressed: () {
                //   _fetchCustomerList();
                // }
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedFilter = null;
                });
                _fetchCustomerList();
              },),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: Colors.white,
              ),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child:
              Consumer<SalesOrderProvider>(builder: (context, provider, child) {
            final customerList = provider.customerListModel?.data ?? [];
            if (provider.isLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (provider.customerListModel == null ||
                provider.customerListModel!.data == null ||
                provider.customerListModel!.data!.isEmpty) {
              return Center(child: Text('No current customer available.'));
            } else {
              return Column(
                children: [
                  Container(
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
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            if (_searchController.text.isNotEmpty) {
                              _fetchCustomerNameSearch(_searchController.text, context);
                            } else {
                              // Show message if search is empty
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please enter a customer name to search'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      onSubmitted: (query) {
                        if (query.isNotEmpty) {
                          _fetchCustomerNameSearch(query, context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please enter a customer name to search'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),


                  ),
                  const SizedBox(height: 20),
                  customerList.isNotEmpty
                  ?ListView.builder(
                    itemCount: customerList.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      final customer = customerList[index];
                      // fetch details only once
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final provider = Provider.of<SalesOrderProvider>(context, listen: false);
                        provider.apiService!.fetchCustomerDetailss(customer, context);
                      });
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 10.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10.0,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 👉 Customer details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (customer.name != null)
                                      Text("Name : ${customer.name}",
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                                    if (customer.gstin != null)
                                      Text("GSTIN : ${customer.gstin}",
                                          style: const TextStyle(fontSize: 16)),

                                    if (customer.territory != null)
                                      Text("Territory : ${customer.territory}",
                                          style: const TextStyle(fontSize: 16)),

                                    if (customer.customerPrimaryContact != null)
                                      Text("Primary Contact : ${customer.customerPrimaryContact}",
                                          style: const TextStyle(fontSize: 16)),

                                    if (customer.mobileNo != null)
                                      Text("Mobile Number : ${customer.mobileNo}",
                                          style: const TextStyle(fontSize: 16)),

                                    if (customer.taxCategory != null)
                                      Text("Tax Category : ${customer.taxCategory}",
                                          style: const TextStyle(fontSize: 16)),

                                    if (customer.customerGroup != null)
                                      Text("Customer Group : ${customer.customerGroup}",
                                          style: const TextStyle(fontSize: 16)),

                                    // 🔥 New fields (only show if > 0)
                                    if (customer.billingThisYear != null && customer.billingThisYear! > 0)
                                      Text(
                                        "Billing This Year : ₹${customer.billingThisYear!.toStringAsFixed(2)}",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                      ),

                                    if (customer.totalUnpaid != null && customer.totalUnpaid! > 0)
                                      Text(
                                        "Total Unpaid : ₹${customer.totalUnpaid!.toStringAsFixed(2)}",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                                      ),
                                  ],
                                ),
                              ),

                              // 👉 Download Icon button
                              IconButton(
                                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                onPressed: () async {
                                  final api = Provider.of<SalesOrderProvider>(context, listen: false);

                                  final now = DateTime.now();

                                  String formatDate(DateTime date) =>
                                      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

                                  final toDate = formatDate(now);
                                  final fromDate = formatDate(safeSubtractOneMonth(now));

                                  final ledgerJson = await api.apiService!.fetchGeneralLedger(
                                    context,
                                    customer.name!,
                                    fromDate,
                                    toDate,
                                  );

                                  if (ledgerJson != null) {
                                    final html = buildLedgerHtml(ledgerJson, fromDate, toDate, fallbackCustomerName: customer.name);
                                    final pdfBytes = await api.apiService!.generatePdfFromHtml(context, html);

                                    if (pdfBytes != null) {
                                      await saveAndOpenPdf(pdfBytes as List<int>, "General_Ledger_${customer.name}");
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("PDF Downloaded Successfully")),
                                      );
                                    }
                                  }

                                },

                              ),
                              IconButton(
                                icon: const Icon(Icons.location_on, color: Colors.blue),
                                onPressed: () async {
                                  final api = Provider.of<SalesOrderProvider>(context, listen: false);

                                  // ✅ Show loading while calling ERP API
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) => const Center(child: CircularProgressIndicator()),
                                  );

                                  try {
                                    final customerDetails =
                                    await api.apiService!.fetchCustomerLocation(customer.name!, context);

                                    double? lat = customerDetails?["latitude"]?.toDouble();
                                    double? lng = customerDetails?["longitude"]?.toDouble();

                                    Navigator.pop(context); // ✅ Close loading dialog

                                    // ✅ If ERP does not have location → ask user
                                    if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
                                      final shouldFetch = await showDialog<bool>(
                                        context: context,
                                        barrierDismissible: false, // ❌ Prevent dismiss outside
                                        builder: (ctx) {
                                          return AlertDialog(
                                            title: const Text("Location Not Found"),
                                            content: const Text(
                                                "No location found. Do you want to fetch location from this device?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false), // Cancel
                                                child: const Text("No"),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, true), // Yes
                                                child: const Text("Yes"),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (shouldFetch == true) {
                                        // ✅ Show loader while fetching device location
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (ctx) => const Center(child: CircularProgressIndicator()),
                                        );

                                        final position = await _getDeviceLocation(context);

                                        Navigator.pop(context); // close loader

                                        if (position != null) {
                                          lat = position.latitude;
                                          lng = position.longitude;
                                        }
                                      } else {
                                        // User chose No → show message and stop
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Location not available.")),
                                        );
                                        return; // 🚀 Prevent navigation
                                      }
                                    }

                                    if (lat != null && lng != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (ctx) => CustomerMapScreen(
                                            latitude: lat!,
                                            longitude: lng!,
                                            customerName: customer.name!,                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("No location data available.")),
                                      );
                                    }
                                  } catch (e) {
                                    Navigator.pop(context); // close dialog if API failed
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error: $e")),
                                    );
                                  }
                                },
                              ),





                            ],
                          ),
                        ),
                      );
                    },
                  )


                      : Center(
                          child: provider.isLoading
                              ? const CircularProgressIndicator()
                              : const Text('No customers found'),
                        ),
                ],
              );
            }
          }),
        ),
      ),
    );
  }
}

class BuildCustomerDetail extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  const BuildCustomerDetail(
      {super.key, required this.label, this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class BuildCustomerTile extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  //final Widget iconWidget;
  const BuildCustomerTile({
    super.key,
    required this.label,
    this.value,
    required this.icon,
    //required this.iconWidget
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          // iconWidget
        ],
      ),
    );
  }
}

class BuildItemDetail extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Function onTapAdd;
  final Function onTapClose;
  const BuildItemDetail(
      {super.key,
      required this.label,
      this.value,
      required this.icon,
      required this.onTapAdd,
      required this.onTapClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () {
              onTapAdd.call();
              //  setState(() {
              //    _addedItems.add(Data(
              //      itemCode: item.itemCode,
              //      itemName: item.itemName,
              //      qty: 1,
              //      rate: item.valuationRate,
              //    ));
              // });
            },
            child: Icon(Icons.add),
          ),
          GestureDetector(
            onTap: () {
              onTapClose.call();
              //  setState(() {
              //    _addedItems.removeWhere((addedItem) => addedItem.itemCode == item.itemCode);
              //  });
            },
            child: Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class BuildItemListTile extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Function onTapAdd;
  final Function onTapClose;
  final int qty;
  const BuildItemListTile(
      {super.key,
      required this.label,
      this.value,
      required this.icon,
      required this.onTapAdd,
      required this.onTapClose,
      required this.qty});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: GestureDetector(
              onTap: () {
                onTapAdd.call();
                //  setState(() {
                //    _addedItems.add(Data(
                //      itemCode: item.itemCode,
                //      itemName: item.itemName,
                //      qty: 1,
                //      rate: item.valuationRate,
                //    ));
                // });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.add),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('$qty'),
          ),
          GestureDetector(
            onTap: () {
              onTapClose.call();
              //  setState(() {
              //    _addedItems.removeWhere((addedItem) => addedItem.itemCode == item.itemCode);
              //  });
            },
            child: Icon(Icons.minimize),
          ),
        ],
      ),
    );
  }
}
