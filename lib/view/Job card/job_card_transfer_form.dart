

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

class JobCardTransferFormScreen extends StatefulWidget {
  final Map<String, dynamic> jobCard;

  const JobCardTransferFormScreen({required this.jobCard, Key? key})
      : super(key: key);

  @override
  _JobCardTransferFormScreenState createState() =>
      _JobCardTransferFormScreenState();
}

class _JobCardTransferFormScreenState extends State<JobCardTransferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late TextEditingController _stockEntryTypeController;
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _stockEntryTypeController =
        TextEditingController(text: 'Material Transfer for Manufacture');
    _items = List<Map<String, dynamic>>.from(widget.jobCard['items'] ?? []);
  }

  @override
  void dispose() {
    _stockEntryTypeController.dispose();
    super.dispose();
  }

Future<void> _editQuantity(int index) async {
  final TextEditingController quantityController = TextEditingController(
    text: _items[index]['required_qty'].toString(),
  );

  bool? result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Edit Quantity'),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          autofocus: true, // Automatically focuses the field
          decoration: InputDecoration(
            labelText: 'Quantity',
            hintText: 'Enter new quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Save'),
          ),
        ],
      );
    },
  );

  if (result == true) {
    setState(() {
      _items[index]['required_qty'] = double.tryParse(quantityController.text) ?? 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quantity updated')),
    );
  }
}

  Future<void> _submitMaterialTransfer() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isSubmitting = true;
    });

    final materialTransferData = {
      'data': {
        'stock_entry_type': _stockEntryTypeController.text,
        'work_order': widget.jobCard['work_order'],
        'bom_no': widget.jobCard['bom_no'],
        'job_card': widget.jobCard['name'],
        'items': _items.map((item) {
          return {
            's_warehouse': item['source_warehouse'],
            't_warehouse': widget.jobCard['wip_warehouse'],
            'item_code': item['item_code'],
            'item_name': item['item_name'],
            'qty': item['required_qty'],
            'uom': item['uom'],
            'job_card_item': item['name'] ?? 'N/A',
          };
        }).toList(),
      },
    };

    try {
      final success = await context
          .read<SalesOrderProvider>()
          .submitMaterialTransfer(context, materialTransferData);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Material Transfer Submitted Successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to Submit Material Transfer')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonAppBar(
//         title: 'Material Transfer',
//         onBackTap: () => Navigator.pop(context),
//         backgroundColor: AppColors.primaryColor,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Work Order ID: ${widget.jobCard['work_order'] ?? 'N/A'}',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 16),
//                 Text(
//                   'Job Card ID: ${widget.jobCard['name'] ?? 'N/A'}',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 16),

//                 TextFormField(
//                   controller: _stockEntryTypeController,
//                   decoration: InputDecoration(
//                     labelText: 'Stock Entry Type',
//                   ),
//                   readOnly: true, // Makes the field non-editable
//                   style: TextStyle(
//                     color: Colors.grey, // Optionally dim the text to indicate it's fixed
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 Text(
//                   'Items',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 8),
//                 _items.isEmpty
//                     ? Center(
//                         child: Text(
//                           'No Items Available',
//                           style: TextStyle(color: Colors.grey),
//                         ),
//                       )
//                       : ListView.builder(
//                           shrinkWrap: true,
//                           physics: NeverScrollableScrollPhysics(),
//                           itemCount: _items.length,
//                           itemBuilder: (context, index) {
//                             final item = _items[index];
//                             return Card(
//                               margin: const EdgeInsets.symmetric(vertical: 8),
//                               child: ListTile(
//                                 title: Text(item['item_name'] ?? 'Unknown Item'),
//                                 subtitle: Text(
//                                   'Item code: ${item['item_code']}\n'
//                                   'Quantity: ${item['required_qty']} ${item['uom']}\n'
//                                   'Source Warehouse: ${item['source_warehouse'] ?? 'N/A'}\n'
//                                   'Target Warehouse: ${widget.jobCard['wip_warehouse'] ?? 'N/A'}',
//                                 ),
//                                 trailing: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     IconButton(
//                                       icon: Icon(Icons.edit),
//                                       onPressed: () => _editQuantity(index),
//                                     ),
//                                     IconButton(
//                                       icon: Icon(Icons.delete),
//                                       color: Colors.red,
//                                       onPressed: () async {
//                                         final confirmed = await showDialog<bool>(
//                                           context: context,
//                                           builder: (context) {
//                                             return AlertDialog(
//                                               title: Text('Confirm Deletion'),
//                                               content: Text(
//                                                 'Are you sure you want to delete this item: ${item['item_name']}?',
//                                               ),
//                                               actions: [
//                                                 TextButton(
//                                                   onPressed: () => Navigator.of(context).pop(false),
//                                                   child: Text('Cancel'),
//                                                 ),
//                                                 ElevatedButton(
//                                                   onPressed: () => Navigator.of(context).pop(true),
//                                                   child: Text('Delete'),
//                                                 ),
//                                               ],
//                                             );
//                                           },
//                                         );

//                                         if (confirmed == true) {
//                                           setState(() {
//                                             _items.removeAt(index);
//                                           });
//                                           ScaffoldMessenger.of(context).showSnackBar(
//                                             SnackBar(content: Text('Item deleted')),
//                                           );
//                                         }
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),

//                 SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: _isSubmitting ? null : _submitMaterialTransfer,
//                   child: _isSubmitting
//                       ? CircularProgressIndicator(
//                           valueColor:
//                               AlwaysStoppedAnimation<Color>(Colors.white),
//                         )
//                       : Text('Submit'),
//                   style: ElevatedButton.styleFrom(
//                     minimumSize: Size(double.infinity, 50),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: CommonAppBar(
      title: 'Material Transfer',
      onBackTap: () => Navigator.pop(context),
      backgroundColor: AppColors.primaryColor,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Work Order ID'),
                  _buildInfoText('${widget.jobCard['work_order'] ?? 'N/A'}'),
                  SizedBox(height: 16),
                  _buildSectionTitle('Job Card ID'),
                  _buildInfoText('${widget.jobCard['name'] ?? 'N/A'}'),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _stockEntryTypeController,
                    decoration: InputDecoration(
                      labelText: 'Stock Entry Type',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  _buildSectionTitle('Items'),
                  SizedBox(height: 8),
                ],
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _items[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        // backgroundColor: AppColors.primaryLightColor,
                        backgroundColor: Colors.grey,

                        child: Text(
                          '${index + 1}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        item['item_name'] ?? 'Unknown Item',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text('Item code: ${item['item_code']}'),
                          Text('Quantity: ${item['required_qty']} ${item['uom']}'),
                          Text('Source Warehouse: ${item['source_warehouse'] ?? 'N/A'}'),
                          Text('Target Warehouse: ${widget.jobCard['wip_warehouse'] ?? 'N/A'}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editQuantity(index),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Confirm Deletion'),
                                  content: Text(
                                    'Are you sure you want to delete this item: ${item['item_name']}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                setState(() {
                                  _items.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Item deleted')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _items.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitMaterialTransfer,
                    icon: Icon(Icons.send),
                    label: _isSubmitting
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildSectionTitle(String title) {
  return Text(
    title,
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
  );
}

Widget _buildInfoText(String text) {
  return Text(
    text,
    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
  );
}
}