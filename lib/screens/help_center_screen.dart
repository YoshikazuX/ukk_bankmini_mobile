import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../widgets/common/app_buttons.dart';
import '../widgets/common/app_inputs.dart';

/// Halaman Pusat Bantuan & FAQ Literasi Keuangan (Production)
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<Map<String, dynamic>> _officialFaqList = [
    {
      'category': 'Transaksi di Loket Teller',
      'items': [
        {
          'question': 'Bagaimana cara melakukan setoran di loket?',
          'answer':
              'Datangi loket Bank Mini, serahkan uang fisik kepada Petugas Teller, lalu tunjukkan QR Code kartu digital rekening Anda dari aplikasi. Teller akan memindai QR Code dan memproses setoran secara langsung.',
        },
        {
          'question': 'Bagaimana cara melakukan penarikan di loket?',
          'answer':
              'Sampaikan nominal penarikan kepada Teller loket, tunjukkan QR Code rekening Anda, lalu masukkan 6-digit PIN keamanan Anda pada layar otorisasi sebagai persetujuan transaksi yang sah.',
        },
        {
          'question': 'Berapa saldo minimal yang harus mengendap?',
          'answer':
              'Saldo minimal mengendap adalah Rp 10.000. Saldo ini berfungsi sebagai jaminan pemeliharaan rekening aktif dan tidak dapat ditarik.',
        },
      ],
    },
    {
      'category': 'Keamanan Akun & PIN',
      'items': [
        {
          'question': 'Apa fungsi 6-digit PIN Keamanan?',
          'answer':
              'PIN 6-digit digunakan sebagai otorisasi resmi saat Anda melakukan penarikan tunai tabungan di loket teller.',
        },
        {
          'question': 'Bagaimana jika saya lupa kata sandi login?',
          'answer':
              'Gunakan fitur Lupa Password pada halaman login atau hubungi Administrator Bank Mini sekolah melalui hotline loket untuk verifikasi identitas dan reset kredensial.',
        },
        {
          'question': 'Apa yang harus dilakukan jika kartu pelajar/rekening hilang?',
          'answer':
              'Buka menu Pengaturan Profil di aplikasi dan pilih "Blokir Rekening Darurat" untuk membekukan rekening sementara agar tidak dapat ditarik oleh pihak lain.',
        },
      ],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faqList = _officialFaqList;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pusat Bantuan & FAQ',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Search Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondaryNavy),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pusat Panduan & Edukasi Siswa',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cari jawaban seputar transaksi, rekening, dan operasional Bank Mini.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SearchField(
                      controller: _searchController,
                      hint: 'Cari pertanyaan atau kata kunci...',
                      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                      onClear: () => setState(() => _searchQuery = ''),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // FAQ Categories
              ...faqList.map((category) {
                final items = (category['items'] as List)
                    .where((item) =>
                        _searchQuery.isEmpty ||
                        item['question']
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        item['answer']
                            .toLowerCase()
                            .contains(_searchQuery))
                    .toList();

                if (items.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (category['category'] as String).toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) => _faqItem(
                          item['question'] as String,
                          item['answer'] as String,
                        )),
                    const SizedBox(height: 14),
                  ],
                );
              }),

              // Contact Admin
              _buildContactAdmin(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: AppColors.primaryNavy,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(
            question,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                answer,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactAdmin() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.primaryNavy,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Butuh Bantuan Lebih Lanjut?',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Konsultasikan perihal rekening dan transaksi langsung dengan Admin Bank Mini Sekolah melalui WhatsApp.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            text: 'Hubungi WhatsApp Resmi Admin',
            icon: Icons.chat_rounded,
            backgroundColor: AppColors.success,
            textColor: Colors.white,
            onPressed: () {
              openWhatsAppAdmin(
                context: context,
                message:
                    'Halo Admin LKM Mitra Siswa Abadi, saya nasabah Bank Mini Sekolah ingin konsultasi perihal transaksi dan literasi tabungan.',
              );
            },
          ),
        ],
      ),
    );
  }
}
