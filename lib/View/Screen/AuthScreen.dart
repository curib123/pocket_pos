import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:retailpos/Provider/TabProvider.dart';
import 'package:retailpos/View/Components/Alert/CustomNotificationDialog.dart';
import 'package:retailpos/View/Components/ResponsiveText.dart';
import 'package:provider/provider.dart';
import 'package:retailpos/Helper/AppColor.dart';
import 'package:retailpos/View/Components/AuthFormWidget.dart';
import 'package:retailpos/Provider/AuthProvider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;

  void _toggleAuthMode() {
    setState(() => _isSignUp = !_isSignUp);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, TabProvider>(
      builder: (context, authProvider, tabProvider, _) {
        return Scaffold(
          backgroundColor: AppColor.background,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ Unified Header
                    Text(
                      _isSignUp ? "Create Your Store" : "Welcome Back",
                      style: TextStyle(
                        fontSize: context.rf(22),
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Auth Form
                    AuthFormWidget(
                      isSignUp: _isSignUp,
                      toggleMode: _toggleAuthMode,
                      onSubmit: ({
                        required String storeName,
                        required String ownerName,
                        required String email,
                        required String password,
                        required bool isSignUp,
                      }) async {
                        try {
                          if (isSignUp) {
                            await authProvider.signUp(
                              email: email,
                              password: password,
                              storeName: storeName,
                              ownerName: ownerName,
                            );
                          } else {
                            await authProvider.signIn(
                              email: email,
                              password: password,
                            );
                          }

                          final userData = await authProvider.getStoredUser();
                          final storeNameOffline = userData['storeName'] ?? 'your store';
                          final ownerNameOffline = userData['ownerName'] ?? 'Owner';

                          await showDialog(
                            context: context,
                            builder: (_) => CustomNotificationDialog(
                              title: isSignUp ? "Account Created" : "Signed In",
                              content: isSignUp
                                  ? "🎉 Your store \"$storeNameOffline\" has been successfully created.\nWelcome, $ownerNameOffline!"
                                  : "You're now signed in to \"$storeNameOffline\".\nGlad to have you here, $ownerNameOffline!",
                              type: "success",
                              onConfirm: () async {
                                Navigator.of(context, rootNavigator: true).pop();
                                if (isSignUp) {
                                  _toggleAuthMode();
                                } else {
                                  await tabProvider.setFirstTimeFlag(false);
                                  if (!tabProvider.isFirstTime) {
                                    Phoenix.rebirth(context);
                                  }
                                }
                              },
                            ),
                          );
                        } catch (e) {
                          await showDialog(
                            context: context,
                            builder: (_) => CustomNotificationDialog(
                              title: "Authentication Failed",
                              content: e.toString(),
                              type: "error",
                              onConfirm: () {
                                Navigator.pop(context);
                              },
                            ),
                          );
                        }
                      },
                    ),

                    if (authProvider.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
