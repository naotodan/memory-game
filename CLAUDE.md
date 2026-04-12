# Memory Game App

## Overview
A number memory game where numbers are displayed on a grid,
hidden after a few seconds, and the player taps them in order.

## Tech Stack
- Flutter (Dart)
- Target: iOS / Android
- State management: flutter_riverpod

## Game Rules
- Numbers are randomly placed on a grid (e.g. 3x4)
- All cards flip face-down after N seconds
- Player taps cards in numerical order (1, 2, 3...)
- Judge correct / incorrect / clear
- Record score, time, and level

## Directory Structure
lib/
  main.dart
  features/
    game/
      game_screen.dart
      game_controller.dart
      card_widget.dart
    home/
      home_screen.dart
    result/
      result_screen.dart

## Coding Rules
- One responsibility per file
- Use Flutter standard AnimationController for animations
- No hardcoding (constants go in constants.dart)
- Write comments in Japanese