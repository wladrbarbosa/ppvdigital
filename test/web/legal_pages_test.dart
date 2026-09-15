import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Páginas Legais do Seapruma (web/privacidade.html e web/termos.html)', () {
    final privacidadeFile = File('web/privacidade.html');
    final termosFile = File('web/termos.html');

    test('web/privacidade.html deve existir e ter conteúdo válido', () {
      expect(privacidadeFile.existsSync(), isTrue,
          reason: 'O arquivo web/privacidade.html deve existir');
      final content = privacidadeFile.readAsStringSync();
      expect(content.trim().isNotEmpty, isTrue,
          reason: 'web/privacidade.html não pode estar vazio');
      expect(content, contains('<!DOCTYPE html>'));
      expect(content, contains('<html'));
    });

    test('web/privacidade.html deve adotar exclusivamente a marca Seapruma sem PPVDigital', () {
      final content = privacidadeFile.readAsStringSync();
      expect(content, contains('Seapruma'));
      expect(content.toLowerCase(), isNot(contains('ppvdigital')));
      expect(content.toLowerCase(), isNot(contains('ppv digital')));
    });

    test('web/privacidade.html deve cumprir os requisitos da LGPD, Google Drive OAuth e Play Store', () {
      final content = privacidadeFile.readAsStringSync();

      // Conformidade LGPD
      expect(content.toLowerCase(), anyOf(contains('lgpd'), contains('13.709')));
      expect(content.toLowerCase(), contains('exclusão'));
      expect(content.toLowerCase(), contains('titular'));

      // Escopo Google Drive restrito
      expect(content, contains('drive.file'));
      expect(content.toLowerCase(), contains('google drive'));
      expect(content.toLowerCase(), contains('backup'));

      // Suporte e links de navegação
      expect(content, contains('suporte@seapruma.app'));
      expect(content, contains('termos.html'));
      expect(content, contains('index.html'));

      // Design System Pastel
      expect(content, contains('Plus Jakarta Sans'));
      expect(content, contains('#7CB9A8')); // Menta Pastel
      expect(content, contains('#F9FAFC')); // Background Light
    });

    test('web/termos.html deve existir e ter conteúdo válido', () {
      expect(termosFile.existsSync(), isTrue,
          reason: 'O arquivo web/termos.html deve existir');
      final content = termosFile.readAsStringSync();
      expect(content.trim().isNotEmpty, isTrue,
          reason: 'web/termos.html não pode estar vazio');
      expect(content, contains('<!DOCTYPE html>'));
      expect(content, contains('<html'));
    });

    test('web/termos.html deve adotar exclusivamente a marca Seapruma sem PPVDigital', () {
      final content = termosFile.readAsStringSync();
      expect(content, contains('Seapruma'));
      expect(content.toLowerCase(), isNot(contains('ppvdigital')));
      expect(content.toLowerCase(), isNot(contains('ppv digital')));
    });

    test('web/termos.html deve conter regras de serviço, propriedade de dados e isenção', () {
      final content = termosFile.readAsStringSync();

      // Regras e objeto
      expect(content.toLowerCase(), contains('termos de serviço'));
      expect(content.toLowerCase(), contains('aceitação'));
      expect(content.toLowerCase(), contains('propriedade'));
      expect(content.toLowerCase(), contains('responsabilidade'));

      // Backup e nuvem
      expect(content.toLowerCase(), contains('google drive'));
      expect(content.toLowerCase(), contains('backup'));

      // Isenção de consultoria financeira
      expect(content.toLowerCase(), anyOf(contains('consultoria'), contains('aconselhamento financeiro')));

      // Suporte e navegação cruzada
      expect(content, contains('suporte@seapruma.app'));
      expect(content, contains('privacidade.html'));
      expect(content, contains('index.html'));

      // Design System Pastel
      expect(content, contains('Plus Jakarta Sans'));
      expect(content, contains('#7CB9A8'));
      expect(content, contains('#F9FAFC'));
    });
  });
}
