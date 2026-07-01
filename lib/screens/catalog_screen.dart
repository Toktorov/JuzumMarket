import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/product_card.dart';
import '../l10n/l10n.dart';

class CatalogScreen extends StatefulWidget {
  /// Если экран открыт как отдельная страница (из Главной) — показываем кнопку «назад».
  final bool standalone;
  final String initialCategory;
  final String initialQuery;

  const CatalogScreen({
    super.key,
    this.standalone = false,
    this.initialCategory = 'Все',
    this.initialQuery = '',
  });

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late String _selectedCategory = widget.initialCategory;
  late String _searchQuery = widget.initialQuery;
  late final _searchController =
      TextEditingController(text: widget.initialQuery);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    // Категории: ключ (для фильтра) + подпись (на текущем языке).
    final allCategories = <({String key, String label})>[
      (key: 'Все', label: context.tr('Все')),
      for (final cat in state.categoryList) (key: cat.key, label: cat.label),
    ];

    final products = _searchQuery.isNotEmpty
        ? state.search(_searchQuery)
        : state.getByCategory(_selectedCategory);

    final body = Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              if (widget.standalone)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 20, color: c.ink),
                  ),
                ),
              Text(
                context.tr('Каталог'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (v) {
              setState(() => _searchQuery = v);
              context.read<AppState>().recordSearch(v);
            },
            decoration: InputDecoration(
              hintText: context.tr('Искать товары...'),
              prefixIcon: Icon(Icons.search, color: c.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Icon(Icons.close, color: c.grey),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Categories
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = allCategories[i];
              final isSelected =
                  _selectedCategory == cat.key && _searchQuery.isEmpty;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCategory = cat.key;
                  _searchQuery = '';
                  _searchController.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.gradient : null,
                    color: isSelected ? null : c.tint,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected ? null : Border.all(color: c.line),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.white : c.ink,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Grid
        Expanded(
          child: (state.catalogLoading && products.isEmpty)
              ? const Center(child: CircularProgressIndicator())
              : products.isEmpty
              ? Center(
                  child: Text(
                    context.tr('Ничего не найдено'),
                    style: TextStyle(color: c.grey, fontSize: 16),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) => ProductCard(product: products[i]),
                ),
        ),
      ],
    );

    if (widget.standalone) {
      return Scaffold(body: SafeArea(child: body));
    }
    return SafeArea(child: body);
  }
}
