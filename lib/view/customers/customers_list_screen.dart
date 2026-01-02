import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

import '../../service/apiservices.dart';
import '../../utils/sharedpreference.dart';
import 'add_customer.dart';
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
  final SharedPrefService _sharedPrefService = SharedPrefService();
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
  Future<void> showLoadingDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // prevent closing
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  DateTime? _selectedPostingDate;

  // String get formattedPostingDate {
  //   if (_selectedPostingDate == null) return "";
  //   return "${_selectedPostingDate!.year}-"
  //       "${_selectedPostingDate!.month.toString().padLeft(2, '0')}-"
  //       "${_selectedPostingDate!.day.toString().padLeft(2, '0')}";
  // }
  String formatDateForDisplay(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  String formatDateForApi(DateTime date) {
    return "${date.year}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Customers',
        onBackTap: () {
          Navigator.pop(context);
        },
        actions: Row(
          children: [
            // ➕ ADD NEW CUSTOMER BUTTON
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                ).then((_) {
                  _fetchCustomerList();   // Refresh after adding customer
                });
              },
            ),
            IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
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
                        EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🧾 Customer details
                              Column(
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

                                  if (customer.billingThisYear != null && customer.billingThisYear! > 0)
                                    Text(
                                      "Billing This Year : ₹${customer.billingThisYear!.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),

                                  if (customer.totalUnpaid != null && customer.totalUnpaid! > 0)
                                    Text(
                                      "Total Unpaid : ₹${customer.totalUnpaid!.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                                    ),
                                ],
                              ),

                              // const SizedBox(height: 12),
                              const Divider(thickness: 1),
                             Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                               crossAxisAlignment: CrossAxisAlignment.center,
                               children: [
                                 // // 🧾 General Ledger
                                 // IconButton(
                                 //   iconSize: 24,
                                 //   padding: EdgeInsets.zero,
                                 //   constraints: const BoxConstraints(),
                                 //   icon: const Icon(Icons.file_download, color: Colors.orangeAccent),
                                 //   tooltip: "Download General Ledger",
                                 // 🧾 General Ledger
                                 Column(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     IconButton(
                                       iconSize: 24,
                                       padding: EdgeInsets.zero,
                                       constraints: const BoxConstraints(),
                                       icon: const Icon(Icons.file_download, color: Colors.orangeAccent),
                                       tooltip: "Download General Ledger",
                                   onPressed: () async {
                                     final api = Provider.of<SalesOrderProvider>(context, listen: false);

                                     // Step 1: Ask user for "From Date"
                                     final DateTime? fromDate = await showDatePicker(
                                       context: context,
                                       initialDate: DateTime.now().subtract(const Duration(days: 30)),
                                       firstDate: DateTime(2020),
                                       lastDate: DateTime.now(),
                                       helpText: "Select From Date",
                                     );

                                     if (fromDate == null) return; // user cancelled

                                     // Step 2: Ask user for "To Date"
                                     final DateTime? toDate = await showDatePicker(
                                       context: context,
                                       initialDate: DateTime.now(),
                                       firstDate: fromDate,
                                       lastDate: DateTime.now(),
                                       helpText: "Select To Date",
                                     );

                                     if (toDate == null) return; // user cancelled

                                     // Step 3: Format selected dates
                                     String formatDate(DateTime date) =>
                                         "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

                                     final fromDateStr = formatDate(fromDate);
                                     final toDateStr = formatDate(toDate);

                                     // Step 4: Fetch Ledger
                                     final ledgerJson = await api.apiService!.FetchGeneralLedger(
                                       context,
                                       customer.name!,
                                       fromDateStr,
                                       toDateStr,
                                     );

                                     if (ledgerJson != null) {
                                       // Step 5: Build HTML & Generate PDF
                                       final html = BuildLedgerHtml(
                                         ledgerJson,
                                         fromDateStr,
                                         toDateStr,
                                         fallbackCustomerName: customer.name,
                                       );

                                       final pdfBytes =
                                       await api.apiService!.generatePdfFromHtml(context, html);

                                       if (pdfBytes != null) {
                                         await saveAndOpenPdf(
                                           pdfBytes as List<int>,
                                           "General_Ledger_${customer.name}",
                                         );
                                         ScaffoldMessenger.of(context).showSnackBar(
                                           const SnackBar(content: Text("PDF Downloaded Successfully")),
                                         );
                                       }
                                     }
                                   },
                                     ),
                                     const SizedBox(height: 4),
                                     const Text(
                                       "GL",
                                       style: TextStyle(fontSize: 12, color: Colors.black54),
                                     ),
                                   ],
                                 ),


                                 // Accounts Receivable
                                 Column(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     // IconButton(
                                     //   iconSize: 24,
                                     //   padding: EdgeInsets.zero,
                                     //   constraints: const BoxConstraints(),
                                     //   icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                     //   tooltip: "Download Accounts Receivable",
                                     //   onPressed: () async {
                                     //     // 1️⃣ Pick date
                                     //     final pickedDate = await showDatePicker(
                                     //       context: context,
                                     //       initialDate: DateTime.now(),
                                     //       firstDate: DateTime(2000),
                                     //       lastDate: DateTime.now(),
                                     //     );
                                     //
                                     //     if (pickedDate == null) return;
                                     //
                                     //     final postingDate =
                                     //         "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                     //
                                     //     // 2️⃣ Pick aging range
                                     //     final range = await showRangeInputDialog(context);
                                     //     if (range == null) return;
                                     //
                                     //     showLoadingDialog(context);
                                     //
                                     //     try {
                                     //       final provider = Provider.of<SalesOrderProvider>(context, listen: false);
                                     //       final api = provider.apiService!;
                                     //       final company = await _sharedPrefService.getCompany();
                                     //       final party = customer.name!;
                                     //
                                     //       // 3️⃣ Fetch report
                                     //       final report = await api.fetchAccountsReceivable(
                                     //         context,
                                     //         company!,
                                     //         postingDate,
                                     //         party,
                                     //         range,
                                     //       );
                                     //
                                     //       if (report == null) return;
                                     //
                                     //       // 4️⃣ Build human-readable labels
                                     //       final rangeLabel = buildRangeLabel(range);
                                     //
                                     //       final letterheadContent =
                                     //       await api.fetchLetterHeadContent(context);
                                     //
                                     //       final html = buildAccountsReceivableHtml(
                                     //         report,
                                     //         party,
                                     //         postingDate,
                                     //         rangeLabel,
                                     //         letterheadContent,
                                     //         provider.domain,
                                     //       );
                                     //
                                     //       final pdfBytes = await api.generatePdfFromHtml(context, html);
                                     //
                                     //       if (pdfBytes != null) {
                                     //         await saveAndOpenPdf(
                                     //           pdfBytes,
                                     //           "Accounts_Receivable_${party}_$postingDate.pdf",
                                     //         );
                                     //       }
                                     //     } finally {
                                     //       Navigator.pop(context);
                                     //     }
                                     //   },
                                     //
                                     // ),
                                     IconButton(
                                       iconSize: 24,
                                       padding: EdgeInsets.zero,
                                       constraints: const BoxConstraints(),
                                       icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                       tooltip: "Download Accounts Receivable",
                                       onPressed: () async {
                                         final result = await showReceivableFilterDialog(context);
                                         if (result == null) return;

                                         // final postingDate =
                                         //     "${result.postingDate.year}-${result.postingDate.month.toString().padLeft(2, '0')}-${result.postingDate.day.toString().padLeft(2, '0')}";
                                         final postingDate = formatDateForApi(result.postingDate);

                                         showLoadingDialog(context);

                                         try {
                                           final provider =
                                           Provider.of<SalesOrderProvider>(context, listen: false);
                                           final api = provider.apiService!;
                                           final company = await _sharedPrefService.getCompany();
                                           final party = customer.name!;

                                           final report = await api.fetchAccountsReceivable(
                                             context,
                                             company!,
                                             postingDate,
                                             party,
                                             result.range,
                                           );

                                           if (report == null) return;

                                           final rangeLabel = buildRangeLabel(result.range);

                                           final letterheadContent =
                                           await api.fetchLetterHeadContent(context);

                                           final html = buildAccountsReceivableHtml(
                                             report,
                                             party,
                                             postingDate,
                                             rangeLabel,
                                             letterheadContent,
                                             provider.domain,
                                           );

                                           final pdfBytes =
                                           await api.generatePdfFromHtml(context, html);

                                           if (pdfBytes != null) {
                                             await saveAndOpenPdf(
                                               pdfBytes,
                                               "Accounts_Receivable_${party}_$postingDate.pdf",
                                             );
                                           }
                                         } finally {
                                           Navigator.pop(context);
                                         }
                                       },
                                     ),

                                     const SizedBox(height: 4),
                                 const Text(
                                   "AR",
                                   style: TextStyle(fontSize: 12, color: Colors.black54),
                                 ),
                                 ]),


                                 Column(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     IconButton(
                                       iconSize: 24,
                                       padding: EdgeInsets.zero,
                                       constraints: const BoxConstraints(),
                                       icon: const Icon(Icons.location_on, color: Colors.blue),
                                       tooltip: "View Location",
                                    onPressed: () async {
                                      final api = Provider.of<SalesOrderProvider>(context, listen: false);
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

                                        Navigator.pop(context);

                                        if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
                                          final shouldFetch = await showDialog<bool>(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text("Location Not Found"),
                                              content: const Text(
                                                  "No location found. Do you want to fetch from this device?"),
                                              actions: [
                                                TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: const Text("No")),
                                                TextButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    child: const Text("Yes")),
                                              ],
                                            ),
                                          );

                                          if (shouldFetch == true) {
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (ctx) =>
                                              const Center(child: CircularProgressIndicator()),
                                            );

                                            final position = await _getDeviceLocation(context);
                                            Navigator.pop(context);
                                            if (position != null) {
                                              lat = position.latitude;
                                              lng = position.longitude;
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Location not available.")),
                                            );
                                            return;
                                          }
                                        }

                                        if (lat != null && lng != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (ctx) => CustomerMapScreen(
                                                latitude: lat!,
                                                longitude: lng!,
                                                customerName: customer.name!,
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("No location data available.")),
                                          );
                                        }
                                      } catch (e) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Error: $e")),
                                        );
                                      }
                                    },
                                     ),
                                     const SizedBox(height: 4),
                                     const Text(
                                       "Location",
                                       style: TextStyle(fontSize: 12, color: Colors.black54),
                                     ),
                                   ],
                                 ),
                               ],
                             ),
                        ]),


                      ));
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
  String buildRangeLabel(String range) {
    final values = range.split(',').map(int.parse).toList();
    final labels = <String>[];

    int start = 0;
    for (final v in values) {
      labels.add("$start–$v");
      start = v + 1;
    }
    labels.add("${start}-Above");

    return labels.join(", ");
  }

  // Future<String?> showRangeInputDialog(BuildContext context) async {
  //   final controller = TextEditingController(text: "30,60,90,120");
  //
  //   return showDialog<String>(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text("Aging Ranges"),
  //       content: TextField(
  //         controller: controller,
  //         keyboardType: TextInputType.number,
  //         decoration: const InputDecoration(
  //           hintText: "Example: 30,60 or 30,60,90",
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text("Cancel"),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             final value = controller.text.trim();
  //             if (value.isEmpty) return;
  //             Navigator.pop(context, value);
  //           },
  //           child: const Text("Continue"),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Future<ReceivableFilterResult?> showReceivableFilterDialog(
      BuildContext context,
      ) async {
    DateTime selectedDate = DateTime.now();
    final rangeController = TextEditingController(text: "30,60,90,120");

    return showDialog<ReceivableFilterResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Accounts Receivable Filter"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date Picker Field
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );

                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Posting Date",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      // child: Text(
                      //   "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                      // ),
                      child: Text(
                        formatDateForDisplay(selectedDate),
                      ),

                    ),
                  ),

                  const SizedBox(height: 16),

                  // Aging Range Field
                  TextField(
                    controller: rangeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Aging Ranges",
                      hintText: "Example: 30,60,90",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final range = rangeController.text.trim();
                    if (range.isEmpty) return;

                    Navigator.pop(
                      context,
                      ReceivableFilterResult(
                        postingDate: selectedDate,
                        range: range,
                      ),
                    );
                  },
                  child: const Text("Continue"),
                ),
              ],
            );
          },
        );
      },
    );
  }


}
class ReceivableFilterResult {
  final DateTime postingDate;
  final String range;

  ReceivableFilterResult({
    required this.postingDate,
    required this.range,
  });
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
            },
            child: Icon(Icons.add),
          ),
          GestureDetector(
            onTap: () {
              onTapClose.call();

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
            },
            child: Icon(Icons.minimize),
          ),
        ],
      ),
    );
  }
}
