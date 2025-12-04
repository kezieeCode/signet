part of 'example_cubit.dart';

class ExampleState {
  final int count;
  const ExampleState({required this.count});

  const ExampleState.initial() : count = 0;

  ExampleState copyWith({int? count}) {
    return ExampleState(count: count ?? this.count);
  }
}
