import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/bootstrap/app_bootstrap.dart';
import 'app/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('id_ID', null);
  runApp(const _BootstrapGate());
}

class _BootstrapGate extends StatefulWidget {
  const _BootstrapGate();

  @override
  State<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<_BootstrapGate> {
  late Future<AppDependencies> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = AppBootstrap().initialize();
  }

  void _retry() {
    setState(() {
      _bootstrapFuture = AppBootstrap().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDependencies>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashScreen();
        }

        if (snapshot.hasError) {
          return _ErrorScreen(error: snapshot.error, onRetry: _retry);
        }

        final dependencies = snapshot.data!;
        return FoodNutritionsApp(
          historyRepository: dependencies.historyRepository,
          weeklyStatsRepository: dependencies.weeklyStatsRepository,
          dailyNutritionAnalyticsRepository:
              dependencies.dailyNutritionAnalyticsRepository,
          mealEntryRepository: dependencies.mealEntryRepository,
          productCacheRepository: dependencies.productCacheRepository,
          pantryRepository: dependencies.pantryRepository,
        );
      },
    );
  }
}

// [NEW] Loading screen saat bootstrap berjalan
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo / ikon app
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  size: 48,
                  color: AppColors.accentStrong,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'FoodNutritions',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Memuat data...',
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppColors.accentStrong,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// [NEW] Error screen yang visual dan informatif
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // Buat pesan error ramah pengguna berdasarkan jenis error
    final errorMsg = _friendlyMessage(error);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ikon error dengan container bulat berwarna
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEC),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFCDD2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    size: 52,
                    color: Color(0xFFE53935),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Gagal Memuat Aplikasi',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  errorMsg,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Detail teknis dalam container collapsible-style
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${error ?? 'Unknown error'}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'Coba Lagi',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentStrong,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _friendlyMessage(Object? error) {
    final msg = error?.toString().toLowerCase() ?? '';
    if (msg.contains('timeout')) {
      return 'Inisialisasi terlalu lama. Periksa ruang penyimpanan perangkat dan coba lagi.';
    }
    if (msg.contains('hive') || msg.contains('box')) {
      return 'Terjadi kesalahan pada database lokal. Coba restart aplikasi.';
    }
    return 'Terjadi kesalahan saat memuat data awal aplikasi.';
  }
}
