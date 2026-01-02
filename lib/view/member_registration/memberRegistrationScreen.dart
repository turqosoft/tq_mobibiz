import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/common/common_widgets.dart';

class MemberRegistrationScreen extends StatefulWidget {
  const MemberRegistrationScreen({super.key});

  @override
  State<MemberRegistrationScreen> createState() =>
      _MemberRegistrationScreenState();
}

class _MemberRegistrationScreenState extends State<MemberRegistrationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController aadharController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "Member Registration",
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primaryColor,

        // 🔹 ADD BOTH SAVE & LOCATION icons here
        actions: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.location_on, color: Colors.white, size: 28),
              tooltip: "Fetch Location",
              onPressed: () {
                print("Location icon pressed");
              },
            ),
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white, size: 28),
              tooltip: "Save Form",
              onPressed: () {
                print("Save pressed");
              },
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 10),

                // 🔹 Name
                const Text("Name", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameController,
                  decoration: _inputDecoration(),
                ),

                const SizedBox(height: 15),

// 🔹 DOB
                const Text(
                  "DOB",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),

                GestureDetector(
                  onTap: () async {
                    FocusScope.of(context).unfocus(); // Close any keyboard

                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 3650)), // default 10 years ago
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppColors.primaryColor,   // Header background
                              onPrimary: Colors.white,           // Header text color
                              onSurface: Colors.black,           // Body text color
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (pickedDate != null) {
                      dobController.text =
                      "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: dobController,
                      decoration: _inputDecoration().copyWith(
                        suffixIcon: Icon(Icons.calendar_month, color: AppColors.primaryColor),
                      ),
                    ),
                  ),
                ),


                const SizedBox(height: 15),

                // 🔹 Address
                const Text("Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 160,
                  child: TextField(
                    controller: addressController,
                    maxLines: null,
                    expands: true,
                    decoration: _inputDecoration(),
                  ),
                ),

                const SizedBox(height: 15),

                // 🔹 Aadhar
                const Text("AADHAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                TextField(
                  controller: aadharController,
                  keyboardType: TextInputType.number,   // ⭐ Shows numeric keyboard
                  decoration: _inputDecoration(),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),        // ⭐ Rounded corners
        borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),        // ⭐ Rounded corners
        borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),        // ⭐ Rounded corners
        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

}

