import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:record/services/auth_service.dart';
import 'package:record/screens/auth/login_screen.dart';
import 'package:record/screens/auth/register_screen.dart';
import 'package:record/screens/home/home_screen.dart';
import 'package:record/screens/product/product_checkin.dart';
import 'package:record/screens/product/product_checkout.dart';
import 'package:record/screens/shipment/shipment_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Product Management System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/product-checkout': (context) => const ProductCheckoutScreen(),
          '/shipments': (context) => const ShipmentListScreen(),
        },
      ),
    );
  }
}
