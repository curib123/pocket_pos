import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data (replace with your provider later)
    const String currency = "₱ - PHP";
    const String accountEmail = "example@email.com";
    const String aboutDev = "CuribTech Software Development Services";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Header Card
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColor.primary.withOpacity(0.85),
                        AppColor.primary.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.primary.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white24,
                        child: Icon(LucideIcons.user, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          "Your Store",
                          style: TextStyle(
                            fontSize: getResponsiveFontSize(context, 20),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Editable Currency
              _profileTile(
                context,
                icon: LucideIcons.dollarSign,
                title: "Currency",
                subtitle: currency,
                onTap: () => _editFieldDialog(context, "Currency", currency, (val) {
                  // Save new currency
                }),
              ),

              // Email (not editable)
              _profileTile(
                context,
                icon: LucideIcons.mail,
                title: "Account Email",
                subtitle: accountEmail,
              ),

              // About Developer
              _profileTile(
                context,
                icon: LucideIcons.info,
                title: "About the Developer",
                subtitle: aboutDev,
              ),

              const SizedBox(height: 30),

              // Export / Import Buttons
              FadeInUp(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Export logic
                        },
                        icon: const Icon(LucideIcons.download),
                        label: const Text("Export"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Import logic
                        },
                        icon: const Icon(LucideIcons.upload),
                        label: const Text("Import"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        VoidCallback? onTap,
      }) {
    final bool isAboutDeveloper = title == "About the Developer";

    return FadeInUp(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 6),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColor.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColor.textSecondary),
                      overflow: isAboutDeveloper ? null : TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.edit, color: AppColor.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _editFieldDialog(
      BuildContext context,
      String title,
      String initialValue,
      Function(String) onSave, {
        bool multiline = false,
      }) {
    final controller = TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit $title"),
        content: TextField(
          controller: controller,
          maxLines: multiline ? 3 : 1,
          decoration: InputDecoration(hintText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
