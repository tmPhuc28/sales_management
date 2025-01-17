// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_management/core/localization/app_strings.dart';
import 'package:sales_management/presentation/blocs/settings/settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/routes/app_routes.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/datasources/local/database_helper.dart';
import 'presentation/blocs/product/product_bloc.dart';
import 'presentation/blocs/cart/cart_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Database
  await DatabaseHelper.instance.database;

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({
    super.key,
    required this.prefs,
  });

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
        RepositoryProvider(
          create: (context) => SettingsRepository(
            databaseHelper: DatabaseHelper.instance,
          ),
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
          BlocProvider(
            create: (context) => SettingsBloc(
              settingsRepository: context.read<SettingsRepository>(),
              prefs: prefs,
            ),
          ),
        ],
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            final ThemeData baseTheme = ThemeData(
              useMaterial3: true,
              primarySwatch: _createMaterialColor(state.primaryColor),
              primaryColor: state.primaryColor,
              colorScheme: ColorScheme.fromSeed(
                seedColor: state.primaryColor,
                primary: state.primaryColor,
              ),
            );

            return MaterialApp(
              title: AppStrings.appName,
              themeMode: state.themeMode,
              theme: baseTheme,
              darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
                primaryColor: state.primaryColor,
                colorScheme: ColorScheme.dark(
                  primary: state.primaryColor,
                  secondary: state.primaryColor,
                ),
              ),
              // Thêm phần localization delegates
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // Hỗ trợ tiếng Việt
              supportedLocales: const [
                Locale('vi', 'VN'),
                Locale('en', 'US'),
              ],
              // Mặc định là tiếng Việt
              locale: const Locale('vi', 'VN'),
              onGenerateRoute: AppRoutes.onGenerateRoute,
              initialRoute: AppRoutes.main,
            );
          },
        ),
      ),
    );
  }

  MaterialColor _createMaterialColor(Color color) {
    List<double> strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }

    return MaterialColor(color.value, swatch);
  }
}
