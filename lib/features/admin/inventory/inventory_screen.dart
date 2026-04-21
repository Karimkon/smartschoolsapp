import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class _Item {
  final int id;
  final String name, category, unit;
  final int quantity, minStock;
  const _Item({required this.id, required this.name, required this.category,
    required this.unit, required this.quantity, required this.minStock});
  String get status => quantity <= 0 ? 'Out of Stock' : quantity <= minStock ? 'Low Stock' : 'In Stock';
  Color get statusColor => quantity <= 0 ? AppColors.error : quantity <= minStock ? AppColors.warning : AppColors.success;
}

const _mockItems = [
  _Item(id:1, name:'Whiteboard Markers',  category:'Stationery',  unit:'Box',     quantity:15, minStock:5),
  _Item(id:2, name:'Exercise Books',      category:'Stationery',  unit:'Ream',    quantity:8,  minStock:10),
  _Item(id:3, name:'Printer Paper A4',    category:'Stationery',  unit:'Ream',    quantity:25, minStock:8),
  _Item(id:4, name:'Laboratory Gloves',   category:'Lab',         unit:'Box',     quantity:3,  minStock:5),
  _Item(id:5, name:'Bunsen Burners',      category:'Lab',         unit:'Units',   quantity:12, minStock:4),
  _Item(id:6, name:'Classroom Chairs',    category:'Furniture',   unit:'Units',   quantity:0,  minStock:10),
  _Item(id:7, name:'Teacher Desks',       category:'Furniture',   unit:'Units',   quantity:6,  minStock:2),
  _Item(id:8, name:'Footballs',           category:'Sports',      unit:'Units',   quantity:4,  minStock:3),
  _Item(id:9, name:'Volleyballs',         category:'Sports',      unit:'Units',   quantity:2,  minStock:3),
  _Item(id:10,name:'First Aid Kits',      category:'Medical',     unit:'Kits',    quantity:5,  minStock:2),
];

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _cat = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<String> get _cats => ['All', ..._mockItems.map((i) => i.category).toSet().toList()..sort()];

  List<_Item> get _filtered => _mockItems.where((i) {
    final mc = _cat == 'All' || i.category == _cat;
    final mq = _query.isEmpty || i.name.toLowerCase().contains(_query.toLowerCase());
    return mc && mq;
  }).toList();

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Stationery': return Icons.edit_rounded;
      case 'Lab':        return Icons.science_rounded;
      case 'Furniture':  return Icons.chair_rounded;
      case 'Sports':     return Icons.sports_soccer_rounded;
      case 'Medical':    return Icons.medical_services_rounded;
      default:           return Icons.inventory_2_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final lowCount = _mockItems.where((i) => i.quantity <= i.minStock).length;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('Inventory', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          if (lowCount > 0)
            Container(margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.warning_rounded, color: AppColors.warning, size: 14),
                const SizedBox(width: 4),
                Text('$lowCount low', style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16,16,16,0),
            child: Column(children: [
              AppSearchField(hint: 'Search items...', controller: _searchCtrl, onChanged: (v) => setState(() => _query = v)).animate().fadeIn(),
              const SizedBox(height: 12),
              SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: _cats.map((c) {
                final sel = c == _cat;
                return Padding(padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(onTap: () => setState(() => _cat = c),
                    child: AnimatedContainer(duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.success : AppColors.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? AppColors.success : Colors.white.withOpacity(0.07)),
                      ),
                      child: Text(c, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  ),
                );
              }).toList())).animate(delay: 100.ms).fadeIn(),
            ]),
          ),
          Expanded(child: items.isEmpty
            ? const Center(child: Text('No items found', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16,12,16,80),
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  return Padding(padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Container(width: 46, height: 46,
                          decoration: BoxDecoration(color: item.statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                          child: Icon(_catIcon(item.category), color: item.statusColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 3),
                          Row(children: [
                            StatusBadge(label: item.category, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('Min: ${item.minStock} ${item.unit}', style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                          ]),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${item.quantity}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: item.statusColor)),
                          Text(item.unit, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                          const SizedBox(height: 4),
                          StatusBadge(label: item.status, color: item.statusColor),
                        ]),
                      ]),
                    ),
                  ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05, end: 0);
                },
              ),
          ),
        ]),
      ),
    );
  }
}
