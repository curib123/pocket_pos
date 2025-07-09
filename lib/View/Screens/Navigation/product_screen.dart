import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Screens/Navigation/ProductListScreen.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';
import 'package:paninda/View_Model/SwitchProvider.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:paninda/View/Screens/ProductList/category_product_list_screen.dart';
import 'package:paninda/View_Model/StoreCategoryProvider.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:paninda/View/Components/Core/product_metrics_container.dart';
import 'package:paninda/View/Components/Core/scalable_appbar.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/StoreCategory.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    Future.delayed(Duration.zero, () async {
      await productProvider.syncProductsWithServer();
      await productProvider.insertOrUpdateProductsToDatabase();
      await loanProvider.syncLoansWithServer();
      await loanProvider.insertOrUpdateLoansToDatabase();

    });

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScalableAppBar(),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 70),
            child: Column(
              children: [
                SizedBox(height: 10,),
                Consumer<SwitchProvider>(
                  builder: (context, switchProvider, _) {
                    return FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Product Category",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.textSecondary,
                                  ),
                                ),
                               Row(
                                 mainAxisAlignment: MainAxisAlignment.end,
                                 children: [
                                   TextButton(
                                     onPressed: () {
                                       switchProvider.toggleArchiveView();
                                     },
                                     style: TextButton.styleFrom(
                                       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                       backgroundColor: AppColor.primary,
                                       foregroundColor: AppColor.surface,
                                       minimumSize: Size.zero, // removes extra space
                                       tapTargetSize: MaterialTapTargetSize.shrinkWrap, // shrink tap area
                                     ),
                                     child: Text(
                                       !switchProvider.isArchiveView ? 'Show Categories' : 'Hide Categories',

                                       style: const TextStyle(fontSize: 14),
                                     ),
                                   ),


                                 ],
                               )
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),

                /// Category List with animations
                /// Category List with animations
                Expanded(
                  child: Consumer3<ProductProvider, StoreCategoryProvider,SwitchProvider>(
                    builder: (context, productProvider, storeCategoryProvider,switchProvider, _) {
                      final categories = !switchProvider.isArchiveView
                          ? storeCategoryProvider.visibleCategories
                          : storeCategoryProvider.hiddenCategories;

                      return Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              final offsetAnimation = Tween<Offset>(
                                begin: const Offset(0, -0.2),
                                end: Offset.zero,
                              ).animate(animation);

                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              key: ValueKey(switchProvider.isArchiveView),
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                              child: Text(
                                switchProvider.isArchiveView
                                    ? 'Swipe right to unhide categories →'
                                    : 'Swipe left to hide categories ←',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColor.textSecondary.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                          if (categories.isEmpty)
                            Expanded(
                              child: Center(
                                child: FadeIn(
                                  duration: const Duration(milliseconds: 500),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.folderOpen,
                                        size: 60,
                                        color: AppColor.textSecondary.withOpacity(0.4),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        switchProvider.isArchiveView
                                            ? 'No hidden categories yet.'
                                            : 'No categories available.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColor.textSecondary.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        switchProvider.isArchiveView
                                            ? 'Switch back to view visible categories.'
                                            : 'Add new categories to get started.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColor.textSecondary.withOpacity(0.6),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                           !switchProvider.isCategoryGridView ? Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 25),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  final icon =
                                      StoreCategory.icons[category] ?? LucideIcons.tag;
                                  final color =
                                      StoreCategory.colors[category] ?? Colors.grey;
                                  final count = productProvider.getProductCountByCategory(category);
                                  final isHidden = storeCategoryProvider.isHidden(category);

                                  return FadeInLeft(
                                    duration: Duration(milliseconds: 300),
                                    child: Slidable(
                                      key: ValueKey(category),
                                      startActionPane: isHidden
                                          ? ActionPane(
                                        motion: const ScrollMotion(),
                                        extentRatio: 0.25,
                                        children: [
                                          SlidableAction(
                                            onPressed: (_) => storeCategoryProvider
                                                .setHidden(category, false),
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            icon: LucideIcons.eye,
                                          ),
                                        ],
                                      )
                                          : null,
                                      endActionPane: !isHidden
                                          ? ActionPane(
                                        motion: const ScrollMotion(),
                                        extentRatio: 0.25,
                                        children: [
                                          SlidableAction(
                                            onPressed: (_) => storeCategoryProvider
                                                .setHidden(category, true),
                                            backgroundColor: Colors.redAccent,
                                            foregroundColor: Colors.white,
                                            icon: LucideIcons.eyeOff,
                                          ),
                                        ],
                                      )
                                          : null,
                                      child: Opacity(
                                        opacity: isHidden ? 0.3 : 1,
                                        child: ListTile(
                                          onTap: isHidden
                                              ? null
                                              : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => CategoryProductListScreen(
                                                  category: category,
                                                ),
                                              ),
                                            );
                                          },
                                          contentPadding:
                                          const EdgeInsets.symmetric(vertical: 6),
                                          leading: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(icon, color: color, size: 20),
                                          ),
                                          title: Text(
                                            category,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: AppColor.textPrimary,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Available Product : $count',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColor.textSecondary,
                                            ),
                                          ),
                                          trailing: const Icon(
                                            LucideIcons.chevronRight,
                                            color: AppColor.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ) :

                           Expanded(
                             child: SingleChildScrollView(
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                               child: GridView.builder(
                                 shrinkWrap: true,
                                 physics: const NeverScrollableScrollPhysics(),
                                 itemCount: categories.length,
                                 gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                   maxCrossAxisExtent: 180, // Auto adjusts per screen size
                                   mainAxisSpacing: 16,
                                   crossAxisSpacing: 16,
                                   childAspectRatio: 0.85,
                                 ),
                                 itemBuilder: (context, index) {
                                   final category = categories[index];
                                   final icon = StoreCategory.icons[category] ?? LucideIcons.tag;
                                   final color = StoreCategory.colors[category] ?? Colors.grey;
                                   final count = productProvider.getProductCountByCategory(category);
                                   final isHidden = storeCategoryProvider.isHidden(category);

                                   return Slidable(
                                     key: ValueKey(category),
                                     startActionPane: isHidden
                                         ? ActionPane(
                                       motion: const ScrollMotion(),
                                       extentRatio: 1,
                                       children: [
                                         SlidableAction(
                                           onPressed: (_) => storeCategoryProvider.setHidden(category, false),
                                           backgroundColor: Colors.green,
                                           foregroundColor: Colors.white,
                                           icon: LucideIcons.eye,
                                         ),
                                       ],
                                     )
                                         : null,
                                     endActionPane: !isHidden
                                         ? ActionPane(
                                       motion: const ScrollMotion(),
                                       extentRatio: 1,
                                       children: [
                                         SlidableAction(
                                           onPressed: (_) => storeCategoryProvider.setHidden(category, true),
                                           backgroundColor: Colors.redAccent,
                                           foregroundColor: Colors.white,
                                           icon: LucideIcons.eyeOff,
                                         ),
                                       ],
                                     )
                                         : null,
                                     child: Opacity(
                                       opacity: isHidden ? 0.8 : 1,
                                       child: GestureDetector(
                                         onTap: isHidden
                                             ? null
                                             : () {
                                           Navigator.push(
                                             context,
                                             MaterialPageRoute(
                                               builder: (_) => CategoryProductListScreen(category: category),
                                             ),
                                           );
                                         },
                                         child: Container(
                                           decoration: BoxDecoration(
                                             color: AppColor.surface,
                                             borderRadius: BorderRadius.circular(16),
                                             border: Border.all(
                                               color: AppColor.border.withOpacity(0.2),
                                               width: 1,
                                             ),
                                             boxShadow: [
                                               BoxShadow(
                                                 color: Colors.black.withOpacity(0.03),
                                                 blurRadius: 6,
                                                 offset: const Offset(0, 1),
                                               ),
                                             ],
                                           ),
                                           padding: const EdgeInsets.all(16),
                                           child: Column(
                                             mainAxisAlignment: MainAxisAlignment.center,
                                             children: [
                                               Container(
                                                 width: 50,
                                                 height: 50,
                                                 decoration: BoxDecoration(
                                                   color: color.withOpacity(0.15),
                                                   shape: BoxShape.circle,
                                                 ),
                                                 child: Icon(icon, color: color, size: 24),
                                               ),
                                               const SizedBox(height: 12),
                                               Text(
                                                 category,
                                                 textAlign: TextAlign.center,
                                                 style: const TextStyle(
                                                   fontWeight: FontWeight.w600,
                                                   fontSize: 15,
                                                   color: AppColor.textPrimary,
                                                 ),
                                               ),
                                               const SizedBox(height: 4),
                                               Text(
                                                 'Available Product: $count',
                                                 textAlign: TextAlign.center,
                                                 style: const TextStyle(
                                                   fontSize: 12,
                                                   color: AppColor.textSecondary,
                                                 ),
                                               ),
                                             ],
                                           ),
                                         ),
                                       ),
                                     ),
                                   );
                                 },
                               ),
                             ),
                           ),


                        ],
                      );
                    },
                  ),
                ),

              ],
            ),
          ),

          /// Add Product Button with animation
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    CustomButton(
                      color: AppColor.primary,
                      icon: LucideIcons.box,
                      label: "View All Product",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProductListScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          Consumer<SwitchProvider>(
            builder: (context,switchProvider,_) {
              return Align(
                alignment: Alignment.bottomRight,
                child: FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 70),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColor.primary.withOpacity(0.9), // Background color of the circle
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              switchProvider.toggleCategoryGridView();
                            },
                            icon: !switchProvider.isCategoryGridView ? const Icon(Icons.dashboard, color: Colors.white) : const Icon(Icons.layers, color: Colors.white),
                            iconSize: 24, // Optional: size of the icon
                            padding: const EdgeInsets.all(12), // Controls inner padding
                            constraints: const BoxConstraints(), // Removes extra constraints
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          )

        ],
      ),
    );
  }
}
