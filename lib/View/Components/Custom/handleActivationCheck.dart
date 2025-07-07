import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Components/Custom/activation_subtitle_widget.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/CheckTrialExpired.dart';
import 'package:paninda/View/Components/HelperClass/LinkOpener.dart';
import 'package:paninda/View/Screens/Navigation/payment_form_screen.dart';
import 'package:paninda/View/Screens/Navigation/verification_screen.dart';
import 'package:paninda/View_Model/AuthPaymentProvider.dart';
import 'package:paninda/View_Model/TabProvider.dart';
import 'package:provider/provider.dart';

Future<dynamic> handleActivationCheck(BuildContext context, {bool isReturn = false}) async {
  final authPaymentProvider = Provider.of<AuthPaymentProvider>(context, listen: false);
  final tabProvider = Provider.of<TabProvider>(context, listen: false);

  final isActivated = await authPaymentProvider.checkActivationStatus();

  Widget verificationCard;

  if (isActivated) {
    final isTrial = await authPaymentProvider.checkTrialStatus();
    final isActive = await authPaymentProvider.checkActiveStatus();

    verificationCard = VerificationStatusCard(
      isSuccess: true,
      title: isTrial
          ? 'Free Trial Activated'
          : (isActive ? 'Lifetime Access Activated' : 'Account Status Unknown'),
      subtitleWidget: Text(
        isTrial
            ? 'Welcome aboard! You’re now on a Free Trial.\nEnjoy exploring all features during your trial period.'
            : (isActive
            ? 'Thank you for unlocking lifetime access!\nYour account is now fully activated and ready to use forever.'
            : 'We couldn’t verify your account status.\nPlease contact support.'),
        textAlign: TextAlign.center,
      ),
      statusIcon: LucideIcons.checkCircle,
      buttonIcon: LucideIcons.arrowRight,
      buttonText: 'Get Started',
      mainColor: const Color(0xFF4CAF50),
      onPressed: () async {
        await authPaymentProvider.setTrialStatus(false);
        checkIfTrialExpired(context);
        await tabProvider.setFirstTimeFlag(false);
        if (!tabProvider.isFirstTime) {
          Phoenix.rebirth(context);
        }
      },
    );
  } else {
    verificationCard = VerificationStatusCard(
      isSuccess: false,
      title: 'Activation Incomplete',
      subtitleWidget: ActivationSubtitleWidget(),
      statusIcon: LucideIcons.xCircle,
      showPrimaryButton: true,
      showSecondButton: true,
      showThirdButton: true,

      // 🔸 Primary Button: Unlock Lifetime Use
      thirdButtonIcon: LucideIcons.creditCard,
      thirdButtonText: 'Unlock Lifetime Use Now',
      thirdButtonColor: Colors.green,
      thirdButtonOnPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentFormScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment action here.")),
        );
      },

// 🔸 Secondary Button: Free Trial
      secondButtonIcon: LucideIcons.gift,
      secondButtonText: 'Start Free Trial',
      secondButtonColor: Colors.blueGrey,
      secondButtonOnPressed: () async {
        await authPaymentProvider.setTrialStatus(true);
        await authPaymentProvider.fetchTrialInfo();
        await tabProvider.setFirstTimeFlag(false);
        if (!tabProvider.isFirstTime) Phoenix.rebirth(context);
      },

// 🔸 Tertiary Button: Facebook Support
      buttonIcon: LucideIcons.messageCircle,
      buttonText: 'Message Us on Facebook',
      mainColor: AppColor.errorText,
      onPressed: () {
        LinkOpener.openLink(
          context,
          "https://www.facebook.com/profile.php?id=61577201312987",
        );
      },

    );
  }

  if (isReturn) {
    return verificationCard;
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.grey.shade100,
          body: Center(child: verificationCard),
        ),
      ),
    );
  }
}
