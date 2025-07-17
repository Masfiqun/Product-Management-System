// import 'package:flutter/material.dart';
// import 'package:record/models/product.dart';
// import 'package:record/services/firestore_service.dart';

// class ProductCheckInScreen extends StatefulWidget {
//   final String? shipmentId;

//   const ProductCheckInScreen({super.key, this.shipmentId});

//   @override
//   State<ProductCheckInScreen> createState() => _ProductCheckInScreenState();
// }

// class _ProductCheckInScreenState extends State<ProductCheckInScreen> {
//   final _firestoreService = FirestoreService();
//   bool _isLoading = false;
//   List<Product> _checkedOutProducts = [];
//   String? _selectedProductId;

//   @override
//   void initState() {
//     super.initState();
//     _loadCheckedOutProducts();
//   }

//   Future<void> _loadCheckedOutProducts() async {
//     setState(() => _isLoading = true);
//     try {
//       List<Product> products;
//       if (widget.shipmentId != null) {
//         products = await _firestoreService.getProductsByShipment(widget.shipmentId!);
//         products = products.where((p) => p.checkedInAt == null).toList();
//       } else {
//         products = await _firestoreService.getCheckedOutProducts();
//       }
//       setState(() => _checkedOutProducts = products);
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading products: ${e.toString()}')),
//         );
//       }
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   Future<void> _checkInProduct() async {
//     if (_selectedProductId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a product to check in')),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);
//     try {
//       final selectedProduct = _checkedOutProducts.firstWhere(
//         (p) => p.id == _selectedProductId,
//       );

//       if (selectedProduct.shipmentId == null) {
//         throw Exception('Product is not associated with a shipment');
//       }

//       final checkedInProduct = Product(
//         id: '', // Firestore will generate this
//         name: selectedProduct.name,
//         description: selectedProduct.description,
//         quantity: selectedProduct.quantity,
//         checkedInAt: DateTime.now(),
//         shipmentId: selectedProduct.shipmentId,
//         originalProductId: selectedProduct.originalProductId,
//       );

//       await _firestoreService.checkInProduct(
//         checkedInProduct as String,
//         selectedProduct.shipmentId!,
//       );

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Product checked in successfully')),
//         );
//         setState(() {
//           _selectedProductId = null;
//           _checkedOutProducts.removeWhere((p) => p.id == selectedProduct.id);
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Product Check-In'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Text(
//                     'Select Product to Check In',
//                     style: Theme.of(context).textTheme.titleLarge,
//                   ),
//                   const SizedBox(height: 16),
//                   Expanded(
//                     child: _checkedOutProducts.isEmpty
//                         ? const Center(
//                             child: Text('No products available for check-in'),
//                           )
//                         : ListView.builder(
//                             itemCount: _checkedOutProducts.length,
//                             itemBuilder: (context, index) {
//                               final product = _checkedOutProducts[index];
//                               return RadioListTile<String>(
//                                 title: Text(product.name),
//                                 subtitle: Text(
//                                     '${product.description}\nQuantity: ${product.quantity}\nChecked Out: ${product.checkedOutAt?.toString() ?? 'N/A'}'),
//                                 value: product.id,
//                                 groupValue: _selectedProductId,
//                                 onChanged: (String? value) {
//                                   setState(() {
//                                     _selectedProductId = value;
//                                   });
//                                 },
//                               );
//                             },
//                           ),
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: _selectedProductId == null ? null : _checkInProduct,
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.all(16),
//                     ),
//                     child: const Text('Check In Selected Product'),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
//   }