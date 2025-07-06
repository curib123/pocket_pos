import 'package:flutter/cupertino.dart';
import 'package:paninda/View_Model/AuthPaymentProvider.dart';
import 'package:paninda/View_Model/TabProvider.dart';
import 'package:provider/provider.dart';

Future<void> checkIfTrialExpired(BuildContext context) async {
  try {
    final authPaymentProvider = Provider.of<AuthPaymentProvider>(context, listen: false);
    final tabProvider = Provider.of<TabProvider>(context, listen: false);

    // Fetch latest trial info from server or local source
    await authPaymentProvider.fetchTrialInfo();
    final trialInfo = await authPaymentProvider.getTrialInfoOffline();

    if (trialInfo.isNotEmpty && trialInfo['isTrial'] == true) {
      print("✅ Trial Active: ${trialInfo['remainingDays']} day(s) left.");
      tabProvider.setFirstTimeFlag(false);
    } else {
      // Check active status and trial status via methods
      final isActive = await authPaymentProvider.checkActiveStatus();
      final isTrial = await authPaymentProvider.checkTrialStatus();

      if (!isActive && !isTrial) {
        print("⚠️ Trial expired or not available.");
        tabProvider.setFirstTimeFlag(true);
      } else if (isTrial) {
        print("ℹ️ Trial still active via checkTrialStatus().");
        tabProvider.setFirstTimeFlag(false);
      }
    }
  } catch (e) {
    print("❌ Error checking trial status: $e");
  }
}
