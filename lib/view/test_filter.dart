import 'package:flutter/material.dart';

class ListFilter extends StatefulWidget { 
@override 
_ListFilterState createState() => _ListFilterState(); 
} 

class _ListFilterState extends State<ListFilter> { 
final List<Product> products = [ 
	Product(name: 'Product 1', price: 10.0, category: 'Category A'), 
	Product(name: 'Product 2', price: 25.0, category: 'Category B'), 
	Product(name: 'Product 3', price: 15.0, category: 'Category A'), 
	Product(name: 'Product 4', price: 30.0, category: 'Category C'), 
	Product(name: 'Product 5', price: 20.0, category: 'Category A'), 
]; 

String filterPrice = ''; 
List<Product> filteredProducts = []; 

@override 
void initState() { 
	// Initialize the filtered 
	// list with all products 
	filteredProducts = products; 
	super.initState(); 
} 

// Function to filter products by price 
void filterProductsByPrice(String price) { 
	setState(() { 
	filterPrice = price; 
	// Use the 'where' method to 
	// filter products by price 
	filteredProducts = products 
		.where((product) => 
			product.price.toStringAsFixed(2).contains(filterPrice)) 
		.toList(); 
	}); 
} 

@override 
Widget build(BuildContext context) { 
	return Scaffold( 
	appBar: AppBar( 
		title: Text('Product Filter App'), 
	), 
	body: SingleChildScrollView( 
		child: Center( 
		child: Column( 
			mainAxisAlignment: MainAxisAlignment.center, 
			children: <Widget>[ 
			// Text input field for price filtering 
			Padding( 
				padding: const EdgeInsets.all(16.0), 
				child: TextField( 
				decoration: InputDecoration(labelText: 'Filter by Price'), 
				// Call the filtering 
				// function on text change 
				onChanged: filterProductsByPrice, 
				), 
			), 
			Text( 
				'Filtered Products', 
				style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), 
			), 
			SizedBox(height: 10), 
			for (var product in filteredProducts) 
				_buildProductCard(product, context), 
			], 
		), 
		), 
	), 
	); 
} 

// Function to build a product card 
Widget _buildProductCard(Product product, BuildContext context) { 
	return Card( 
	elevation: 5, 
	margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20), 
	child: Padding( 
		padding: EdgeInsets.all(20), 
		child: Column( 
		crossAxisAlignment: CrossAxisAlignment.start, 
		children: <Widget>[ 
			Text( 
			product.name, 
			style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), 
			), 
			SizedBox(height: 5), 
			Text( 
			'Price: Rs.${product.price.toStringAsFixed(2)}', 
			style: TextStyle(fontSize: 16, color: Colors.green), 
			), 
			SizedBox(height: 5), 
			Text( 
			'Category: ${product.category}', 
			style: TextStyle(fontSize: 16, color: Colors.blue), 
			), 
		], 
		), 
	), 
	); 
} 
}

class Product { 
	
final String name; 
final double price; 
final String category; 

Product({required this.name, required this.price, required this.category}); 
} 
