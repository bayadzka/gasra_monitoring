// lib/features/inspection/chassis/pages/form_chassis_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/dialog_helper.dart';
// [FIX] Import provider base
import 'package:gasra_monitoring/features/inspection/providers/base_inspection_provider.dart';
import 'package:gasra_monitoring/features/inspection/shared/steps/step_generic_page.dart';
import 'package:gasra_monitoring/features/inspection/shared/steps/step_review_page.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:provider/provider.dart';

class FormChassisPage extends StatefulWidget {
  final String chassisType;
  final String chassisCode;
  final String chassisId;
  const FormChassisPage(
      {super.key,
      required this.chassisType,
      required this.chassisCode,
      required this.chassisId});

  @override
  State<FormChassisPage> createState() => _FormChassisPageState();
}

class _FormChassisPageState extends State<FormChassisPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;
  bool _isProviderInitialized = false;

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

  Future<void> _submit() async {
    // [FIX] Baca dari provider base
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
    // [FIX] Gunakan Consumer dari provider base
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
                    widget.chassisCode, widget.chassisId);
                provider.fetchInspectionItems(subtype: widget.chassisType);
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

            if (provider.errorMessage != null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(child: Text(provider.errorMessage!)),
              );
            }

            final desiredPageOrder = [
              'Kondisi Ban',
              'Lampu',
              'Landingan',
              'Sistem Pengereman',
              'Per Chasis',
              'U Bolt+Tusukan Per',
              'Karet Chamber',
              'Baut Roda',
              'Mur Roda',
              'Dop Roda',
              'Per Luar Chamber',
            ];

            final relevantCategories = desiredPageOrder
                .where((cat) =>
                    // [FIX] Gunakan getter dari kontrak
                    provider.groupedItems.containsKey(cat) &&
                    provider.groupedItems[cat]!.isNotEmpty)
                .toList();

            final pages = [
              ...relevantCategories
                  .map((category) => StepGenericPage(category: category)),
              const StepReviewPage(),
            ];

            final isLastPage = _currentPage == pages.length - 1;
            bool isNextButtonEnabled = true;

            if (!isLastPage && _currentPage < relevantCategories.length) {
              final currentCategory = relevantCategories[_currentPage];
              isNextButtonEnabled = provider.isStepValid(currentCategory);
            }

            return Scaffold(
              appBar: AppBar(
                title: Text('Inspeksi: ${widget.chassisCode}'),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(25.0),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      pages.length <= 1
                          ? "Ringkasan & Kirim"
                          : (isLastPage
                              ? "Ringkasan & Kirim"
                              : "Langkah ${_currentPage + 1} dari ${pages.length}"),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                ),
              ),
              body: pages.length <= 1
                  ? const StepReviewPage()
                  : PageView(
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
                            label: Text(isLastPage ? 'Kirim' : 'Lanjut'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              disabledBackgroundColor: Colors.grey.shade400,
                            ),
                            onPressed: isNextButtonEnabled
                                ? () {
                                    if (isLastPage) {
                                      _submit();
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
}
