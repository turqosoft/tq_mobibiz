
import 'package:flutter/material.dart';

class PurchaseReceipt {
  int? docstatus;
  String? supplier;
  String? branch;
  String? warehouse;
  String? rejectedWarehouse;
  int? setPostingTime;
  String? postingDate;
  String? purchaseOrder;
  List<PurchaseItem>? items;

  PurchaseReceipt({
    this.docstatus = 1, // ✅ Default to 1 (Submitted)
    this.supplier,
    this.purchaseOrder,
    this.branch,
    this.warehouse,
    this.rejectedWarehouse,
    this.setPostingTime,
    this.postingDate,
    this.items,
  });

  factory PurchaseReceipt.fromJson(Map<String, dynamic> json) {
    return PurchaseReceipt(
      docstatus: json['docstatus'] ?? 1, // ✅ Default to 1 if null
      supplier: json['supplier'],
      branch: json['branch'],
      warehouse: json['set_warehouse'], // ✅ Correct key
      rejectedWarehouse: json['rejected_warehouse'],
      setPostingTime: json['set_posting_time'],
      postingDate: json['posting_date'],
      items: (json['items'] as List?)
          ?.map((item) => PurchaseItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "docstatus": docstatus,
      "purchase_order": purchaseOrder,
      "supplier": supplier,
      "branch": branch,
      "set_warehouse": warehouse,
      "rejected_warehouse": rejectedWarehouse,
      "set_posting_time": setPostingTime,
      "posting_date": postingDate,
      "items": items?.map((item) => item.toJson()).toList(),
    };
  }
}

// class PurchaseItem {
//   String? itemCode;
//   String? itemName;
//   double qty;
//   double rejectedQty;
//   double wastageQuantity;
//   double excessQuantity;
//   double priceListRate;
//     double? receivedQty; // ✅ New field added

//   String? uom;
//   String? purchaseOrder;
//   String? purchaseOrderItem;
//   String? itemPackDetails; // ✅ NEW

//   late TextEditingController acceptedQtyController;
//   late TextEditingController rejectedQtyController;
//   late TextEditingController wastageQtyController;
//   late TextEditingController excessQtyController;
//   late TextEditingController rejectedWarehouseController;

//   PurchaseItem({
//     this.itemCode,
//     this.itemName,
//     this.qty = 0.0,
//     this.rejectedQty = 0.0,
//     this.wastageQuantity = 0.0,
//     this.excessQuantity = 0.0,
//     this.priceListRate = 0.0,
//     this.uom,
//     this.purchaseOrder,
//     this.purchaseOrderItem,
//     this.itemPackDetails, // ✅ NEW
//         this.receivedQty, // ✅ Include in constructor

//   }) {
//     acceptedQtyController = TextEditingController(text: qty.toStringAsFixed(2));
//     rejectedQtyController = TextEditingController(text: rejectedQty.toStringAsFixed(2));
//     wastageQtyController = TextEditingController(text: wastageQuantity.toStringAsFixed(2));
//     excessQtyController = TextEditingController(text: excessQuantity.toStringAsFixed(2));
//     rejectedWarehouseController = TextEditingController();
//   }

//   factory PurchaseItem.fromJson(Map<String, dynamic> json) {
//     var item = PurchaseItem(
//       itemCode: json['item_code'],
//       itemName: json['item_name'],
//       qty: (json['qty'] ?? 0.0).toDouble(),
//       rejectedQty: (json['rejected_qty'] ?? 0.0).toDouble(),
//       wastageQuantity: (json['wastage_quantity'] ?? 0.0).toDouble(),
//       excessQuantity: (json['excess_quantity'] ?? 0.0).toDouble(),
//       priceListRate: (json['price_list_rate'] ?? 0.0).toDouble(),
//       uom: json['uom'],
//       purchaseOrder: json['purchase_order'],
//       purchaseOrderItem: json['purchase_order_item'],
//       itemPackDetails: json['item_pack_details'], // ✅ NEW
//             receivedQty: json['received_qty'] != null
//           ? (json['received_qty']).toDouble()
//           : 0.0, // ✅ Parse receivedQty
//     );

//     item.acceptedQtyController.text = item.qty.toStringAsFixed(2);
//     item.rejectedQtyController.text = item.rejectedQty.toStringAsFixed(2);
//     item.wastageQtyController.text = item.wastageQuantity.toStringAsFixed(2);
//     item.excessQtyController.text = item.excessQuantity.toStringAsFixed(2);

//     return item;
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       "item_code": itemCode,
//       "item_name": itemName,
//       "qty": double.tryParse(acceptedQtyController.text) ?? 0.0,
//       "rejected_qty": double.tryParse(rejectedQtyController.text) ?? 0.0,
//       "wastage_quantity": double.tryParse(wastageQtyController.text) ?? 0.0,
//       "excess_quantity": double.tryParse(excessQtyController.text) ?? 0.0,
//       "price_list_rate": priceListRate,
//       "uom": uom,
// 'received_qty': receivedQty ?? 0.0,

//       "purchase_order": purchaseOrder,
//       "purchase_order_item": purchaseOrderItem,
//       if ((double.tryParse(rejectedQtyController.text) ?? 0.0) > 0)
//         "rejected_warehouse": rejectedWarehouseController.text,
//       if (itemPackDetails != null && itemPackDetails!.isNotEmpty)
//         "item_pack_details": itemPackDetails, // ✅ NEW
//     };
//   }
// }

class PurchaseItem {
  String? itemCode;
  String? itemName;
  double qty;
  double rejectedQty;
  double wastageQuantity;
  double excessQuantity;
  double priceListRate;
  double? receivedQty;
  double? finalReceivedQty; // <-- This will be used only for API
  bool hasBatchNo = false;

