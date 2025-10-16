
// material_request.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/view/material_request/MaterialRequestScreen.dart';
import 'package:sales_ordering_app/view/material_request/material_request_status.dart';

class MaterialRequest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

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
            'Material Request',
            style: TextStyle(color: Colors.white),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Material Request Form'),
              Tab(text: 'Material Requests'),
            ],
          ),
        ),
        body: FutureBuilder(
          future: provider.fetchMaterialRequests(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            return TabBarView(
              children: [
                MaterialRequestScreen(), 
                // MaterialRequestFormScreen(),
                MaterialRequestStatusScreen(),
              ],
            );
          },
        ),
      ),
    );
  }
}


