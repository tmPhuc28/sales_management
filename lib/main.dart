// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/routes/app_routes.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/order_repository.dart';
import 'presentation/blocs/product/product_bloc.dart';
import 'presentation/blocs/cart/cart_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Cấu hình chỉ cho phép chế độ dọc
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => ProductRepository(),
        ),
        RepositoryProvider(
          create: (context) => CategoryRepository(),
        ),
        RepositoryProvider(
          create: (context) => OrderRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ProductBloc(
              productRepository: context.read<ProductRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => CartBloc(),
          ),
        ],
        child: MaterialApp(
          title: 'Sales Management',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.main,
        ),
      ),
    );
  }
}
