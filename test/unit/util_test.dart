import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/util.dart';

void main() {
  group('NumberPtBrExtension Tests', () {
    test('toCurrency formats numbers in Brazilian Real format', () {
      expect(1234.56.toCurrency(), contains('1.234,56'));
      expect(0.0.toCurrency(), contains('0,00'));
      expect((-50.0).toCurrency(), contains('50,00'));
      expect((-50.0).toCurrency(), contains('-R\$'));
    });

    test('toPtBr formats decimals properly with fractionDigits', () {
      expect(1234.56.toPtBr(), '1.234,56');
      expect(100.toPtBr(compactIfInteger: true), '100');
      expect(100.5.toPtBr(fractionDigits: 1), '100,5');
    });
  });

  group('HexColor Extension Tests', () {
    test('fromHex parses 6-digit and 8-digit hex strings with or without hash', () {
      final c1 = HexColor.fromHex('#ff0000');
      expect(c1.r, closeTo(1.0, 0.01));
      expect(c1.g, closeTo(0.0, 0.01));
      expect(c1.b, closeTo(0.0, 0.01));

      final c2 = HexColor.fromHex('00ff00');
      expect(c2.g, closeTo(1.0, 0.01));

      final c3 = HexColor.fromHex('#800000ff');
      expect(c3.b, closeTo(1.0, 0.01));
    });

    test('toHex converts Color back to Hex format', () {
      const color = Color(0xffff0000);
      expect(color.toHex(), '#ffff0000');
      expect(color.toHex(leadingHashSign: false), 'ffff0000');
    });
  });

  group('evaluateMathExpression Tests', () {
    test('parses simple numbers', () {
      expect(evaluateMathExpression('100'), 100.0);
      expect(evaluateMathExpression('123,45'), 123.45);
      expect(evaluateMathExpression('1.234,56'), 1234.56);
      expect(evaluateMathExpression('  50  '), 50.0);
    });

    test('evaluates basic arithmetic operations', () {
      expect(evaluateMathExpression('10 + 20'), 30.0);
      expect(evaluateMathExpression('50 - 15'), 35.0);
      expect(evaluateMathExpression('5 * 6'), 30.0);
      expect(evaluateMathExpression('100 / 4'), 25.0);
    });

    test('handles operator synonyms (x, X, ×, :, ÷)', () {
      expect(evaluateMathExpression('5 x 6'), 30.0);
      expect(evaluateMathExpression('5 X 6'), 30.0);
      expect(evaluateMathExpression('5 × 6'), 30.0);
      expect(evaluateMathExpression('100 : 4'), 25.0);
      expect(evaluateMathExpression('100 ÷ 4'), 25.0);
    });

    test('respects operator precedence and parentheses', () {
      expect(evaluateMathExpression('10 + 2 * 5'), 20.0);
      expect(evaluateMathExpression('(10 + 2) * 5'), 60.0);
      expect(evaluateMathExpression('(100 - 20) / (2 + 2)'), 20.0);
      expect(evaluateMathExpression('50 + (10 * 3) - 5'), 75.0);
    });

    test('handles unary plus and minus', () {
      expect(evaluateMathExpression('-10 + 5'), -5.0);
      expect(evaluateMathExpression('+20 - 5'), 15.0);
      expect(evaluateMathExpression('-(10 + 5)'), -15.0);
    });

    test('returns null on invalid inputs or division by zero', () {
      expect(evaluateMathExpression(''), isNull);
      expect(evaluateMathExpression('   '), isNull);
      expect(evaluateMathExpression('abc'), isNull);
      expect(evaluateMathExpression('10 / 0'), isNull);
      expect(evaluateMathExpression('(10 + 5'), isNull); // missing parenthesis
      expect(evaluateMathExpression('10 + * 5'), isNull);
      expect(evaluateMathExpression('10 +'), isNull);
    });
  });
}
