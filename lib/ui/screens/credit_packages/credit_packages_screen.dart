import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:nofak/data/model/subscription/subscription_package_model.dart';
import 'package:nofak/ui/screens/subscription/widget/planHelper.dart';
import 'package:nofak/utils/api.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/hive_utils.dart';
import 'package:nofak/utils/ui_utils.dart';

class CreditPackagesScreen extends StatefulWidget {
  const CreditPackagesScreen({super.key});

  @override
  State<CreditPackagesScreen> createState() => _CreditPackagesScreenState();
}

class _CreditPackagesScreenState extends State<CreditPackagesScreen> {
  List<dynamic> creditPackages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCreditPackages();
  }

  Future<void> fetchCreditPackages() async {
    try {
      final response = await Api.get(
        url: Api.creditPackages,
        useBaseUrl: true,
      );

      if (response['error'] == false && response['data'] != null) {
        setState(() {
          creditPackages = response['data'] as List;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e, st) {
      log('Error fetching credit packages: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> purchasePackage(Map package) async {
    if (!HiveUtils.isUserAuthenticated()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to purchase credits'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment coming soon. Price: ₹${package['price']}'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Packages'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : creditPackages.isEmpty
              ? const Center(
                  child: Text('No credit packages available'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: creditPackages.length,
                  itemBuilder: (context, index) {
                    final package = creditPackages[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    package['name'] ?? 'Credits',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '₹${package['price']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (package['bonus_credits'] > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+${package['bonus_credits']} Bonus Credits',
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: PlanHelper().purchaseButtonWidget(
                                context,
                                SubscriptionPackageModel.fromJson(
                                  Map<String, dynamic>.from(package),
                                ),
                                null,
                                btnTitle: "buyCredits".translate(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}