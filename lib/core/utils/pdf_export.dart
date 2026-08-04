import 'dart:io';

import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:whats_order/features/orders/data/order_model.dart';

import 'package:pdf/pdf.dart';
// import 'package:open_filex/open_filex.dart';

class PdfExport {
  static Future<void> exportOrders(List<OrderModel> orders) async {
    final pdf = pw.Document();

    // تحميل الخط العربي
    final font = pw.Font.ttf(
      await rootBundle.load("assets/fonts/Cairo-Regular.ttf"),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (_) {
          return [
            pw.Text(
              "Orders Report",
              style: pw.TextStyle(
                font: font,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            ...orders.map(
              (order) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("رقم الطلب : ${order.id}"),
                      pw.Text("رقم الطلب : ${order.orderId}"),

                      pw.SizedBox(height: 5),
                      pw.Text("الهاتف : ${order.phone}"),
                      pw.Text("المكونات : ${order.components}"),
                      pw.Text("القسم : ${order.sector}"),
                      pw.Text("السعر : ${order.price}"),
                      pw.Text("التكلفة : ${order.cost}"),
                      pw.Text("Latitude : ${order.latitude}"),
                      pw.Text("Longitude : ${order.longitude}"),
                      pw.Text("التاريخ : ${order.createdDate}"),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
      ),
    );

    final dir = await getDownloadDirectory();

    final file = File(
      "${dir.path}/Orders_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );

    await file.writeAsBytes(await pdf.save());

    // await OpenFilex.open(file.path);
  }
}
