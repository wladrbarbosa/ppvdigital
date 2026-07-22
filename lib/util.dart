import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

extension NumberPtBrExtension on num {
  /// Formats the number as currency in pt_BR format (e.g., "R$ 1.234,56").
  String toCurrency({String symbol = 'R\$'}) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: symbol);
    return formatter.format(this);
  }

  /// Formats the number as decimal in pt_BR format (e.g., "1.234,56").
  String toPtBr({int fractionDigits = 2, bool compactIfInteger = false}) {
    if (compactIfInteger && this % 1 == 0) {
      return NumberFormat.decimalPattern('pt_BR').format(toInt());
    }
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: '')
      ..maximumFractionDigits = fractionDigits
      ..minimumFractionDigits = fractionDigits;
    return formatter.format(this).trim();
  }
}

TextTheme createTextTheme(
  BuildContext context,
  String bodyFontString,
  String displayFontString,
) {
  final TextTheme baseTextTheme = Theme.of(context).textTheme;
  try {
    final TextTheme bodyTextTheme = GoogleFonts.getTextTheme(
      bodyFontString,
      baseTextTheme,
    );
    final TextTheme displayTextTheme = GoogleFonts.getTextTheme(
      displayFontString,
      baseTextTheme,
    );
    return displayTextTheme.copyWith(
      bodyLarge: bodyTextTheme.bodyLarge,
      bodyMedium: bodyTextTheme.bodyMedium,
      bodySmall: bodyTextTheme.bodySmall,
      labelLarge: bodyTextTheme.labelLarge,
      labelMedium: bodyTextTheme.labelMedium,
      labelSmall: bodyTextTheme.labelSmall,
    );
  } catch (e) {
    debugPrint('GoogleFonts loading fallback: $e');
    return baseTextTheme;
  }
}

/// Evaluates a mathematical expression string (e.g. "10 + 15,5 * 2" or "1.234,56 / 4")
/// and returns the resulting [double], or `null` if the expression is invalid.
double? evaluateMathExpression(String input) {
  if (input.trim().isEmpty) return null;

  String expr = input.trim();
  if (expr.contains('.') && expr.contains(',')) {
    final lastDot = expr.lastIndexOf('.');
    final lastComma = expr.lastIndexOf(',');
    if (lastComma > lastDot) {
      expr = expr.replaceAll('.', '').replaceAll(',', '.');
    } else {
      expr = expr.replaceAll(',', '');
    }
  } else {
    expr = expr.replaceAll(',', '.');
  }

  expr = expr
      .replaceAll('×', '*')
      .replaceAll('x', '*')
      .replaceAll('X', '*')
      .replaceAll('÷', '/')
      .replaceAll(':', '/')
      .replaceAll(' ', '');

  // If it's already a simple number, parse directly
  final directNum = double.tryParse(expr);
  if (directNum != null) return directNum;

  try {
    final parser = _MathParser(expr);
    final result = parser.parse();
    if (result.isInfinite || result.isNaN) return null;
    return result;
  } catch (_) {
    return null;
  }
}

class _MathParser {
  _MathParser(this.text);
  final String text;
  int pos = 0;

  double parse() {
    final result = _parseExpression();
    if (pos < text.length) {
      throw const FormatException('Unexpected character');
    }
    return result;
  }

  double _parseExpression() {
    double left = _parseTerm();
    while (pos < text.length) {
      final char = text[pos];
      if (char == '+') {
        pos++;
        left += _parseTerm();
      } else if (char == '-') {
        pos++;
        left -= _parseTerm();
      } else {
        break;
      }
    }
    return left;
  }

  double _parseTerm() {
    double left = _parseFactor();
    while (pos < text.length) {
      final char = text[pos];
      if (char == '*') {
        pos++;
        left *= _parseFactor();
      } else if (char == '/') {
        pos++;
        final denominator = _parseFactor();
        if (denominator == 0) throw const FormatException('Division by zero');
        left /= denominator;
      } else {
        break;
      }
    }
    return left;
  }

  double _parseFactor() {
    if (pos < text.length && text[pos] == '-') {
      pos++;
      return -_parseFactor();
    }
    if (pos < text.length && text[pos] == '+') {
      pos++;
      return _parseFactor();
    }

    if (pos < text.length && text[pos] == '(') {
      pos++;
      final result = _parseExpression();
      if (pos < text.length && text[pos] == ')') {
        pos++;
      } else {
        throw const FormatException('Missing closing parenthesis');
      }
      return result;
    }

    final start = pos;
    while (pos < text.length &&
        ((text[pos].codeUnitAt(0) >= 48 && text[pos].codeUnitAt(0) <= 57) ||
            text[pos] == '.')) {
      pos++;
    }

    if (start == pos) {
      throw const FormatException('Expected number');
    }

    final numberStr = text.substring(start, pos);
    final number = double.tryParse(numberStr);
    if (number == null) {
      throw const FormatException('Invalid number');
    }
    return number;
  }
}
