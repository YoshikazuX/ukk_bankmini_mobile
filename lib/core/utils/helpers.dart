import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Format angka ke format Rupiah
String formatRupiah(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

/// Format tanggal ke bahasa Indonesia
String formatTanggal(DateTime date) {
  return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
}

String formatTanggalSingkat(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatTanggalLengkap(DateTime date) {
  return DateFormat('EEEE, dd MMMM yyyy - HH:mm', 'id_ID').format(date);
}

String formatWaktuRelatif(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inMinutes < 1) {
    return 'Baru saja';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} menit lalu';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} jam lalu';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} hari lalu';
  } else {
    return DateFormat('dd MMM yyyy').format(date);
  }
}

/// Nama bulan Indonesia
String namaBulan(int month) {
  const bulan = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  return bulan[month];
}

String namaBulanLengkap(int month) {
  const bulan = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  return bulan[month];
}

/// Show custom snackbar
void showAppSnackbar(BuildContext context, String message,
    {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF2DD4A8),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Buka link WhatsApp resmi Administrator Bank Mini Sekolah secara langsung
Future<void> openWhatsAppAdmin({
  BuildContext? context,
  String? message,
  String phoneNumber = '6281234567890',
}) async {
  final defaultMsg = message ??
      'Halo Admin LKM Mitra Siswa Abadi, saya nasabah Bank Mini Sekolah ingin meminta bantuan terkait akun saya.';
  final encodedText = Uri.encodeComponent(defaultMsg);
  final url = Uri.parse('https://wa.me/$phoneNumber?text=$encodedText');

  try {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(url);
    }
  } catch (e) {
    if (context != null && context.mounted) {
      showAppSnackbar(
        context,
        'Membuka WhatsApp Admin ($phoneNumber)...',
      );
    }
  }
}

