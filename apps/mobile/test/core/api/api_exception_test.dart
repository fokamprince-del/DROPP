import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/api_exception.dart';
import 'package:mobile/core/api/pagination.dart';

DioException _reponse(int statut, Object? corps) {
  final requete = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requete,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: requete, statusCode: statut, data: corps),
  );
}

void main() {
  group('ApiException.depuis', () {
    test('reprend le message texte de l\'API', () {
      final e = ApiException.depuis(
        _reponse(409, {'statusCode': 409, 'message': 'Ce pseudo est déjà pris.'}),
      );
      expect(e.type, TypeErreurApi.conflit);
      expect(e.statusCode, 409);
      expect(e.message, 'Ce pseudo est déjà pris.');
    });

    test('garde toutes les erreurs de validation', () {
      final e = ApiException.depuis(_reponse(400, {
        'statusCode': 400,
        'message': ['prenom ne doit pas être vide', 'motDePasse trop court'],
      }));
      expect(e.type, TypeErreurApi.requeteInvalide);
      expect(e.message, 'prenom ne doit pas être vide');
      expect(e.details, hasLength(2));
    });

    test('traduit le 429 du throttler', () {
      final e = ApiException.depuis(
        _reponse(429, {'statusCode': 429, 'message': 'ThrottlerException: Too Many Requests'}),
      );
      expect(e.type, TypeErreurApi.tropDeRequetes);
      expect(e.message, contains('Trop de tentatives'));
    });

    test('n\'affiche pas le détail d\'une erreur serveur', () {
      final e = ApiException.depuis(_reponse(500, {'message': 'Erreur interne.'}));
      expect(e.type, TypeErreurApi.serveur);
      expect(e.message, isNot(contains('interne')));
    });

    test('distingue l\'absence de réseau', () {
      final e = ApiException.depuis(DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      ));
      expect(e.type, TypeErreurApi.reseau);
    });
  });

  test('PageResultats lit donnees + pagination et garde les champs en plus', () {
    final page = PageResultats.fromJson(
      {
        'donnees': [
          {'id': 'a'},
          {'id': 'b'},
        ],
        'nonLues': 3,
        'pagination': {'total': 25, 'page': 1, 'limite': 2, 'pages': 13},
      },
      (json) => json['id'] as String,
    );
    expect(page.donnees, ['a', 'b']);
    expect(page.pagination.aSuivante, isTrue);
    expect(page.brut['nonLues'], 3);
  });
}
