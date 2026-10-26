import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_exception.dart';
import 'package:dropp/core/upload/choix_media.dart';
import 'package:dropp/core/upload/service_upload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

/// Faux R2 : mémorise la requête reçue et répond [statut].
class _FauxR2 implements HttpClientAdapter {
  _FauxR2({this.statut = 200});

  final int statut;
  RequestOptions? requete;
  int octetsRecus = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requete = options;
    await for (final morceau in requestStream!) {
      octetsRecus += morceau.length;
    }
    return ResponseBody.fromString('', statut);
  }

  @override
  void close({bool force = false}) {}
}

FichierLocal _photo(int taille) => FichierLocal(
  fichier: XFile.fromData(Uint8List(taille), name: 'photo.jpg'),
  typeMime: 'image/jpeg',
  taille: taille,
  largeur: 800,
  hauteur: 600,
);

const _signature = SignatureUpload(
  uploadUrl: 'https://r2.exemple/bucket/conversations/c1/u1/abc.jpg?X-Amz=1',
  cleStockage: 'conversations/c1/u1/abc.jpg',
  enTetes: {'Content-Type': 'image/jpeg'},
);

void main() {
  test('envoie le fichier vers l’URL signée, avec les en-têtes signés et '
      'sans le jeton de l’API', () async {
    final r2 = _FauxR2();
    final service = ServiceUpload(Dio()..httpClientAdapter = r2);
    final demandes = <String>[];
    final progressions = <double>[];

    final envoye = await service.televerser(
      _photo(4096),
      demanderSignature: (type, taille) async {
        demandes.add('$type $taille');
        return _signature;
      },
      surProgression: progressions.add,
    );

    expect(demandes, ['image/jpeg 4096']);
    expect(r2.requete!.method, 'PUT');
    expect(r2.requete!.uri.toString(), _signature.uploadUrl);
    expect(r2.requete!.headers['Content-Type'], 'image/jpeg');
    expect(r2.requete!.headers.containsKey('Authorization'), isFalse);
    expect(r2.octetsRecus, 4096);
    expect(progressions.last, 1);
    expect(envoye.toJson(), {
      'cleStockage': 'conversations/c1/u1/abc.jpg',
      'typeMime': 'image/jpeg',
      'taille': 4096,
      'largeur': 800,
      'hauteur': 600,
    });
  });

  test('envoyer() enchaîne signature, envoi et confirmation', () async {
    final service = ServiceUpload(Dio()..httpClientAdapter = _FauxR2());
    final resultat = await service.envoyer(
      _photo(10),
      demanderSignature: (_, _) async => _signature,
      confirmer: (envoye) async => 'confirmé ${envoye.cleStockage}',
    );
    expect(resultat, 'confirmé conversations/c1/u1/abc.jpg');
  });

  test('un refus de R2 (URL expirée) devient une ApiException', () async {
    final service = ServiceUpload(
      Dio()..httpClientAdapter = _FauxR2(statut: 403),
    );
    await expectLater(
      service.televerser(
        _photo(10),
        demanderSignature: (_, _) async => _signature,
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.type,
          'type',
          TypeErreurApi.interdit,
        ),
      ),
    );
  });

  test('lit la signature renvoyée par l’API', () {
    final s = SignatureUpload.fromJson({
      'uploadUrl': 'https://u',
      'cleStockage': 'c',
      'expireA': '2026-10-26T10:10:00.000Z',
      'enTetes': {'Content-Type': 'video/mp4'},
    });
    expect(s.enTetes, {'Content-Type': 'video/mp4'});
  });

  test('types acceptés par extension', () {
    expect(typeMimeDe('IMG_001.JPG'), 'image/jpeg');
    expect(typeMimeDe('a.webp'), 'image/webp');
    expect(typeMimeDe('clip.mov'), 'video/quicktime');
    expect(typeMimeDe('doc.pdf'), isNull);
    expect(typeMimeDe('sans_extension'), isNull);
  });
}
