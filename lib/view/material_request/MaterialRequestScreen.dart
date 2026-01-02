import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/model/material_request_model.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';

class MaterialRequestScreen extends StatefulWidget {
  final Map<String, dynamic>? materialRequest;

  MaterialRequestScreen({this.materialRequest});

  @override
  _MaterialRequestScreenState createState() => _MaterialRequestScreenState();
}

class _MaterialRequestScreenState extends State<MaterialRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _materialRequestTypeController = TextEditingController();
  final _setWarehouseController = TextEditingController();
  final _itemCodeController = TextEditingController();
  DateTime? _scheduleDate;

  final FocusNode _itemCodeFocusNode = FocusNode();
  final FocusNode _warehouseFocusNode = FocusNode();
  final LayerLink _itemCodeLayerLink = LayerLink();
  final LayerLink _warehouseLayerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Map<String, String?>> _itemSuggestions = [];

  // List<String> _itemSuggestions = [];
  List<String> _warehouseSuggestions = [];
  List<MaterialRequestItem> _selectedItems = [];

  String? _selectedMaterialRequestType;

  @override
  void initState() {
    super.initState();
    if (widget.materialRequest != null) {
      // Prepopulate fields if data is available
      _setWarehouseController.text = widget.materialRequest!['set_warehouse'] ?? '';
      _selectedMaterialRequestType = widget.materialRequest!['material_request_type'];
      _scheduleDate = widget.materialRequest!['schedule_date'] != null
          ? DateTime.parse(widget.materialRequest!['schedule_date'])
          : null;



// Extracting items if available
if (widget.materialRequest!.containsKey('items')) {
  _selectedItems = (widget.materialRequest!['items'] as List)
      .map((item) => MaterialRequestItem(
            itemCode: item['item_code'],
            itemName: item['item_name'] ?? 'Unknown', // Include itemName
            qty: item['qty'],
          ))
      .toList();
}
    }
  }

  void _fetchWarehouseSuggestions(String query) async {
    if (query.isEmpty) {
      _warehouseSuggestions.clear();
      _hideOverlay();
      return;
    }

    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      final results = await provider.fetchWarehouseCodes(query);
      setState(() {
        _warehouseSuggestions = results;
      });
      if (_warehouseSuggestions.isNotEmpty && _warehouseFocusNode.hasFocus) {
        _showOverlay(layerLink: _warehouseLayerLink, isWarehouse: true);
      } else {
        _hideOverlay();
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      _hideOverlay();
    }
  }



void _fetchItemSuggestions(String query) async {
  if (query.isEmpty) {
    _itemSuggestions.clear();
    _hideOverlay();
    return;
  }

  final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  try {
    final results = await provider.fetchItems(query); // Adjusted to fetch items with names and codes
    setState(() {
      _itemSuggestions = results
          .map((item) => {'item_code': item['item_code'], 'item_name': item['item_name']})
          .toList();
    });
    if (_itemSuggestions.isNotEmpty && _itemCodeFocusNode.hasFocus) {
      _showOverlay(layerLink: _itemCodeLayerLink);
    } else {
      _hideOverlay();
    }
  } catch (e) {
    print('Error fetching suggestions: $e');
    _hideOverlay();
  }
}


