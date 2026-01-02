import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';

import '../../../utils/common/common_widgets.dart';
import '../../../utils/sharedpreference.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);


  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SharedPrefService _sharedPrefService = SharedPrefService();
  String? _savedPrinter;
  bool _autoSubmitPickList = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPrinter();
    _loadSubmitToggle();

  }
  Future<void> _loadSubmitToggle() async {
    final value = await _sharedPrefService.getAutoSubmitPickList();
    setState(() {
      _autoSubmitPickList = value;
    });
  }

  Future<void> _updateSubmitToggle(bool value) async {
    await _sharedPrefService.saveAutoSubmitPickList(value);
    setState(() {
      _autoSubmitPickList = value;
    });
  }
  Future<void> _loadSavedPrinter() async {
    final name = await _sharedPrefService.getPrinterName();
    final address = await _sharedPrefService.getPrinterAddress();
    setState(() {
      _savedPrinter = name?.isNotEmpty == true ? name : address;
    });
  }

  Future<void> _pickPrinter() async {
    final device = await FlutterBluetoothPrinter.selectDevice(context);
    if (device != null) {
      // await _sharedPrefService.savePrinterAddress(device.address);
      await _sharedPrefService.savePrinter(device.name ?? "", device.address);

      setState(() {
        _savedPrinter = device.name ?? device.address;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Printer set to ${device.name ?? device.address}")),
      );
    }
  }

  Future<void> _clearPrinter() async {
    // await _sharedPrefService.savePrinterAddress(""); // clear it
    await _sharedPrefService.clearPrinter();

    setState(() {
      _savedPrinter = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🖨️ Printer cleared")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Settings',
        onBackTap: () {
          Navigator.pop(context);
        },
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text("Printer"),
            subtitle: Text(_savedPrinter ?? "No printer selected"),
            onTap: _pickPrinter, // open printer selection on tap
            trailing: _savedPrinter != null
                ? IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: _clearPrinter, // clear printer when cross is pressed
            )
                : null,
          ),
          SwitchListTile(
            title: const Text("Auto Submit Pick List"),
            subtitle: const Text("If ON: Pick List will be submitted automatically"),
            value: _autoSubmitPickList,
            onChanged: (value) async {
              await _updateSubmitToggle(value);
            },
          ),

        ],
      ),
    );
  }

}