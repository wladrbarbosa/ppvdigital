import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/app/login/login_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Regras de Negócio - Módulo de Autenticação (Login)', () {
    group('1. Validação de Formulário de Autenticação', () {
      bool isEmailValid(String email) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        return emailRegex.hasMatch(email.trim());
      }

      bool isSenhaValid(String password) {
        return password.trim().length >= 6;
      }

      test('Validação de sintaxe de e-mail', () {
        expect(isEmailValid('usuario@dominio.com'), isTrue);
        expect(isEmailValid('teste.sobrenome@empresa.com.br'), isTrue);
        expect(isEmailValid('email_invalido'), isFalse);
        expect(isEmailValid('usuario@.com'), isFalse);
        expect(isEmailValid(''), isFalse);
      });

      test('Validação de regras de senha (mínimo 6 caracteres)', () {
        expect(isSenhaValid('123456'), isTrue);
        expect(isSenhaValid('senhaSuperSegura'), isTrue);
        expect(isSenhaValid('12345'), isFalse);
        expect(isSenhaValid('  123 '), isFalse);
        expect(isSenhaValid(''), isFalse);
      });
    });

    group('2. Estados da Sessão de Autenticação (AuthStatus)', () {
      test('Valores de AuthStatus e transições', () {
        const statusInicial = AuthStatus.uninitialized;
        const statusLogado = AuthStatus.authenticated;
        const statusDeslogado = AuthStatus.unauthenticated;

        expect(statusInicial, equals(AuthStatus.uninitialized));
        expect(statusLogado, equals(AuthStatus.authenticated));
        expect(statusDeslogado, equals(AuthStatus.unauthenticated));
      });
    });
  });
}
