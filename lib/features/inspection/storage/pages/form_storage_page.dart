// lib/features/inspection/storage/pages/form_storage_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/dialog_helper.dart';
import 'package:gasra_monitoring/features/inspection/providers/base_inspection_provider.dart';
import 'package:gasra_monitoring/features/inspection/shared/steps/step_review_page.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/inspection/storage/pages/storage_form_content.dart';
import 'package:provider/provider.dart';

class FormStoragePage extends StatefulWidget {
  final String storageCode;
  final String storageId;
  const FormStoragePage(
      {super.key, required this.storageCode, required this.storageId});

  @override
  State<FormStoragePage> createState() => _FormStoragePageState();
}

class _FormStoragePageState extends State<FormStoragePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isProviderInitialized = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  // Di dalam class _FormStoragePageState

  Future<void> _submit() async {
    final provider = context.read<BaseInspectionProvider>();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Pengiriman"),
        content:
            const Text("Apakah Anda yakin ingin mengirim data inspeksi ini?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Batal")),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Ya, Kirim")),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSubmitting = true);
      try {
        await provider.submitInspection();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Data berhasil dikirim!"),
                backgroundColor: Colors.green),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Error: ${e.toString()}"),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          showExitConfirmationDialog(context);
        },
        child: Consumer<BaseInspectionProvider>(
          builder: (context, provider, child) {
            if (!_isProviderInitialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.clearAllData();
                provider.updateVehicleSelection(
                    widget.storageCode, widget.storageId);
                provider.fetchInspectionItems(subtype: 'Umum');
                setState(() {
                  _isProviderInitialized = true;
                });
              });
            }

            if (provider.isLoading && !_isProviderInitialized) {
              return Scaffold(
                appBar: AppBar(title: const Text('Memuat Checklist...')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final bool isFormValid = provider.isStepValid('Umum');

            final pages = [
              _buildFormPage(provider),
              // [FIX] Kirim fungsi untuk mengontrol PageController
              const StepReviewPage(),
            ];

            final isLastPage = _currentPage == pages.length - 1;

            return Scaffold(
              appBar: AppBar(
                title: Text('Inspeksi: ${widget.storageCode}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: AppTheme.background,
                foregroundColor: AppTheme.textPrimary,
                elevation: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(25.0),
                  child: Column(
                    children: [
                      Text(
                        isLastPage
                            ? "Ringkasan & Kirim"
                            : "Langkah 1 dari 2", // Disederhanakan
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 16),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(
                          value: (pages.isEmpty)
                              ? 0
                              : (_currentPage + 1) / pages.length,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primary),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              body: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: pages,
              ),
              bottomNavigationBar: BottomAppBar(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentPage > 0)
                            TextButton.icon(
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Kembali'),
                              onPressed: () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut),
                            ),
                          if (_currentPage == 0) const Spacer(),
                          ElevatedButton.icon(
                            icon: Icon(
                                isLastPage ? Icons.send : Icons.arrow_forward),
                            label:
                                Text(isLastPage ? 'Kirim' : 'Lanjut ke Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              disabledBackgroundColor: Colors.grey.shade400,
                            ),
                            onPressed: isFormValid
                                ? () {
                                    if (isLastPage) {
                                      _submit(); // Panggil fungsi submit
                                    } else {
                                      _pageController.nextPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeIn);
                                    }
                                  }
                                : null,
                          )
                        ],
                      ),
              ),
            );
          },
        ));
  }

  // Halaman Form Checklist
  Widget _buildFormPage(BaseInspectionProvider provider) {
    return const StorageFormContent();
  }
}