void _showOverlay({required LayerLink layerLink, bool isWarehouse = false}) {
  _hideOverlay(); // Remove any existing overlay before showing a new one

  final renderBox = isWarehouse
      ? _warehouseFocusNode.context!.findRenderObject() as RenderBox
      : _itemCodeFocusNode.context!.findRenderObject() as RenderBox;
  final size = renderBox.size;
  final offset = renderBox.localToGlobal(Offset.zero);

  _overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      left: offset.dx,
      top: offset.dy + size.height,
      width: size.width,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: Offset(0.0, size.height),
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 200, // Limit height to make suggestions scrollable
            ),
            child: Scrollbar(
              child: ListView.builder(
                                padding: EdgeInsets.zero, // Fix: Removes unwanted padding

                shrinkWrap: true,
                itemCount: isWarehouse ? _warehouseSuggestions.length : _itemSuggestions.length,
                itemBuilder: (context, index) {
                  if (isWarehouse) {
                    // **Fix: Explicitly cast to String**
                    final String suggestion = _warehouseSuggestions[index];

                    return ListTile(
                      title: Text(suggestion),
                      onTap: () {
                        _setWarehouseController.text = suggestion;
                        _hideOverlay();
                      },
                    );
                  } else {
                    // **Fix: Explicitly cast to Map<String, String?>**
                    final Map<String, String?> suggestion = _itemSuggestions[index];

                    final String itemName = suggestion['item_name'] ?? 'Unknown';
                    final String itemCode = suggestion['item_code'] ?? 'Unknown';

                    return ListTile(
                      title: Text(itemName),
                      subtitle: Text('Code: $itemCode'),
                      onTap: () {
                        _showQuantityDialog(
                          itemCode: itemCode,
                          itemName: itemName,
                          onConfirm: (quantity) {
                            setState(() {
                              _selectedItems.add(
                                MaterialRequestItem(
                                  itemCode: itemCode,
                                  itemName: itemName,
                                  qty: quantity,
                                ),
                              );
                            });
                          },
                        );
                        _hideOverlay();
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Overlay.of(context).insert(_overlayEntry!);
}


  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showQuantityDialog({
      required String itemName,

    required String itemCode,
    double? initialQuantity,
    required void Function(double quantity) onConfirm,
  }) {
    _hideOverlay();

    final FocusNode _dialogQtyFocusNode = FocusNode();
    final TextEditingController _dialogQtyController = TextEditingController(
      text: initialQuantity != null ? initialQuantity.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // title: Text('Enter Quantity for $itemCode '),
          title: Text('Enter Quantity'),
content: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: [
    Text('Item Name: $itemName', style: TextStyle(fontWeight: FontWeight.bold)),
    SizedBox(height: 8),
    Text('Item Code: $itemCode'),
    SizedBox(height: 16),
    TextField(
      controller: _dialogQtyController,
      focusNode: _dialogQtyFocusNode,
      decoration: InputDecoration(labelText: 'Enter Quantity'),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    ),
  ],
),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final quantity = double.parse(_dialogQtyController.text);
                if (quantity > 0) {
                  onConfirm(quantity);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Quantity must be positive and greater than zero'),
                  ));
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    ).then((_) {
      _dialogQtyFocusNode.dispose();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dialogQtyFocusNode.requestFocus();
    });
  }


void _showEditQuantityDialog(int index) {
  final item = _selectedItems[index];

  final itemName = _itemSuggestions.firstWhere(
        (suggestion) => suggestion['item_code'] == item.itemCode,
        orElse: () => {'item_name': 'Unknown'})['item_name'];


_showQuantityDialog(
  itemCode: item.itemCode,
  itemName: item.itemName, // Pass the itemName directly from the item
  initialQuantity: item.qty,
  onConfirm: (quantity) {
    setState(() {
      _selectedItems[index] = MaterialRequestItem(
        itemCode: item.itemCode,
        itemName: item.itemName, // Ensure itemName is retained
        qty: quantity,
      );
    });
  },
);

}
  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedItems.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    // Validate that at least one item is selected
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please add at least one item to the Material Request'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Validate that a schedule date is selected
    if (_scheduleDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select a schedule date'),
        backgroundColor: Colors.red,
      ));
      return;
    }




final materialRequest = MaterialRequest(
  materialRequestType: _selectedMaterialRequestType!,
  setWarehouse: _setWarehouseController.text,
  scheduleDate: DateFormat('yyyy-MM-dd').format(_scheduleDate!),
  items: _selectedItems.map((item) => MaterialRequestItem(
    itemCode: item.itemCode,
    itemName: item.itemName, // Ensure itemName is included
    qty: item.qty,
  )).toList(),
);

    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    if (widget.materialRequest == null) {
      // Creating a new material request
      await provider.createMaterialRequest(context, materialRequest);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Material Request Created'),
      ));
    } else {
      // Updating an existing material request
      final requestName = widget.materialRequest!['name'];

      final updatedMaterialRequest = {
        "material_request_type": _selectedMaterialRequestType!,
        "set_warehouse": _setWarehouseController.text,
        "schedule_date": DateFormat('yyyy-MM-dd').format(_scheduleDate!),
        "items": _selectedItems.map((item) => {
          "item_code": item.itemCode,
          "qty": item.qty,
        }).toList(),
      };

      final success = await provider.updateMaterialRequest(
        context,
        requestName,
        updatedMaterialRequest,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Material Request Updated Successfully'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to Update Material Request'),
        ));
      }
    }

    Navigator.pop(context);
  }
}
  @override
  void dispose() {
    _itemCodeController.dispose();
    _itemCodeFocusNode.dispose();
    _setWarehouseController.dispose();
    _warehouseFocusNode.dispose();
    super.dispose();
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.blueGrey[50],
    appBar: widget.materialRequest != null
        ? AppBar(
            backgroundColor: AppColors.primaryColor,
            title: Text(
              'Material Request',
              style: TextStyle(color: Colors.white),
            ),
            leading: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(
                Icons.arrow_back,
                color: const Color.fromARGB(255, 255, 254, 254),
              ),
            ),
          )
        : null,
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Center(
              child: Text(
                widget.materialRequest == null
                    ? 'New Material Request'
                    : 'Edit Material Request',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 27, 27, 28),
                  letterSpacing: 1.5,
                 
                ),
              ),
            ),
            SizedBox(height: 20),

              if (widget.materialRequest != null)
                Text(
                  'ID: ${widget.materialRequest!['name'] ?? ''}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  
                ),
              if (widget.materialRequest != null)
                SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedMaterialRequestType,
                decoration: InputDecoration(
                  labelText: 'Material Request Type',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  'Purchase',
                  'Material Transfer',
                  'Material Issue',
                  'Manufacture',
                  'Customer Provided',
                ].map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedMaterialRequestType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select the material request type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              CompositedTransformTarget(
                link: _warehouseLayerLink,
                child: Focus(
                  focusNode: _warehouseFocusNode,
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) {
                      _hideOverlay();
                    }
                  },
                  child: TextFormField(
                    controller: _setWarehouseController,
                    decoration: InputDecoration(
                      labelText: 'Set Warehouse',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: _fetchWarehouseSuggestions,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the warehouse';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 10),
              CompositedTransformTarget(
                link: _itemCodeLayerLink,
                child: Focus(
                  focusNode: _itemCodeFocusNode,
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) {
                      _hideOverlay();
                    }
                  },
                  child: TextFormField(
                    controller: _itemCodeController,
                    decoration: InputDecoration(
                      labelText: 'Item',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: _fetchItemSuggestions,
                    validator: (value) {
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 10),
              ListTile(
                title: Text('Schedule Date'),
                subtitle: _scheduleDate == null
                    ? Text('No date selected')
                    : Text(DateFormat('dd-MM-yyyy').format(_scheduleDate!)),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null && pickedDate != _scheduleDate) {
                    setState(() {
                      _scheduleDate = pickedDate;
                    });
                  }
                },
              ),
              SizedBox(height: 10),


              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _selectedItems.length,
                itemBuilder: (context, index) {
                  final item = _selectedItems[index];
                  return Card(
                    elevation: 8, // Higher elevation for better shadow effect
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10), // Margin around cards
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [const Color.fromARGB(255, 239, 245, 248), const Color.fromARGB(255, 239, 245, 248)], // Gradient background
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(12.0), // Padding inside the card
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start
                        children: [
                          Row(
                            children: [
                              Icon(Icons.label, color: Colors.deepPurple, size: 20), // Icon for item name
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.itemName, // Display itemName
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6), // Small gap between name and code
                          Row(
                            children: [
                              Icon(Icons.code, color: Colors.grey[700], size: 20), // Icon for item code
                              SizedBox(width: 8),
                              Text(
                                'Code: ${item.itemCode}', // Display itemCode
                                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Quantity: ${item.qty}', // Display quantity
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
                                    onPressed: () {
                                      _showEditQuantityDialog(index);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(index);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Submit', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



