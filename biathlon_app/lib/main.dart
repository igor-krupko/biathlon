import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/app_bloc_provider.dart';
import 'blocs/app_bloc_observer.dart';
import 'router/app_router.dart';
import 'widgets/error_display.dart';

void main() {
  Bloc.observer = AppBlocObserver();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBlocProvider(
      child: MaterialApp.router(
        title: 'Biathlon Career',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
        builder: (context, child) {
          return Stack(
            children: [
              child!,
              const ErrorDisplay(),
            ],
          );
        },
      ),
    );
  }
}
