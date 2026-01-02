import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/common/common_widgets.dart';
import 'customers_list_screen.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController addressLine1Controller = TextEditingController();
  final TextEditingController addressLine2Controller = TextEditingController();
  final TextEditingController countryController = TextEditingController(text: "India");
  final TextEditingController gstinController = TextEditingController();
  double? latitude;
  double? longitude;
  bool isFetchingLocation = false;
  bool locationFetched = false;



  // ⭐ Dropdown values
  String? selectedCustomerType = "Company";
  String? selectedGstCategory = "Unregistered";

  // ⭐ Dropdown options
  final List<String> customerTypeList = [
    "Company",
    "Individual",
    "Partnership",
  ];

  final List<String> gstCategoryList = [
    "Registered Regular",
    "Registered Composition",
    "Unregistered",
    "SEZ",
    "Overseas",
    "Deemed Export",
    "UIN Holders",
    "Tax Deductor",
    "Tax Collector",
    "Input Service Distributor",
  ];
  final List<String> stateList = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Goa", "Gujarat", "Haryana",
    "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur",
    "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
    "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal", "Delhi", "Jammu & Kashmir",
    "Ladakh", "Puducherry"
  ];
  String? selectedState = "Kerala";   // default or null

  String? _validateCustomerFields() {
    // 1️⃣ Customer Name Required
    if (nameController.text.trim().isEmpty) {
      return "Customer name is required";
    }

    // 2️⃣ Email OR Mobile — at least ONE required
    final email = emailController.text.trim();
    final mobile = mobileController.text.trim();

    if (email.isEmpty && mobile.isEmpty) {
      return "Either Email ID or Mobile Number is required";
    }

    // 3️⃣ If Email present → must be valid
    if (email.isNotEmpty && !_isValidEmail(email)) {
      return "Please enter a valid email address";
    }

    // 4️⃣ If Mobile present → must be 10 digits
    if (mobile.isNotEmpty && !_isValidMobile(mobile)) {
      return "Enter a valid 10-digit mobile number";
    }

    return null; // ✔ All good
  }


  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidMobile(String mobile) {
    final mobileRegex = RegExp(r'^[0-9]{10}$'); // exactly 10 digits
    return mobileRegex.hasMatch(mobile);
  }
  bool _isValidPostalCode(String code) {
    final pinRegex = RegExp(r'^[1-9][0-9]{5}$'); // India: 6 digits, cannot start with 0
    return pinRegex.hasMatch(code);
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoading() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }


  bool _isAddressProvided() {
    return addressLine1Controller.text.isNotEmpty ||
        addressLine2Controller.text.isNotEmpty ||
        cityController.text.isNotEmpty ||
        (selectedState != null && selectedState!.isNotEmpty) ||
        postalCodeController.text.isNotEmpty ||
        countryController.text.isNotEmpty;
  }


  Future<void> _saveCustomer() async {
    if (!locationFetched) {
      final proceed = await _showLocationWarningDialog();
      if (!proceed) return; // User canceled the operation
    }

    // ... existing validation code ...
    final validationError = _validateCustomerFields();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

// ⬇️ NEW ADDRESS VALIDATION CHECK
    final addressError = _validateAddress();
    if (addressError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(addressError)),
      );
      return; // STOP
    }
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer name is required")),
      );
      return;
    }

    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    final isDuplicate = await provider.customerAlreadyExists(
      nameController.text.trim(),
      context,
    );

