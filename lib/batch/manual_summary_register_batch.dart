import 'package:flutter/material.dart';

sealed class BatchState {}

class InitState extends BatchState {}

// --- Events ---
// The event class only needs its data if the event occurs outside of the Batch class.
sealed class BatchEvent {}

class Batch {
  final ValueNotifier<BatchState> _state = ValueNotifier(InitState());

  ValueNotifier<BatchState> get state => _state;
}
