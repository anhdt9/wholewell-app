import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_paths.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/product/presentation/product_list_screen.dart';
import '../features/people/presentation/people_placeholder_screen.dart';
import '../features/knowledge/presentation/knowledge_placeholder_screen.dart';
import '../features/settings/presentation/settings_placeholder_screen.dart';
import '../features/product/presentation/product_detail_screen.dart';
import '../features/product/presentation/add_product/add_product_screen.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.home,
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: RoutePaths.home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: RoutePaths.products,
          name: 'products',
          builder: (context, state) => const ProductListScreen(),
        ),
        GoRoute(
          path: RoutePaths.people,
          name: 'people',
          builder: (context, state) => const PeoplePlaceholderScreen(),
        ),
        GoRoute(
          path: RoutePaths.knowledge,
          name: 'knowledge',
          builder: (context, state) => const KnowledgePlaceholderScreen(),
        ),
        GoRoute(
          path: RoutePaths.settings,
          name: 'settings',
          builder: (context, state) => const SettingsPlaceholderScreen(),
        ),
        GoRoute(
          path: RoutePaths.productDetail,
          name: 'productDetail',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            return ProductDetailScreen(productId: id);
          },
        ),
        GoRoute(
          path: RoutePaths.addProduct,
          name: 'addProduct',
          builder: (context, state) {
            final editId = int.tryParse(state.queryParameters['editId'] ?? '');
            return AddProductScreen(editProductId: editId);
          },
        ),
      ],
    )
  ],
);

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    RoutePaths.home,
    RoutePaths.products,
    RoutePaths.people,
    RoutePaths.knowledge,
    RoutePaths.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouter.of(context).location;
    final currentIndex = _currentIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          context.go(_tabs[index]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'People'),
          NavigationDestination(icon: Icon(Icons.book_outlined), label: 'Knowledge'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  int _currentIndex(String location) {
    if (location.startsWith(RoutePaths.products)) {
      return 1;
    }
    if (location.startsWith(RoutePaths.people)) {
      return 2;
    }
    if (location.startsWith(RoutePaths.knowledge)) {
      return 3;
    }
    if (location.startsWith(RoutePaths.settings)) {
      return 4;
    }
    return 0;
  }
}
