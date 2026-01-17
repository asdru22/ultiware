import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../data/clothing_item.dart';
import '../data/clothing_repository.dart';

enum ExportFilter { allItems, tradable, favorites, exceptFavorites }

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  ExportFilter _selectedFilter = ExportFilter.allItems;
  bool _isGenerating = false;

  List<ClothingItem> _getFilteredItems(List<ClothingItem> allItems) {
    // Filter out traded items first
    final availableItems = allItems.where((item) => !item.isTraded).toList();

    switch (_selectedFilter) {
      case ExportFilter.allItems:
        return availableItems;
      case ExportFilter.tradable:
        return availableItems.where((item) => item.isTradeable).toList();
      case ExportFilter.favorites:
        return availableItems.where((item) => item.isFavorite).toList();
      case ExportFilter.exceptFavorites:
        return availableItems.where((item) => !item.isFavorite).toList();
    }
  }

  Future<void> _generateAndExportPdf(
    BuildContext context,
    List<ClothingItem> items,
  ) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final doc = pw.Document();
      final font = await PdfGoogleFonts.nunitoExtraLight();

      // Load images logic
      final List<_PdfItemData> pdfItems = [];

      for (final item in items) {
        Uint8List? imageBytes;
        if (item.frontImage.isNotEmpty) {
          final file = File(item.frontImage);
          if (await file.exists()) {
            imageBytes = await file.readAsBytes();
          }
        }
        Uint8List? backImageBytes;
        if (item.backImage != null && item.backImage!.isNotEmpty) {
          final file = File(item.backImage!);
          if (await file.exists()) {
            backImageBytes = await file.readAsBytes();
          }
        }
        pdfItems.add(_PdfItemData(item, imageBytes, backImageBytes));
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  "Ultiware Export",
                  style: pw.TextStyle(font: font, fontSize: 24),
                ),
              ),
              ...pdfItems.map((pdfItem) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (pdfItem.imageBytes != null)
                        pw.Container(
                          width: 100,
                          height: 100,
                          child: pw.Image(
                            pw.MemoryImage(pdfItem.imageBytes!),
                            fit: pw.BoxFit.contain,
                          ),
                        )
                      else
                        pw.Container(
                          width: 100,
                          height: 100,
                          color: PdfColors.grey300,
                          alignment: pw.Alignment.center,
                          child: pw.Text("No Image"),
                        ),
                      if (pdfItem.backImageBytes != null) ...[
                        pw.SizedBox(width: 10),
                        pw.Container(
                          width: 100,
                          height: 100,
                          child: pw.Image(
                            pw.MemoryImage(pdfItem.backImageBytes!),
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                      ],
                      pw.SizedBox(width: 20),
                      // Details
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (pdfItem.item.name != null &&
                                pdfItem.item.name!.isNotEmpty)
                              pw.Text(
                                "Name: ${pdfItem.item.name}",
                                style: pw.TextStyle(font: font),
                              ),
                            if (pdfItem.item.brand != null)
                              pw.Text(
                                "Brand: ${pdfItem.item.brand!.displayName}",
                                style: pw.TextStyle(font: font),
                              ),
                            if (pdfItem.item.type != null)
                              pw.Text(
                                "Type: ${pdfItem.item.type!.displayName}",
                                style: pw.TextStyle(font: font),
                              ),
                            if (pdfItem.item.size != null)
                              pw.Text(
                                "Size: ${pdfItem.item.size!.name.toUpperCase()}",
                                style: pw.TextStyle(font: font),
                              ),
                            if (pdfItem.item.countryOfOrigin != null &&
                                pdfItem.item.countryOfOrigin!.isNotEmpty)
                              pw.Text(
                                "Country: ${pdfItem.item.countryOfOrigin}",
                                style: pw.TextStyle(font: font),
                              ),
                            if (pdfItem.item.productionYear != null)
                              pw.Text(
                                "Year: ${pdfItem.item.productionYear}",
                                style: pw.TextStyle(font: font),
                              ),
                            if (pdfItem.item.source != null)
                              pw.Text(
                                "Source: ${pdfItem.item.source!.displayName}",
                                style: pw.TextStyle(font: font),
                              ),
                            if (pdfItem.item.condition != null)
                              pw.Text(
                                "Condition: ${pdfItem.item.condition!.displayName}",
                                style: pw.TextStyle(font: font),
                              ),
                            if (pdfItem.item.isTradeable)
                              pw.Text(
                                "Tradeable: Yes",
                                style: pw.TextStyle(font: font),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ];
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'ultiware_export.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<ClothingRepository>(context);
    final allItems = repo.items;

    return Scaffold(
      appBar: AppBar(title: const Text("Export Data")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Select what to export:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioGroup<ExportFilter>(
              groupValue: _selectedFilter,
              onChanged: (value) => setState(() => _selectedFilter = value!),
              child: Column(
                children: [
                  RadioListTile<ExportFilter>(
                    title: const Text("All items"),
                    value: ExportFilter.allItems,
                  ),
                  RadioListTile<ExportFilter>(
                    title: const Text("All tradable items"),
                    value: ExportFilter.tradable,
                  ),
                  RadioListTile<ExportFilter>(
                    title: const Text("All favourites"),
                    value: ExportFilter.favorites,
                  ),
                  RadioListTile<ExportFilter>(
                    title: const Text("All except favourites"),
                    value: ExportFilter.exceptFavorites,
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isGenerating
                  ? null
                  : () {
                      final itemsToExport = _getFilteredItems(allItems);
                      if (itemsToExport.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "No items match the selected filter.",
                            ),
                          ),
                        );
                        return;
                      }
                      _generateAndExportPdf(context, itemsToExport);
                    },
              icon: _isGenerating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isGenerating ? "Generating..." : "Export to PDF"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfItemData {
  final ClothingItem item;
  final Uint8List? imageBytes;
  final Uint8List? backImageBytes;

  _PdfItemData(this.item, this.imageBytes, this.backImageBytes);
}
