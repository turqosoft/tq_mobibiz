//  // material_demand_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/model/material_demand_model.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/view/material_demand/MaterialDemandStatusScreen.dart';

class MaterialDemandScreen extends StatefulWidget {
  final String? demandName; // Optional for edit mode
  final MaterialDemand? materialDemand; // Optional for edit mode

  MaterialDemandScreen({this.demandName, this.materialDemand});

  @override
  _MaterialDemandScreenState createState() => _MaterialDemandScreenState();
}

class _MaterialDemandScreenState extends State<MaterialDemandScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _scheduleDate;
  List<Map<String, dynamic>> _items = [];
  final _searchController = TextEditingController();
  List<Map<String, String>> _filteredSuggestions = [];
  bool _isLoadingSuggestions = false;
bool _isUpdated = false; // Track if update is completed
  String? _selectedPurpose;


  @override
  void initState() {
    super.initState();
    if (widget.materialDemand != null) {
      // Initialize fields for edit mode
      _selectedPurpose = widget.materialDemand?.purpose;

      _scheduleDate =
          DateFormat('yyyy-MM-dd').parse(widget.materialDemand!.scheduleDate);

      _items = widget.materialDemand!.items.map((item) {
        return {
          'item_code': item.itemCode,
          'item_name': item.itemName,
          'qty': item.qty,
          'notes': item.notes,
          'uom': item.uom, // Include uom field
        };
      }).toList();
    } else {
      // Set default schedule date to today's date for create mode
      _scheduleDate = DateTime.now();
      _initializePurpose(); // <-- Add this

    }
  }
  Future<void> _initializePurpose() async {
    try {
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);
      final currentUser = await provider.getLoggedInUserIdentifier();
      if (currentUser == null) return;

      final additionalData = await provider.fetchAdditionalFields(currentUser);
      final customerDetails = await provider.fetchCustomerDetail(additionalData['customer_info']);
      final customerType = customerDetails['customer_type'];

      setState(() {
        _selectedPurpose = (customerType == 'Own Stalls') ? 'Material Transfer' : 'Sales';
      });
    } catch (e) {
      debugPrint('Failed to initialize purpose: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to determine purpose')),
      );
    }
  }

  void _fetchSuggestions(String query) async {
  if (query.isEmpty) {
    setState(() {
      _filteredSuggestions = [];
    });
    return;
  }

  setState(() {
    _isLoadingSuggestions = true;
  });

  try {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    final suggestions = await provider.fetchItemsDemand(context, query);

    setState(() {
      _filteredSuggestions = (suggestions ?? [])
          .map((item) => {
                'item_name': item['item_name'].toString(),
                'item_code': item['item_code'].toString(),
                'stock_uom': item['stock_uom'].toString(),
              })
          .toList();
    });
  } catch (e) {
    debugPrint('Error fetching suggestions: $e');
  } finally {
    setState(() {
      _isLoadingSuggestions = false;
    });
  }
}




  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog without deleting
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                // Delete the item and close the dialog
                setState(() {
                  _items.removeAt(index);
                });
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showQuantityDialog({
    required String itemCode,
    required String itemName,
    required String uom, // Add uom parameter

    bool isEdit = false,
    int? index,
  }) {
    final _qtyController = TextEditingController(
      text: isEdit && index != null ? _items[index]['qty'].toString() : '',
    );
    final _notesController = TextEditingController(
      text: isEdit && index != null ? _items[index]['notes'] : '',
    );
    final _qtyFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              isEdit ? 'Edit Quantity and Notes' : 'Add Details for $itemName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _qtyController,
                focusNode: _qtyFocusNode,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final quantity = double.tryParse(_qtyController.text);

                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Quantity must be greater than zero')),
                  );
                  return;
                }

                setState(() {
                  final item = {
                    'item_code': itemCode,
                    'item_name': itemName,
                    'qty': quantity,
                    'notes': _notesController.text,
                    'uom': uom, // Pass the uom value
                  };
                  if (isEdit && index != null) {
                    _items[index] = item;
                  } else {
                    _items.add(item);
                  }
                });

                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _qtyFocusNode.requestFocus();
    });
  }

void _submitForm() async {
  if (_formKey.currentState!.validate() &&
      _scheduleDate != null &&
      _items.isNotEmpty) {
    // final materialDemand = MaterialDemand(
    //   scheduleDate: DateFormat('yyyy-MM-dd').format(_scheduleDate!),
    //   items: _items.map((item) {
    //     return MaterialDemandItem(
    //       itemCode: item['item_code'],
    //       itemName: item['item_name'],
    //       qty: item['qty'],
    //       notes: item['notes'],
    //       uom: item['uom'],
    //     );
    //   }).toList(),
    // );
    final materialDemand = MaterialDemand(
      scheduleDate: DateFormat('yyyy-MM-dd').format(_scheduleDate!),
      items: _items.map((item) {
        return MaterialDemandItem(
          itemCode: item['item_code'],
          itemName: item['item_name'],
          qty: item['qty'],
          notes: item['notes'],
          uom: item['uom'],
        );
      }).toList(),
      purpose: _selectedPurpose, // Include purpose here
    );

    try {
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);
      if (widget.demandName != null) {
        final success = await provider.updateMaterialDemand(
          context,
          widget.demandName!,
          {'data': materialDemand.toJson()},
        );

        if (success) {
          debugPrint('Update successful: scheduleDate=$_scheduleDate, items=$_items');
          _showSummaryDialog(
            widget.demandName!,
            _scheduleDate,
            List.from(_items), // Pass a fresh copy of _items
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update Material Demand')),
          );
        }
      } else {
        await provider.createMaterialDemand(context, materialDemand);
      }

      setState(() {
        _scheduleDate = null;
        _items.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save Material Demand: $e')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please fill all required fields')),
    );
  }
}


