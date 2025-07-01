import 'package:flutter/material.dart';

class RaceUtils {
  static String formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toStringAsFixed(1).padLeft(4, '0')}';
  }

  static String formatTimeDiff(double seconds) {
    if (seconds <= 0) return '0:00.0';
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toStringAsFixed(1).padLeft(4, '0')}';
  }

  static String countryToFlag(String country) {
    final map = {
      'France': 'FR',
      'Norway': 'NO',
      'Germany': 'DE',
      'Russia': 'RU',
      'Italy': 'IT',
      'Poland': 'PL',
      'Czech Republic': 'CZ',
      'Austria': 'AT',
      'Belarus': 'BY',
      'Finland': 'FI',
      'Sweden': 'SE',
      'Slovakia': 'SK',
      'Ukraine': 'UA',
      'Japan': 'JP',
      'South Korea': 'KR',
      'Slovenia': 'SI',
      'Estonia': 'EE',
      'Switzerland': 'CH',
      'Lithuania': 'LT',
      'Latvia': 'LV',
    };
    final code = map[country] ?? '';
    if (code.length != 2) return '';
    return String.fromCharCodes([
      code.codeUnitAt(0) + 0x1F1A5,
      code.codeUnitAt(1) + 0x1F1A5,
    ]);
  }

  static String countryToFlagAsset(String country) {
    final map = {
      'France': 'FR',
      'Norway': 'NO',
      'Germany': 'DE',
      'Russia': 'RU',
      'Italy': 'IT',
      'Poland': 'PL',
      'Czech Republic': 'CZ',
      'Austria': 'AT',
      'Belarus': 'BY',
      'Finland': 'FI',
      'Sweden': 'SE',
      'Slovakia': 'SK',
      'Ukraine': 'UA',
      'Japan': 'JP',
      'South Korea': 'KR',
      'Slovenia': 'SI',
      'Estonia': 'EE',
      'Switzerland': 'CH',
      'Lithuania': 'LT',
      'Latvia': 'LV',
      'USA': 'US',
      'Croatia': 'HR',
      'Denmark': 'DK',
      'New Zealand': 'NZ',
    };
    final code = map[country] ?? '';
    if (code.isEmpty) return '';
    return 'assets/flags/$code.png';
  }

  static Widget flagImage(String country, {double size = 20}) {
    final asset = countryToFlagAsset(country);
    if (asset.isEmpty) return const SizedBox.shrink();
    return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
  }

  static InlineSpan buildFlagNameSpan(String flag, String name, String surname) {
    return TextSpan(children: [
      TextSpan(
        text: flag.isNotEmpty ? '$flag ' : '', 
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal, height: 1)
      ),
      TextSpan(
        text: '$name $surname', 
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)
      ),
    ]);
  }
} 