import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/settings/data/product/product_model.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/products_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/products_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/products_state.dart';
import 'package:whats_order/features/settings/presentation/screens/add_product_screen.dart';
import 'package:whats_order/features/settings/presentation/utils/products_listing.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/product_card.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/products_empty_state.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/products_error_view.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/products_filters.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/products_header.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/products_pagination.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/products_statistics.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/products_style.dart';
import 'package:whats_order/injection/injection_container.dart';

/*
|--------------------------------------------------------------------------
| ProductsScreen — the vendor's products (services), loaded from
| POST /api/auth/vendor-services/getServicesForVendor.
|
| The screen only coordinates: the Bloc loads products, [ProductsListing]
| filters and paginates them, and the widgets under widgets/products render.
|--------------------------------------------------------------------------
*/

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductsBloc>()..add(_fetchEvent()),
      child: const _ProductsView(),
    );
  }
}

FetchProductsEvent _fetchEvent() => FetchProductsEvent(
  vendorId:
      CacheHelper.getDataFromSharedPreference(
        key: CacheKeys.vendorId,
      )?.toString() ??
      '',
);

class _ProductsView extends StatefulWidget {
  const _ProductsView();

  @override
  State<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<_ProductsView> {
  static const _contentPadding = EdgeInsets.fromLTRB(16, 8, 16, 24);

  final _searchController = TextEditingController();

  String _query = '';
  String? _sectorId;
  int _page = 0;

  // Filtering/pagination is derived from the inputs above, so it is computed
  // once per change instead of on every rebuild.
  List<ProductModel>? _source;
  ProductsListing? _listing;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ProductsListing _listingFor(List<ProductModel> products) {
    final cached = _listing;
    if (cached != null && identical(_source, products)) return cached;

    _source = products;
    return _listing = ProductsListing.from(
      products,
      query: _query,
      sectorId: _sectorId,
      page: _page,
    );
  }

  void _updateFilters(VoidCallback change) => setState(() {
    change();
    _listing = null;
  });

  void _onQueryChanged(String value) => _updateFilters(() {
    _query = value;
    _page = 0;
  });

  void _onSectorChanged(String? value) => _updateFilters(() {
    _sectorId = value;
    _page = 0;
  });

  void _onPageChanged(int value) => _updateFilters(() => _page = value);

  /// A refresh can drop the selected sector; fall back to "all" instead of
  /// keeping a filter the dropdown can no longer show.
  void _onProductsLoaded(List<ProductModel> products) {
    final sectorId = _sectorId;
    if (sectorId == null || ProductsListing.hasSector(products, sectorId)) {
      return;
    }
    _updateFilters(() {
      _sectorId = null;
      _page = 0;
    });
  }

  void _reload() => context.read<ProductsBloc>().add(_fetchEvent());

  Future<void> _refresh() {
    final bloc = context.read<ProductsBloc>();
    // Listen before dispatching so the result can't be missed.
    final settled = bloc.stream.firstWhere(
      (state) => state is! ProductsLoadingState,
      orElse: () => bloc.state,
    );
    _reload();
    return settled;
  }

  Future<void> _openAddProduct() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (added == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(context.tr('products'), style: AppTextStyles.heading18),
      ),
      body: BlocConsumer<ProductsBloc, ProductsState>(
        listenWhen: (_, current) => current is ProductsLoadedState,
        listener: (_, state) {
          if (state is ProductsLoadedState) _onProductsLoaded(state.products);
        },
        // Keep the list on screen while it reloads so a pull-to-refresh
        // isn't torn down by a full-screen spinner.
        buildWhen: (previous, current) =>
            !(previous is ProductsLoadedState &&
                current is ProductsLoadingState),
        builder: (context, state) {
          if (state is ProductsLoadedState) {
            return _buildLoaded(_listingFor(state.products));
          }
          if (state is ProductsErrorState) {
            return ProductsErrorView(message: state.message, onRetry: _reload);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildLoaded(ProductsListing listing) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        // Lets pull-to-refresh work even when the list is shorter than the
        // viewport.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: _contentPadding,
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductsHeader(
                        productsCount: listing.totalCount,
                        onAddProduct: _openAddProduct,
                      ),
                      const SizedBox(height: 16),
                      ProductsStatistics(
                        productsCount: listing.totalCount,
                        categoriesCount: listing.sectors.length,
                      ),
                      const SizedBox(height: 16),
                      ProductsFilters(
                        searchController: _searchController,
                        onQueryChanged: _onQueryChanged,
                        sectors: listing.sectors,
                        selectedSectorId: _sectorId,
                        onSectorChanged: _onSectorChanged,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                if (listing.isEmpty)
                  const SliverToBoxAdapter(child: ProductsEmptyState())
                else
                  SliverList.builder(
                    itemCount: listing.pageItems.length,
                    itemBuilder: (context, index) {
                      final product = listing.pageItems[index];
                      return Padding(
                        key: ValueKey(product.id),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ProductCard(
                          product: product,
                          tileColor: ProductsStyle.tileColor(
                            listing.firstIndex + index,
                          ),
                        ),
                      );
                    },
                  ),
                if (listing.filteredCount > 0)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 6),
                    sliver: SliverToBoxAdapter(
                      child: ProductsPagination(
                        from: listing.firstIndex + 1,
                        to: listing.firstIndex + listing.pageItems.length,
                        total: listing.filteredCount,
                        page: listing.page,
                        pageCount: listing.pageCount,
                        onPageChanged: _onPageChanged,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
