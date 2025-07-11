import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../model/addon_model.dart';

class AddonProvider extends ChangeNotifier {
  final Box<Addon> _addonBox = Hive.box<Addon>('addons');

  // ─────────────────────────────────────────────────────────────
  // GET: All non-deleted addons
  List<Addon> get allAddons =>
      _addonBox.values.where((a) => !a.isDeleted).toList();

  // GET: Single addon by ID
  Addon? getById(String id) => _addonBox.values.firstWhere(
        (addon) => addon.addonId == id && !addon.isDeleted,
  );

  // ─────────────────────────────────────────────────────────────
  // ADD: New addon
  Future<void> addAddon(Addon addon) async {
    await _addonBox.put(addon.addonId, addon);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE: Existing addon
  Future<void> updateAddon(Addon updatedAddon) async {
    if (_addonBox.containsKey(updatedAddon.addonId)) {
      await _addonBox.put(updatedAddon.addonId, updatedAddon);
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE: Soft delete (sets isDeleted = true)
  Future<void> deleteAddon(String id) async {
    final addon = _addonBox.get(id);
    if (addon != null) {
      addon.isDeleted = true;
      await addon.save();
      notifyListeners();
    }
  }

  // PERMANENT DELETE: Optional if you want hard delete
  Future<void> deletePermanently(String id) async {
    await _addonBox.delete(id);
    notifyListeners();
  }

  // RESTORE: If deleted, undo it
  Future<void> restoreAddon(String id) async {
    final addon = _addonBox.get(id);
    if (addon != null && addon.isDeleted) {
      addon.isDeleted = false;
      await addon.save();
      notifyListeners();
    }
  }

  // FILTER: Get addons applied to a product
  List<Addon> getAddonsForProduct(String productId) {
    return _addonBox.values
        .where((addon) =>
    !addon.isDeleted &&
        addon.appliesTo != null &&
        addon.appliesTo!.contains(productId))
        .toList();
  }
}