// Check if customer name exists

    if (isDuplicate) {
      final continueCreation =
      await _showDuplicateConfirmationDialog(nameController.text);

      if (!continueCreation) {
        // User selected NO
        return;
      }
    }

    final primaryAddress = """
${addressLine1Controller.text}
${addressLine2Controller.text}
${cityController.text}
${selectedState ?? ''}
PIN Code: ${postalCodeController.text}
${countryController.text}
""";

    final data = {
      "doctype": "Customer",
      "customer_name": nameController.text,
      "gstin": gstinController.text,
      "customer_type": selectedCustomerType,
      "gst_category": selectedGstCategory,
      "email_id": emailController.text,
      "country": "India",
      "primary_address": primaryAddress,
      "mobile_no": mobileController.text,
      "latitude": latitude ?? 0.0,
      "longitude": longitude ?? 0.0,
    };

    _showLoading();
    final result = await provider.createNewCustomer(data, context);
    _hideLoading();
    if (result == true || result is String) {
      // ERPNext sometimes returns true or customer_name as string
      final createdCustomerName =
      result is String ? result : nameController.text;

      // 🔍 CHECK IF USER ENTERED ADDRESS
      if (!_isAddressProvided()) {
        // ---------------------------
        // NO ADDRESS → JUST NAVIGATE
        // ---------------------------
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Customer Created Successfully")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CustomersListScreen()),
        );

        return;
      }

      // -------------------------------------------
      // ADDRESS PROVIDED — CREATE ADDRESS DOCUMENT
      // -------------------------------------------
      final addressData = {
        "doctype": "Address",
        "address_type": "Billing",
        "country": "India",
        "gst_category": "Unregistered",
        "address_line1": addressLine1Controller.text,
        "address_line2": addressLine2Controller.text,
        "city": cityController.text,
        "state": selectedState ?? "",
        "pincode": postalCodeController.text,
        "links": [
          {
            "doctype": "Dynamic Link",
            "parentfield": "links",
            "parenttype": "Address",
            "link_doctype": "Customer",
            "link_name": createdCustomerName
          }
        ]
      };

      final addressResult =
      await provider.createAddressForCustomer(addressData, context);

      if (addressResult == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Customer & Address Created Successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Customer created without Address")),
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CustomersListScreen()),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.toString())),
      );
    }
  }

  Future<bool> _showDuplicateConfirmationDialog(String name) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Duplicate Customer"),
          content: Text(
              "A customer named \"$name\" already exists.\n\nDo you still want to continue?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes, Continue"),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _showLocationWarningDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Location Not Added"),
        content: const Text(
            "You have not fetched the device location.\n\nDo you want to create the customer without adding a location?"),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Yes, Continue"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _fetchLocation() async {
    // SHOW LOADING INDICATOR
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Navigator.pop(context);
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied")),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission permanently denied")),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        latitude = pos.latitude;
        longitude = pos.longitude;
        isFetchingLocation = false;
        locationFetched = true;       // ✅ IMPORTANT FIX
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location fetched: $latitude, $longitude")),
      );

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching location: $e")),
      );
    }
  }
  // String? _validateAddress() {
  //   // Check if user has started filling any required field
  //   bool startedAddress =
  //       addressLine1Controller.text.isNotEmpty ||
  //           cityController.text.isNotEmpty ||
  //           postalCodeController.text.isNotEmpty;
  //           // (selectedState != null && selectedState!.isNotEmpty) ||
  //           // countryController.text.isNotEmpty;
  //
  //   if (!startedAddress) {
  //     // User did NOT enter any required address field → OK (no address creation)
  //     return null;
  //   }
  //
  //   // Required fields validation
  //   if (addressLine1Controller.text.isEmpty) {
  //     return "Address Line 1 is required";
  //   }
  //   if (cityController.text.isEmpty) {
  //     return "City is required";
  //   }
  //   if (postalCodeController.text.isEmpty) {
  //     return "Postal Code is required";
  //   }
  //
  //   return null; // All required address fields OK
  // }
  String? _validateAddress() {
    // Check if user has started filling any required field
    bool startedAddress =
        addressLine1Controller.text.isNotEmpty ||
            cityController.text.isNotEmpty ||
            postalCodeController.text.isNotEmpty;

    if (!startedAddress) {
      // No address entered → OK (skip address creation)
      return null;
    }

    // Required fields
    if (addressLine1Controller.text.isEmpty) {
      return "Address Line 1 is required";
    }
    if (cityController.text.isEmpty) {
      return "City is required";
    }
    if (postalCodeController.text.isEmpty) {
      return "Postal Code is required";
    }

    // 🔹 NEW — Validate PIN Code
    if (!_isValidPostalCode(postalCodeController.text.trim())) {
      return "Please enter a valid 6-digit Postal Code (PIN)";
    }

    return null; // All OK
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "Add Customer",
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primaryColor,
        actions: Row(
          children: [
            isFetchingLocation
                ? const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
                : IconButton(
              icon: const Icon(Icons.location_on, color: Colors.white),
              onPressed: _fetchLocation,
            ),

            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveCustomer,
            ),
          ],
        ),

      ),

      body: SafeArea(   // <-- prevents overlap with system navigation bar
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [

                // GSTIN
                _buildField("GSTIN / UIN", gstinController),
                const SizedBox(height: 15),

                // CUSTOMER NAME
                _buildField("Customer Name", nameController),
                const SizedBox(height: 15),

                // ROW: EMAIL + MOBILE
                Row(
                  children: [
                    Expanded(child: _buildField("Email ID", emailController)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildField("Mobile Number", mobileController, keyboard: TextInputType.phone)),
                  ],
                ),
                const SizedBox(height: 15),

                // ROW: CUSTOMER TYPE + GST CATEGORY
                Row(
                  children: [
                    Expanded(child: _buildDropdownCustomerType()),
                    const SizedBox(width: 15),
                    Expanded(child: _buildDropdownGstCategory()),
                  ],
                ),
                const SizedBox(height: 15),

                // POSTAL CODE + CITY
                _buildTwoFieldRow(
                  "Postal Code",
                  postalCodeController,
                  "City/Town",
                  cityController,
                  keyboard1: TextInputType.number,
                ),
                const SizedBox(height: 15),

                // ADDRESS + STATE
                _buildTwoFieldRowCustom(
                  leftLabel: "Address Line 1",
                  leftController: addressLine1Controller,
                  rightWidget: _buildStateDropdown(),
                ),
                const SizedBox(height: 15),

                // ADDRESS2 + COUNTRY
                _buildTwoFieldRow(
                  "Address Line 2",
                  addressLine2Controller,
                  "Country",
                  countryController,
                ),
                const SizedBox(height: 30),
                if (latitude != null && longitude != null) ...[
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 250,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(latitude!, longitude!),
                        initialZoom: 16,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all,),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: 'com.example.sales_ordering_app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(latitude!, longitude!),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ]

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoFieldRowCustom({
    required String leftLabel,
    required TextEditingController leftController,
    required Widget rightWidget,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leftLabel,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              TextField(
                controller: leftController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              )
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(child: rightWidget),
      ],
    );
  }

  Widget _buildTwoFieldRow(
      String label1,
      TextEditingController controller1,
      String label2,
      TextEditingController controller2, {
        TextInputType keyboard1 = TextInputType.text,
        TextInputType keyboard2 = TextInputType.text,
      }) {
    return Row(
      children: [
        Expanded(
          child: _buildField(label1, controller1, keyboard: keyboard1),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildField(label2, controller2, keyboard: keyboard2),
        ),
      ],
    );
  }



  /// -------------------------------------------
  /// ⭐ TEXT FIELD BUILDER
  /// -------------------------------------------
  Widget _buildField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  /// -------------------------------------------
  /// ⭐ CUSTOMER TYPE DROPDOWN
  /// -------------------------------------------
  Widget _buildDropdownCustomerType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Customer Type",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade300, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCustomerType,
              isExpanded: true,
              items: customerTypeList
                  .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCustomerType = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "State/Province",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedState,
              isExpanded: true,
              items: stateList
                  .map((state) => DropdownMenuItem(
                value: state,
                child: Text(state),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedState = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  /// -------------------------------------------
  /// ⭐ GST CATEGORY DROPDOWN
  /// -------------------------------------------
  Widget _buildDropdownGstCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("GST Category",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade300, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedGstCategory,
              isExpanded: true,
              items: gstCategoryList
                  .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedGstCategory = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

