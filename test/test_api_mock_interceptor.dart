import 'package:dio/dio.dart';
import 'package:ukk_bankmini/core/network/api_client.dart';

/// Test Mock Interceptor yang terisolasi HANYA pada lingkungan pengujian (unit testing)
/// Memastikan tes berjalan independen tanpa memanggil backend nyata atau membocorkan data mock ke runtime
class TestApiMockInterceptor extends Interceptor {
  static void install() {
    final dio = ApiClient.instance.dio;
    dio.interceptors.removeWhere((i) => i is TestApiMockInterceptor);
    dio.interceptors.insert(0, TestApiMockInterceptor());
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    final method = options.method.toUpperCase();
    final data = options.data is Map ? options.data as Map : {};

    // 1. PIN VERIFICATION
    if (path.contains('/verify-pin')) {
      if (data['pin'] == '240808') {
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'PIN valid dan terotentikasi',
              'data': {'valid': true},
            },
          ),
        );
      } else {
        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {
                'success': false,
                'message': 'PIN otorisasi nasabah salah',
              },
            ),
          ),
        );
      }
    }

    // 2. SETOR TUNAI
    if (path.contains('/transaksi/setor')) {
      final nominal = (data['nominal'] as num?)?.toDouble() ?? 50000.0;
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Setoran tunai berhasil diproses',
            'data': {
              'kode_sandi': '101',
              'nominal': nominal,
              'no_rekening': data['no_rekening'] ?? '202601001',
              'nama_siswa': 'Handa',
              'saldo_akhir': 100000.0,
            },
          },
        ),
      );
    }

    // 3. TARIK TUNAI
    if (path.contains('/transaksi/tarik')) {
      if (data['pin'] != '240808') {
        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {
                'success': false,
                'message': 'PIN otorisasi nasabah tidak sesuai',
              },
            ),
          ),
        );
      }
      final nominal = (data['nominal'] as num?)?.toDouble() ?? 20000.0;
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Penarikan tunai berhasil diproses',
            'data': {
              'kode_sandi': '201',
              'nominal': nominal,
              'no_rekening': data['no_rekening'] ?? '202601001',
              'nama_siswa': 'Handa',
              'saldo_akhir': 30000.0,
            },
          },
        ),
      );
    }

    // 4. NASABAH SEARCH & DETAIL
    if (path.contains('/petugas/nasabah') && !path.contains('/transaksi')) {
      if (path.contains('/202601001') || (path.split('/').length > 3 && !path.endsWith('/nasabah'))) {
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Detail nasabah berhasil dimuat',
              'data': {
                'id': '1',
                'id_nasabah': 1,
                'nama_siswa': 'Dewi Handayani Nur Halimah (Handa)',
                'nama': 'Dewi Handayani Nur Halimah',
                'no_rekening': '202601001',
                'nis': '17763',
                'kelas': 'XII AKL 1',
                'jurusan': 'Akuntansi',
                'saldo': 50000.0,
                'saldo_mengendap_min': 10000.0,
                'saldo_dapat_ditarik': 40000.0,
                'status': 'aktif',
                'riwayat_transaksi': [],
              },
            },
          ),
        );
      }

      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Data nasabah berhasil dimuat',
            'data': [
              {
                'id': '1',
                'id_nasabah': 1,
                'nama_siswa': 'Dewi Handayani Nur Halimah (Handa)',
                'nama': 'Dewi Handayani Nur Halimah',
                'no_rekening': '202601001',
                'nis': '17763',
                'kelas': 'XII AKL 1',
                'jurusan': 'Akuntansi',
                'saldo': 50000,
                'status': 'aktif',
              }
            ],
          },
        ),
      );
    }

    // 5. PENGAJUAN KAS (SUPERVISOR & TELLER)
    if (path.contains('/pengajuan-kas')) {
      if (path.contains('/setujui')) {
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Tiket permohonan kas loket berhasil disetujui',
              'data': {
                'id': 1,
                'status': 'disetujui',
                'nomor_pengajuan': 'PK-2026-001',
              },
            },
          ),
        );
      }

      if (path.contains('/tolak')) {
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Tiket permohonan kas loket ditolak',
              'data': {
                'id': 1,
                'status': 'ditolak',
                'nomor_pengajuan': 'PK-2026-001',
              },
            },
          ),
        );
      }

      if (method == 'POST') {
        final nominal = (data['nominal'] as num?)?.toDouble() ?? 1000000.0;
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Pengajuan modal kas berhasil dikirim',
              'data': {
                'id': 1,
                'nomor_pengajuan': 'PK-2026-001',
                'nominal': nominal,
                'status': 'pending',
                'alasan': data['alasan'] ?? 'Kebutuhan kas',
              },
            },
          ),
        );
      }

      // GET
      final statusFilter = options.queryParameters['status'];
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Daftar pengajuan kas berhasil dimuat',
            'data': [
              {
                'id': 1,
                'nomor_pengajuan': 'PK-2026-001',
                'nominal': 1000000.0,
                'status': statusFilter ?? 'pending',
                'alasan': 'Antrean penarikan siswa tinggi di loket 1',
                'nama_teller': 'Siti Rahmawati',
                'created_at': '2026-10-31 08:30:00',
              }
            ],
          },
        ),
      );
    }

    // 6. STATUS KAS LOKET
    if (path.contains('/kas') && !path.contains('pengajuan')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Status kas loket berhasil dimuat',
            'data': {
              'saldo_awal': 1000000.0,
              'kas_tersedia': 2250000.0,
              'kas_fisik_laci': 2250000.0,
              'total_setor': 1500000.0,
              'total_tarik': 250000.0,
            },
          },
        ),
      );
    }

    // 7. DAILY REPORT (SUPERVISOR & TELLER)
    if (path.contains('/daily-report')) {
      if (path.contains('/status')) {
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Status closing harian kasir berhasil diperbarui',
              'data': {
                'id': 1,
                'status': data['status'] ?? 'approved',
              },
            },
          ),
        );
      }

      if (method == 'POST') {
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Daily report kas harian berhasil disubmit',
              'data': {
                'id': 1,
                'physical_balance':
                    (data['saldo_akhir'] as num?)?.toDouble() ?? 2250000.0,
                'difference': 0.0,
                'status': 'submitted',
              },
            },
          ),
        );
      }

      // GET
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Daftar closing harian kasir berhasil dimuat',
            'data': [
              {
                'id': 1,
                'nama_teller': 'Siti Rahmawati',
                'shift': 'Shift Pagi',
                'system_balance': 2250000.0,
                'physical_balance': 2250000.0,
                'difference': 0.0,
                'status': 'submitted',
              }
            ],
          },
        ),
      );
    }

    // 8. RINGKASAN HARIAN
    if (path.contains('/ringkasan-harian')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Ringkasan harian operasional',
            'data': {
              'nasabah': {
                'total_nasabah_aktif': 120,
                'total_dana_tabungan': 15000000.0,
              },
              'kas_operasional': {
                'kas_fisik_tersedia': 2250000.0,
              },
              'transaksi_hari_ini': {
                'frekuensi_transaksi': 45,
                'total_nominal': 5000000.0,
              },
            },
          },
        ),
      );
    }

    // 9. MUTASI JURNAL
    if (path.contains('/mutasi-jurnal')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Laporan mutasi jurnal akuntansi',
            'data': {
              'summary': {
                'total_debit': 50000.0,
                'total_kredit': 50000.0,
              },
              'data': [
                {
                  'id': 1,
                  'kode_jurnal': 'JU-001',
                  'debet': 50000.0,
                  'kredit': 50000.0,
                  'keterangan': 'Setoran tabungan nasabah',
                }
              ],
            },
          },
        ),
      );
    }

    // 10. SALDO PER KELAS
    if (path.contains('/saldo-per-kelas')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Laporan saldo per kelas',
            'data': [
              {
                'kelas': 'XII AKL 1',
                'total_saldo': 5000000.0,
                'total_siswa': 36,
              }
            ],
          },
        ),
      );
    }

    // 11. HEALTH CHECK & AVALIS ABSENSI
    if (path.contains('/health')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Server Bank Mini Sehat & Aktif',
            'data': {'status': 'healthy'},
          },
        ),
      );
    }

    if (path.contains('/avalis/absensi')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Presensi petugas avalis berhasil dimuat',
            'data': {
              'summary': {
                'tanggal': '2026-10-31',
                'total_petugas': 1,
                'hadir': 1,
                'izin': 0,
                'tidak_masuk': 0,
              },
              'items': [
                {
                  'nama': 'Siti Rahmawati (Teller 1)',
                  'shift_jaga': 'Shift Pagi',
                  'status': 'Hadir',
                  'jam_masuk': '07.25 WIB',
                }
              ],
            },
          },
        ),
      );
    }

    // Default handler passes to next
    return handler.next(options);
  }
}
