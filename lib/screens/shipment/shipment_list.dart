import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:record/models/shipment.dart';
import 'package:record/screens/shipment/shipment_details.dart';
import 'package:record/services/firestore_service.dart';
import 'package:share_plus/share_plus.dart';

class ShipmentListScreen extends StatefulWidget {
  const ShipmentListScreen({super.key});

  @override
  State<ShipmentListScreen> createState() => _ShipmentListScreenState();
}

class _ShipmentListScreenState extends State<ShipmentListScreen> {
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

Future<void> _generateAndSharePDF(Shipment shipment) async {
  setState(() => _isLoading = true);
  try {
    final products = await _firestoreService.getProductsByShipment(shipment.id);
    final pdf = pw.Document();

    final pageTheme = await _myPageTheme(); // Custom theme

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) => pw.Text('Shipment Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        footer: (context) => pw.Text(
          'Generated on ${DateFormat('MMM dd, yyyy – hh:mm a').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
        build: (context) => [
          pw.SizedBox(height: 10),
          _buildSectionHeader('Shipment Details'),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
            },
            border: pw.TableBorder.all(color: PdfColors.grey),
            children: [
              _tableRow('Name', shipment.name),
              _tableRow('Created Date',
                  DateFormat('MMM dd, yyyy').format(shipment.createdAt)),
              _tableRow('Status',
                  shipment.isCompleted ? 'Completed' : 'Pending'),
              _tableRow('Total Products', products.length.toString()),
              _tableRow(
                'Checked In',
                '${shipment.checkedInProductIds.length} / ${shipment.productIds.length}',
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          _buildSectionHeader('Product List'),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ['Name', 'Description', 'Qty', 'Checked Out', 'Check-in Status'],
            cellAlignment: pw.Alignment.centerLeft,
            data: products.map((product) {
              final checkedIn = shipment.checkedInProductIds.contains(product.id);
              return [
                product.name,
                product.description,
                product.quantity.toString(),
                DateFormat('MMM dd, yyyy').format(product.checkedOutAt!),
                checkedIn ? 'Checked In' : 'Pending',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/shipment_${shipment.id}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Shipment Report - ${shipment.name}',
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: ${e.toString()}')),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

pw.Widget _buildSectionHeader(String title) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(
      title,
      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
    ),
  );
}

pw.TableRow _tableRow(String key, String value) {
  return pw.TableRow(children: [
    pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    ),
    pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(value),
    ),
  ]);
}

Future<pw.PageTheme> _myPageTheme() async {
  final fontData = await rootBundle.load('assets/fonts/times.ttf');
  final boldData = await rootBundle.load('assets/fonts/times.ttf');

  final ttf = pw.Font.ttf(fontData);
  final ttfBold = pw.Font.ttf(boldData);

  return pw.PageTheme(
    theme: pw.ThemeData.withFont(
      base: ttf,
      bold: ttfBold,
    ),
    margin: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 40),
  );
}




  Future<void> _completeShipment(Shipment shipment) async {
    try {
      final updatedShipment = shipment.copyWith(isCompleted: true);
      await _firestoreService.updateShipment(updatedShipment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shipment marked as completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating shipment: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(Shipment shipment) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Shipment?'),
          content: const Text('Are you sure you want to delete this shipment and all its products? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteShipment(shipment.id);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteShipment(String shipmentId) async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.deleteShipment(shipmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shipment deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting shipment: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _statusChip(bool isCompleted) {
    return Chip(
      label: Text(isCompleted ? 'Completed' : 'Pending'),
      backgroundColor: isCompleted ? Colors.green[100] : Colors.orange[100],
      labelStyle: TextStyle(
        color: isCompleted ? Colors.green[800] : Colors.orange[800],
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipments', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.white
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Shipment>>(
              stream: _firestoreService.streamShipments(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final shipments = snapshot.data!;

                if (shipments.isEmpty) {
                  return const Center(child: Text('No shipments found'));
                }

                return ListView.builder(
                  itemCount: shipments.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemBuilder: (context, index) {
                    final shipment = shipments[index];

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          shipment.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text('Created: ${DateFormat('MMM dd, yyyy').format(shipment.createdAt)}'),
                            Text('Products Checked In: ${shipment.checkedInProductIds.length}/${shipment.productIds.length}'),
                            const SizedBox(height: 6),
                            _statusChip(shipment.isCompleted),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShipmentDetailsScreen(shipment: shipment),
                            ),
                          );
                        },
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              tooltip: 'Export PDF',
                              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
                              onPressed: () => _generateAndSharePDF(shipment),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
                              onPressed: () => _showDeleteConfirmation(shipment),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
