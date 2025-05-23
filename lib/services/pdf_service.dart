import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/variable_model.dart';
import '../models/formula_model.dart';
import '../models/input_field_model.dart';

class PdfService {
  Future<Uint8List> generatePdf({
    required String title,
    required Map<String, dynamic> inputValues,
    required Map<String, dynamic> results,
    required List<Variable> variables,
    required List<Formula> formulas,
    required List<InputField> inputFields,
  }) async {
    final pdf = pw.Document();
    
    // Load font
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              title,
              style: pw.TextStyle(font: fontBold, fontSize: 24),
            ),
          );
        },
        build: (pw.Context context) => [
          // Input values section
          pw.Header(level: 1, text: 'Données saisies', textStyle: pw.TextStyle(font: fontBold)),
          pw.SizedBox(height: 10),
          _buildInputValuesTable(inputValues, variables, font, fontBold, inputFields: inputFields),
          pw.SizedBox(height: 20),
          
          // Results section
          pw.Header(level: 1, text: 'Résultats du calcul', textStyle: pw.TextStyle(font: fontBold)),
          pw.SizedBox(height: 10),
          _buildResultsTable(results, formulas, font, fontBold),
        ],
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Page ${context.pageNumber} sur ${context.pagesCount}',
              style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey),
            ),
          );
        },
      ),
    );
    
    return pdf.save();
  }
  
  pw.Widget _buildInputValuesTable(
    Map<String, dynamic> inputValues,
    List<Variable> variables,
    pw.Font font,
    pw.Font fontBold,
    {List<InputField>? inputFields,
  }) {
    final rows = <pw.TableRow>[];
    
    // Add header row
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey200,
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Nom',
              style: pw.TextStyle(font: fontBold),
              textAlign: pw.TextAlign.left,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Valeur',
              style: pw.TextStyle(font: fontBold),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
    
    // Use a Set to track variables that have been processed via input fields
    final processedVariableIds = <String>{};
    
    // First add input fields with their labels
    if (inputFields != null) {
      for (var field in inputFields.where((f) => f.variableId != null)) {
        final variableId = field.variableId;
        if (variableId != null) {
          final variable = variables.firstWhere(
            (v) => v.id == variableId,
            orElse: () => Variable(id: '', name: '', type: VariableType.text, initialValue: ''),
          );
          
          if (variable.id.isEmpty) continue; // Skip if variable not found
          
          processedVariableIds.add(variableId);
          final value = inputValues[variableId] ?? variable.initialValue;
          
          // Format the value based on type
          String displayValue;
          if (variable.type == VariableType.boolean) {
            displayValue = (value == true || value == 'true') ? 'Oui' : 'Non';
          } else {
            displayValue = value?.toString() ?? '';
          }
          
          rows.add(
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    field.label,
                    style: pw.TextStyle(font: font),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    displayValue,
                    style: pw.TextStyle(font: font),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }
      }
    }
    
    // Then add all remaining variables that weren't processed as input fields
    for (var variable in variables) {
      if (processedVariableIds.contains(variable.id)) continue;
      
      final value = inputValues[variable.id] ?? variable.initialValue;
      
      // Format the value based on type
      String displayValue;
      if (variable.type == VariableType.boolean) {
        displayValue = (value == true || value == 'true') ? 'Oui' : 'Non';
      } else {
        displayValue = value?.toString() ?? '';
      }
      
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                variable.name,
                style: pw.TextStyle(font: font),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                displayValue,
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }
    
    if (rows.length <= 1) {
      // If only the header row, add a message
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Aucune donnée',
                style: pw.TextStyle(font: font, color: PdfColors.grey700),
              ),
            ),
            pw.Container(),
          ],
        ),
      );
    }
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }
  
  pw.Widget _buildResultsTable(
    Map<String, dynamic> results,
    List<Formula> formulas,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final rows = <pw.TableRow>[];
    
    // Add header row
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey200,
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Formule',
              style: pw.TextStyle(font: fontBold),
              textAlign: pw.TextAlign.left,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Résultat',
              style: pw.TextStyle(font: fontBold),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
    
    // Add result rows
    for (var formula in formulas) {
      final result = results[formula.name];
      
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                formula.name,
                style: pw.TextStyle(font: font),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                result != null ? result.toString() : 'Non calculé',
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }
    
    if (rows.length <= 1) {
      // If only the header row, add a message
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Aucun résultat',
                style: pw.TextStyle(font: font, color: PdfColors.grey700),
              ),
            ),
            pw.Container(),
          ],
        ),
      );
    }
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }
  
  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Voici votre rapport de décompte final');
    } catch (e) {
      print('Error sharing PDF: $e');
    }
  }
  
  Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }
}
