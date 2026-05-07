import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final inventoryProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, query) async {
  final params = query.isNotEmpty ? {'search': query} : <String, dynamic>{};
  final res = await ApiService().get('/inventory', params: params);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

IconData _catIcon(String cat) {
  switch (cat.toLowerCase()) {
    case 'stationery': return Icons.edit_rounded;
    case 'lab':        return Icons.science_rounded;
    case 'furniture':  return Icons.chair_rounded;
    case 'sports':     return Icons.sports_soccer_rounded;
    case 'medical':    return Icons.medical_services_rounded;
    default:           return Icons.inventory_2_rounded;
  }
}

String _itemStatus(int qty, int minStock) {
  if (qty <= 0) return 'Out of Stock';
  if (qty <= minStock) return 'Low Stock';
  return 'In Stock';
}

Color _statusColor(int qty, int minStock) {
  if (qty <= 0) return AppColors.error;
  if (qty <= minStock) return AppColors.warning;
  return AppColors.success;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _cat = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  List<dynamic> _filterByCat(List<dynamic> items) {
    if (_cat == 'All') return items;
    return items.where((i) {
      return (i['category'] ?? '').toString().toLowerCase() == _cat.toLowerCase();
    }).toList();
  }

  List<String> _getCategories(List<dynamic> items) {
    final cats = items
        .map((i) => (i['category'] ?? '').toString())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inventoryProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Inventory',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          async.maybeWhen(
            data: (data) {
              final items = List<dynamic>.from(data['data'] ?? data['inventory'] ?? []);
              final lowCount = items.where((i) {
                final qty = i['quantity'] as int? ?? 0;
                final min = i['min_stock'] as int? ?? i['minimum_stock'] as int? ?? 0;
                return qty <= min;
              }).length;
              if (lowCount == 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.warning_rounded, color: AppColors.warning, size: 14),
                  const SizedBox(width: 4),
                  Text('$lowCount low',
                      style: const TextStyle(
                          color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: async.when(
          loading: () => Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(children: [
                ShimmerCard(height: 44, radius: 14),
                const SizedBox(height: 12),
                ShimmerCard(height: 36, radius: 20),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: 6,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ShimmerCard(height: 72, radius: 14),
                ),
              ),
            ),
          ]),
          error: (e, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load inventory',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(inventoryProvider),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Retry'),
              ),
            ]),
          ),
          data: (data) {
            final allItems = List<dynamic>.from(data['data'] ?? data['inventory'] ?? []);
            final cats = _getCategories(allItems);
            final items = _filterByCat(allItems);

            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(children: [
                  AppSearchField(
                    hint: 'Search items...',
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                  ).animate().fadeIn(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: cats.map((c) {
                        final sel = c == _cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _cat = c),
                            child: AnimatedContainer(
                              duration: 200.ms,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.success : AppColors.surface2,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel ? AppColors.success : Colors.white.withOpacity(0.07),
                                ),
                              ),
                              child: Text(c,
                                  style: TextStyle(
                                      color: sel ? Colors.white : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate(delay: 100.ms).fadeIn(),
                ]),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text('No items found',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(inventoryProvider),
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: items.length,
                          itemBuilder: (ctx, i) {
                            final item = items[i];
                            final name = item['name'] ?? item['item_name'] ?? 'Item';
                            final category = item['category'] ?? '';
                            final unit = item['unit'] ?? 'Units';
                            final qty = item['quantity'] as int? ?? 0;
                            final minStock = item['min_stock'] as int? ??
                                item['minimum_stock'] as int? ?? 0;
                            final sc = _statusColor(qty, minStock);
                            final statusLabel = _itemStatus(qty, minStock);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(children: [
                                  Container(
                                    width: 46, height: 46,
                                    decoration: BoxDecoration(
                                      color: sc.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(_catIcon(category.toString()),
                                        color: sc, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name.toString(),
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary)),
                                        const SizedBox(height: 3),
                                        Row(children: [
                                          StatusBadge(label: category.toString(), color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          if (minStock > 0)
                                            Text('Min: $minStock $unit',
                                                style: const TextStyle(
                                                    fontSize: 10, color: AppColors.textHint)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text('$qty',
                                        style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: sc)),
                                    Text(unit.toString(),
                                        style: const TextStyle(
                                            fontSize: 10, color: AppColors.textHint)),
                                    const SizedBox(height: 4),
                                    StatusBadge(label: statusLabel, color: sc),
                                  ]),
                                ]),
                              ),
                            ).animate(delay: Duration(milliseconds: i * 40))
                                .fadeIn()
                                .slideX(begin: 0.05, end: 0);
                          },
                        ),
                      ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
