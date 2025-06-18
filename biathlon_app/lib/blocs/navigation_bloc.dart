import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class NavigateTo extends NavigationEvent {
  final String route;
  final Map<String, dynamic>? arguments;

  const NavigateTo(this.route, {this.arguments});

  @override
  List<Object?> get props => [route, arguments];
}

class NavigateBack extends NavigationEvent {}

class NavigateToHome extends NavigationEvent {}

class NavigateToCareer extends NavigationEvent {}

class NavigateToRace extends NavigationEvent {}

class NavigateToPoints extends NavigationEvent {}

// States
abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object?> get props => [];
}

class NavigationInitial extends NavigationState {}

class NavigationActive extends NavigationState {
  final String currentRoute;
  final List<String> routeHistory;
  final Map<String, dynamic>? currentArguments;

  const NavigationActive({
    required this.currentRoute,
    required this.routeHistory,
    this.currentArguments,
  });

  @override
  List<Object?> get props => [currentRoute, routeHistory, currentArguments];

  NavigationActive copyWith({
    String? currentRoute,
    List<String>? routeHistory,
    Map<String, dynamic>? currentArguments,
  }) {
    return NavigationActive(
      currentRoute: currentRoute ?? this.currentRoute,
      routeHistory: routeHistory ?? this.routeHistory,
      currentArguments: currentArguments ?? this.currentArguments,
    );
  }
}

// BLoC
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(NavigationInitial()) {
    on<NavigateTo>(_onNavigateTo);
    on<NavigateBack>(_onNavigateBack);
    on<NavigateToHome>(_onNavigateToHome);
    on<NavigateToCareer>(_onNavigateToCareer);
    on<NavigateToRace>(_onNavigateToRace);
    on<NavigateToPoints>(_onNavigateToPoints);
  }

  void _onNavigateTo(NavigateTo event, Emitter<NavigationState> emit) {
    if (state is NavigationActive) {
      final currentState = state as NavigationActive;
      final newHistory = List<String>.from(currentState.routeHistory)..add(event.route);
      emit(currentState.copyWith(
        currentRoute: event.route,
        routeHistory: newHistory,
        currentArguments: event.arguments,
      ));
    } else {
      emit(NavigationActive(
        currentRoute: event.route,
        routeHistory: [event.route],
        currentArguments: event.arguments,
      ));
    }
  }

  void _onNavigateBack(NavigateBack event, Emitter<NavigationState> emit) {
    if (state is NavigationActive) {
      final currentState = state as NavigationActive;
      if (currentState.routeHistory.length > 1) {
        final newHistory = List<String>.from(currentState.routeHistory)..removeLast();
        final previousRoute = newHistory.last;
        emit(currentState.copyWith(
          currentRoute: previousRoute,
          routeHistory: newHistory,
        ));
      }
    }
  }

  void _onNavigateToHome(NavigateToHome event, Emitter<NavigationState> emit) {
    add(const NavigateTo('/'));
  }

  void _onNavigateToCareer(NavigateToCareer event, Emitter<NavigationState> emit) {
    add(const NavigateTo('/career-details'));
  }

  void _onNavigateToRace(NavigateToRace event, Emitter<NavigationState> emit) {
    add(const NavigateTo('/race'));
  }

  void _onNavigateToPoints(NavigateToPoints event, Emitter<NavigationState> emit) {
    add(const NavigateTo('/points'));
  }
} 