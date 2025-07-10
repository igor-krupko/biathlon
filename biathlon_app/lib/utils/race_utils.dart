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
      'USA': 'US',
      'United States': 'US',
      'Croatia': 'HR',
      'Denmark': 'DK',
      'New Zealand': 'NZ',
      'Argentina': 'AR',
      'Chile': 'CL',
      'Bulgaria': 'BG',
      'Canada': 'CA',
      'China': 'CN',
      'Great Britain': 'GB',
      'Hungary': 'HU',
      'Greece': 'GR',
      'Romania': 'RO',
      'Serbia': 'RS',
      'Netherlands': 'NL',
      'Moldova': 'MD',
      'Bosnia': 'BA',
      'Bosnia and Herzegovina': 'BA',
      'Kazakhstan': 'KZ',
      'Greenland': 'GL',
      'Spain': 'ES',
      'Belgium': 'BE',
      'Iceland': 'IS',
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
      'United States': 'US',
      'Croatia': 'HR',
      'Denmark': 'DK',
      'New Zealand': 'NZ',
      'Argentina': 'AR',
      'Chile': 'CL',
      'Bulgaria': 'BG',
      'Canada': 'CA',
      'China': 'CN',
      'Great Britain': 'GB',
      'Hungary': 'HU',
      'Greece': 'GR',
      'Romania': 'RO',
      'Serbia': 'RS',
      'Netherlands': 'NL',
      'Moldova': 'MD',
      'Bosnia': 'BA',
      'Bosnia and Herzegovina': 'BA',
      'Kazakhstan': 'KZ',
      'Greenland': 'GL',
      'Spain': 'ES',
      'Belgium': 'BE',
      'Iceland': 'IS',
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

  /// Returns a tuple (primary, secondary) color for a given country.
  static (Color, Color) countryColors(String country) {
    // Primary: legs, Secondary: arms
    const map = <String, List<Color>>{
      'Norway': [Color(0xFFBA0C2F), Color(0xFF00205B)], // red, blue
      'France': [Color(0xFF0055A4), Color(0xFFEF4135)], // blue, red
      'Germany': [Color(0xFF000000), Color(0xFFFFCE00)], // black, yellow
      'Russia': [Color(0xFF0039A6), Color(0xFFD52B1E)], // blue, red
      'Italy': [Color(0xFF008C45), Color(0xFFCD212A)], // green, red
      'Poland': [Color(0xFFFFFFFF), Color(0xFFDC143C)], // white, red
      'Czech Republic': [Color(0xFF11457E), Color(0xFFD7141A)], // blue, red
      'Austria': [Color(0xFFED2939), Color(0xFFFFFFFF)], // red, white
      'Belarus': [Color(0xFF00923F), Color(0xFFED2939)], // green, red
      'Finland': [Color(0xFF003580), Color(0xFFFFFFFF)], // blue, white
      'Sweden': [Color(0xFF006AA7), Color(0xFFFFCD00)], // blue, yellow
      'Slovakia': [Color(0xFF0B4EA2), Color(0xFFD7141A)], // blue, red
      'Ukraine': [Color(0xFF0057B7), Color(0xFFFFD700)], // blue, yellow
      'Japan': [Color(0xFFFFFFFF), Color(0xFFBC002D)], // white, red
      'South Korea': [Color(0xFFFFFFFF), Color(0xFF003478)], // white, blue
      'Slovenia': [Color(0xFF005DA4), Color(0xFFB6E61A)], // blue, green
      'Estonia': [Color(0xFF0072CE), Color(0xFF000000)], // blue, black
      'Switzerland': [Color(0xFFDA291C), Color(0xFFFFFFFF)], // red, white
      'Lithuania': [Color(0xFFFDB913), Color(0xFF006A44)], // yellow, green
      'Latvia': [Color(0xFF9E3039), Color(0xFFFFFFFF)], // maroon, white
      'USA': [Color(0xFF3C3B6E), Color(0xFFB22234)], // blue, red
      'United States': [Color(0xFF3C3B6E), Color(0xFFB22234)],
      'Croatia': [Color(0xFF171796), Color(0xFFFE0000)], // blue, red
      'Denmark': [Color(0xFFC60C30), Color(0xFFFFFFFF)], // red, white
      'New Zealand': [Color(0xFF00247D), Color(0xFFFFFFFF)], // blue, white
      'Argentina': [Color(0xFF74ACDF), Color(0xFFF6B40E)], // blue, yellow
      'Chile': [Color(0xFF0033A0), Color(0xFFD52B1E)], // blue, red
      'Bulgaria': [Color(0xFF00966E), Color(0xFFD62612)], // green, red
      'Canada': [Color(0xFFEF3340), Color(0xFFFFFFFF)], // red, white
      'China': [Color(0xFFDE2910), Color(0xFFFFDE00)], // red, yellow
      'Great Britain': [Color(0xFF00247D), Color(0xFFCF142B)], // blue, red
      'Hungary': [Color(0xFF436F4D), Color(0xFFCD2A3E)], // green, red
      'Greece': [Color(0xFF0D5EAF), Color(0xFFFFFFFF)], // blue, white
      'Romania': [Color(0xFF002B7F), Color(0xFFFCD116)], // blue, yellow
      'Serbia': [Color(0xFF0C4076), Color(0xFFDE2910)], // blue, red
      'Netherlands': [Color(0xFFFF6600), Color(0xFF21468B)], // orange, blue
      'Moldova': [Color(0xFF0033A0), Color(0xFFFFD700)], // blue, yellow
      'Bosnia': [Color(0xFF002395), Color(0xFFFFD700)], // blue, yellow
      'Bosnia and Herzegovina': [Color(0xFF002395), Color(0xFFFFD700)],
      'Kazakhstan': [Color(0xFF00AFCA), Color(0xFFFFD600)], // blue, yellow
      'Greenland': [Color(0xFFEB0029), Color(0xFFFFFFFF)], // red, white
      'Spain': [Color(0xFFAA151B), Color(0xFFF1BF00)], // red, yellow
      'Belgium': [Color(0xFF000000), Color(0xFFFFD700)], // black, yellow
      'Iceland': [Color(0xFF003897), Color(0xFFDC1E35)], // blue, red
    };
    final colors = map[country] ?? [Colors.grey, Colors.grey];
    return (colors[0], colors[1]);
  }
} 