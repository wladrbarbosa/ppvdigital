import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Regras de Negócio - Integridade de Cache e Conformidade com AGENTS.md', () {
    group('1. Regra de Seleção do Appwrite API (Query.select)', () {
      test('Proibição de usar "*" junto de wildcards de relacionamento (ex: "conta.*")', () {
        final libDir = Directory('lib');
        expect(libDir.existsSync(), isTrue, reason: 'Diretório lib deve existir');

        final files = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        final illegalPattern = RegExp(r"Query\.select\(\s*\[[^\]]*'\*'[^\]]*'[a-zA-Z0-9_]+\.\*'");

        for (final file in files) {
          final content = file.readAsStringSync();
          final hasViolation = illegalPattern.hasMatch(content);
          expect(
            hasViolation,
            isFalse,
            reason:
                'O arquivo ${file.path} viola a regra do AGENTS.md: combinou "*" com wildcard de relacionamento no Query.select()',
          );
        }
      });
    });

    group('2. Preservação de Cache Local no Drift SQLite', () {
      test('Resultados de consultas leves (lightweight) não devem corromper dados locais completos', () {
        const fullTransactionData = {
          'id': 't1',
          'descricao': 'Supermercado Completo',
          'valor': 250.0,
          'tipo': 'despesa',
          'consolidada': true,
        };

        const partialTransactionData = {
          'id': 't1',
          'descricao': null, // Query leve sem o atributo descrição
          'valor': 250.0,
          'tipo': 'despesa',
          'consolidada': true,
        };

        Map<String, dynamic>? localCache = Map.from(fullTransactionData);

        // Função utilitária que simula a lógica de atualização com proteção de cache
        void updateLocalCache(Map<String, dynamic> incoming, {required bool isLightweight}) {
          if (isLightweight) {
            // Se for resposta leve, apenas atualiza valores não-nulos ou mantém em memória sem sobrescrever o banco local
            if (localCache != null && incoming['descricao'] == null) {
              return; // Preserva o dado completo pré-existente
            }
          }
          localCache = Map.from(incoming);
        }

        // Tentar atualizar com dado parcial (lightweight)
        updateLocalCache(partialTransactionData, isLightweight: true);

        // O cache deve ter mantido a descrição completa
        expect(localCache?['descricao'], equals('Supermercado Completo'));
      });
    });
  });
}