void _showSummaryDialog(String demandName, DateTime? scheduleDate, List<Map<String, dynamic>> updatedItems) {
  showDialog(
    context: context,
    barrierDismissible: false, // ✅ Prevents closing by tapping outside or using back button
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false, // ✅ Prevents back button dismissal
        child: AlertDialog(
          title: Text('Update Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Material Demand "$demandName" has been updated successfully.'),
              SizedBox(height: 10),
              Text('Scheduled Date: ${scheduleDate != null ? DateFormat('dd-MM-yyyy').format(scheduleDate) : 'Not set'}'),
              SizedBox(height: 10),
              Text('Updated Items:'),
              if (updatedItems.isNotEmpty)
                ...updatedItems.map((item) => Text('- ${item['item_name']} (${item['qty']} ${item['uom']})')).toList()
              else
                Text('No items updated'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MaterialDemandStatusScreen()),
                );
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    },
  );
}




@override
  Widget build(BuildContext context) {
    return Scaffold(
              appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: AppColors.primaryColor,
        title: Text(widget.demandName != null ? 'Edit Material Demand' : 'Material Demand'),
              actions: [
        IconButton(
          icon: Icon(Icons.list, color: Colors.white), // List icon for navigation
          tooltip: 'View Material Demands',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MaterialDemandStatusScreen()),
            );
          },
        ),
      ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
    child: ListView(
      children: [
        SizedBox(height: 20),
        if (widget.demandName != null)
          Text(
            widget.demandName!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        SizedBox(height: 20),
        if (widget.demandName == null)
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Add Item',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
              suffixIcon: _isLoadingSuggestions
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            onChanged: _fetchSuggestions,
          ),
        SizedBox(height: 10),
        
        // Scrollable Item Suggestions
        if (_filteredSuggestions.isNotEmpty)
          SizedBox(
            height: 200, // Allows proper scrolling space
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200, // Ensures proper scrolling behavior
              ),
              child: Scrollbar( // Adds a visible scrollbar for better UX
                child: SingleChildScrollView(
                  child: Column(
                    children: _filteredSuggestions.map((suggestion) {
                      return ListTile(
                        title: Text(suggestion['item_name']!),
                        subtitle: Text('Code: ${suggestion['item_code']}'),
                        onTap: () {
                          _searchController.clear();
                          _filteredSuggestions.clear();
                          _showQuantityDialog(
                            itemCode: suggestion['item_code']!,
                            itemName: suggestion['item_name']!,
                            uom: suggestion['stock_uom']!,
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

        SizedBox(height: 10),
        ..._items.map((item) {
          final index = _items.indexOf(item);
          return Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 239, 245, 248),
                    Color.fromARGB(255, 239, 245, 248),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${index + 1}.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item['item_name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.code, color: Colors.grey[700], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Code: ${item['item_code']}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.straighten, color: Colors.grey[700], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'UOM: ${item['uom']}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantity: ${item['qty']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.deepPurple),
                            onPressed: () => _showQuantityDialog(
                              itemCode: _items[index]['item_code'],
                              itemName: _items[index]['item_name'],
                              uom: _items[index]['uom'],
                              index: index,
                              isEdit: true,
                            ),
                          ),
                          if (widget.demandName == null)
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmationDialog(index),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        SizedBox(height: 20),
        TextFormField(
          readOnly: true,
          enabled: false,
          initialValue: _selectedPurpose ?? '',
          decoration: InputDecoration(
            labelText: 'Purpose',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),


        SizedBox(height: 20),

        ListTile(
          title: Text('Schedule Date'),
          subtitle: Text(
            _scheduleDate == null
                ? 'No date selected'
                : DateFormat('dd-MM-yyyy').format(_scheduleDate!),
            style: TextStyle(
              fontWeight: widget.demandName != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: widget.demandName == null ? Icon(Icons.calendar_today) : null,
          onTap: widget.demandName == null
              ? () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _scheduleDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _scheduleDate = pickedDate;
                    });
                  }
                }
              : null,
        ),

        SizedBox(height: 20),

if (widget.demandName != null && !_isUpdated)
  ElevatedButton(
    onPressed: () {
      _submitForm();
      setState(() {
        _isUpdated = true; // Hide the update button after submission
      });
    },
    child: Text('Update'),
  ),

if (widget.demandName == null)
  ElevatedButton(
    onPressed: () {
      _submitForm();
    },
    child: Text('Submit'),
  ),


      ],
    ),
  ),
),
        );
  }
}