  String? uom;
  String? purchaseOrder;
  String? purchaseOrderItem;
  String? itemPackDetails;
  late TextEditingController batchNoController;
  late TextEditingController acceptedQtyController;
  late TextEditingController rejectedQtyController;
  late TextEditingController wastageQtyController;
  late TextEditingController excessQtyController;
  late TextEditingController rejectedWarehouseController;
  VoidCallback? onAcceptedQtyChanged;

  PurchaseItem({
    this.itemCode,
    this.itemName,
    this.qty = 0.0,
    this.rejectedQty = 0.0,
    this.wastageQuantity = 0.0,
    this.excessQuantity = 0.0,
    this.priceListRate = 0.0,
    this.uom,
    this.purchaseOrder,
    this.purchaseOrderItem,
    this.itemPackDetails,
    this.hasBatchNo = false,
    this.receivedQty,
  }) {
    acceptedQtyController = TextEditingController(
      text: defaultAcceptedQty.toStringAsFixed(2),
    );
    rejectedQtyController = TextEditingController(
      text: rejectedQty.toStringAsFixed(2),
    );
    wastageQtyController = TextEditingController(
      text: wastageQuantity.toStringAsFixed(2),
    );
    excessQtyController = TextEditingController(
      text: excessQuantity.toStringAsFixed(2),
    );
    rejectedWarehouseController = TextEditingController();
    batchNoController = TextEditingController();

        initAcceptedQtyListener(); // ✅ Set up listener

  }

    /// ✅ Listener to notify UI when acceptedQtyController changes
  void initAcceptedQtyListener() {
    acceptedQtyController.addListener(() {
      if (onAcceptedQtyChanged != null) {
        onAcceptedQtyChanged!();
      }
    });
  }

  /// ✅ Computed accepted quantity: Ordered - Received
  double get defaultAcceptedQty {
    final ordered = qty;
    final received = receivedQty ?? 0.0;
    return (ordered - received).clamp(0.0, double.infinity);
  }

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    var item = PurchaseItem(
      itemCode: json['item_code'],
      itemName: json['item_name'],
      qty: (json['qty'] ?? 0.0).toDouble(),
      rejectedQty: (json['rejected_qty'] ?? 0.0).toDouble(),
      wastageQuantity: (json['wastage_quantity'] ?? 0.0).toDouble(),
      excessQuantity: (json['excess_quantity'] ?? 0.0).toDouble(),
      priceListRate: (json['price_list_rate'] ?? 0.0).toDouble(),
      uom: json['uom'],
      purchaseOrder: json['purchase_order'],
      purchaseOrderItem: json['purchase_order_item'],
      itemPackDetails: json['item_pack_details'],
      receivedQty: json['received_qty'] != null
          ? (json['received_qty']).toDouble()
          : 0.0,
      hasBatchNo: json['has_batch_no'] == 1,
    );

    item.acceptedQtyController.text =
        item.defaultAcceptedQty.toStringAsFixed(2);
    item.rejectedQtyController.text =
        item.rejectedQty.toStringAsFixed(2);
    item.wastageQtyController.text =
        item.wastageQuantity.toStringAsFixed(2);
    item.excessQtyController.text =
        item.excessQuantity.toStringAsFixed(2);
    item.initAcceptedQtyListener(); // ✅ Again for fromJson

    return item;
  }

  Map<String, dynamic> toJson() {
    return {
      "item_code": itemCode,
      "item_name": itemName,
      "qty": double.tryParse(acceptedQtyController.text) ?? 0.0,
      "rejected_qty": double.tryParse(rejectedQtyController.text) ?? 0.0,
      "wastage_quantity": double.tryParse(wastageQtyController.text) ?? 0.0,
      "excess_quantity": double.tryParse(excessQtyController.text) ?? 0.0,
      "price_list_rate": priceListRate,
      "uom": uom,
      // "received_qty": finalReceivedQty ?? receivedQty ?? 0.0,
      "received_qty":
      (double.tryParse(acceptedQtyController.text) ?? 0.0) +
          (double.tryParse(rejectedQtyController.text) ?? 0.0),

      "purchase_order": purchaseOrder,
      "purchase_order_item": purchaseOrderItem,
      if (hasBatchNo && batchNoController.text.isNotEmpty)
        "batch_no": batchNoController.text.trim(),

      if ((double.tryParse(rejectedQtyController.text) ?? 0.0) > 0)
        "rejected_warehouse": rejectedWarehouseController.text,
      if (itemPackDetails != null && itemPackDetails!.isNotEmpty)
        "item_pack_details": itemPackDetails,
    };
  }
    void dispose() {
    acceptedQtyController.dispose();
    rejectedQtyController.dispose();
    wastageQtyController.dispose();
    excessQtyController.dispose();
    rejectedWarehouseController.dispose();
    batchNoController.dispose();
    }
}
