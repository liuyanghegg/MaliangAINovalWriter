import 'package:flutter/material.dart';

abstract class ThemeEvent {}

class ThemeInitialize extends ThemeEvent {}

class ThemeChanged extends ThemeEvent {
  final ThemeMode themeMode;

  ThemeChanged(this.themeMode);
}

class ThemeToggled extends ThemeEvent {}