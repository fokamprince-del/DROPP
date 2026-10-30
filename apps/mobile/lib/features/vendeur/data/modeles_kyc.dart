/// Plafond de l'API pour un document.
const tailleMaxDocumentKyc = 10 ;

enum TypeDocumentKyc {
  cniRecto('CNI_RECTO'),
  cniVerso('CNI_VERSO'),
  photoFaciale('PHOTO_FACIALE');

  const TypeDocumentKyc(this.valeurApi);

  final String valeurApi;

  static TypeDocumentKyc? depuisApi(String? valeur) {
    for (final type in values) {
      if (type.valeurApi == valeur) return type;
    }
    return null;
  }
}

enum StatutDossierKyc {
  enAttente('EN_ATTENTE'),
  enCoursVerification('EN_COURS_VERIFICATION'),
  enAttenteRevueAdmin('EN_ATTENTE_REVUE_ADMIN'),
  valide('VALIDE'),
  rejete('REJETE'),
  inconnu('');

  const StatutDossierKyc(this.valeurApi);

  final String valeurApi;

  static StatutDossierKyc depuisApi(String? valeur) =>
      values.firstWhere((s) => s.valeurApi == valeur, orElse: () => inconnu);

  /// Dossier soumis, en cours d'examen.
  bool get enVerification =>
      this == enCoursVerification || this == enAttenteRevueAdmin;
}

class DocumentKyc {
  const DocumentKyc({
    required this.id,
    required this.type,
    required this.statut,
  });

  final String id;
  final TypeDocumentKyc type;

  /// `SOUMIS`, `VALIDE` ou `REJETE`.
  final String statut;

  bool get refuse => statut == 'REJETE';

  /// `null` pour un type de document que l'app ne connaît pas.
  static DocumentKyc? fromJson(Map<String, dynamic> json) {
    final type = TypeDocumentKyc.depuisApi(json['typeDocument'] as String?);
    final id = json['id'];
    if (type == null || id is! String) return null;
    return DocumentKyc(
      id: id,
      type: type,
      statut: json['statut'] as String? ?? 'SOUMIS',
    );
  }
}

/// Une date de naissance n'a pas de fuseau : on ne garde que le jour, en UTC.
DateTime? lireJour(Object? valeur) {
  if (valeur is! String) return null;
  final date = DateTime.tryParse(valeur);
  if (date == null) return null;
  return DateTime.utc(date.year, date.month, date.day);
}

/// Format `date-time` attendu par l'API : minuit UTC.
String jourVersApi(DateTime jour) =>
    DateTime.utc(jour.year, jour.month, jour.day).toIso8601String();

/// Lettres et chiffres uniquement, en majuscules (`^[A-Z0-9]{6,20}$`).
String normaliserNumeroCni(String saisie) =>
    saisie.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

bool numeroCniValide(String numero) =>
    RegExp(r'^[A-Z0-9]{6,20}$').hasMatch(numero);

class DonneesCni {
  const DonneesCni({
    this.nomLegal,
    this.prenomLegal,
    this.numeroCni,
    this.dateNaissance,
    this.lieuNaissance,
    this.dateEtablissement,
    this.dateExpiration,
  });

  factory DonneesCni.depuisJson(Map<String, dynamic> json) => DonneesCni(
    nomLegal: json['nomLegal'] as String?,
    prenomLegal: json['prenomLegal'] as String?,
    numeroCni: json['numeroCni'] as String?,
    dateNaissance: lireJour(json['dateNaissance']),
    lieuNaissance: json['lieuNaissance'] as String?,
    dateEtablissement: lireJour(json['dateEtablissement']),
    dateExpiration: lireJour(json['dateExpiration']),
  );

  final String? nomLegal;
  final String? prenomLegal;
  final String? numeroCni;
  final DateTime? dateNaissance;
  final String? lieuNaissance;
  final DateTime? dateEtablissement;
  final DateTime? dateExpiration;

  static bool _rempli(String? texte) =>
      texte != null && texte.trim().isNotEmpty;

  bool get complet =>
      _rempli(nomLegal) &&
      _rempli(prenomLegal) &&
      _rempli(numeroCni) &&
      _rempli(lieuNaissance) &&
      dateNaissance != null &&
      dateEtablissement != null &&
      dateExpiration != null;

  /// Corps de `POST /kyc/cni/confirmer` : tous les champs sont obligatoires.
  Map<String, dynamic> versJsonConfirmation() {
    if (!complet) throw StateError('Données de CNI incomplètes.');
    return {
      'nomLegal': nomLegal!.trim(),
      'prenomLegal': prenomLegal!.trim(),
      'numeroCni': normaliserNumeroCni(numeroCni!),
      'dateNaissance': jourVersApi(dateNaissance!),
      'lieuNaissance': lieuNaissance!.trim(),
      'dateEtablissement': jourVersApi(dateEtablissement!),
      'dateExpiration': jourVersApi(dateExpiration!),
    };
  }
}

class ResultatExtractionCni {
  const ResultatExtractionCni({
    required this.donnees,
    this.confiance,
    this.avertissement,
  });

  factory ResultatExtractionCni.depuisJson(Map<String, dynamic> json) {
    final brut = json['donnees'];
    final donnees = brut is Map<String, dynamic> ? brut : <String, dynamic>{};
    final confiance = donnees['confidence'];
    return ResultatExtractionCni(
      donnees: DonneesCni.depuisJson(donnees),
      confiance: confiance is num ? confiance.toDouble() : null,
      avertissement: json['avertissement'] as String?,
    );
  }

  final DonneesCni donnees;

  /// De 0 à 100.
  final double? confiance;
  final String? avertissement;
}

class DossierKyc {
  const DossierKyc({
    required this.id,
    required this.statut,
    required this.documents,
    this.motifRejet,
    this.donnees = const DonneesCni(),
    this.consentementLe,
  });

  factory DossierKyc.depuisJson(Map<String, dynamic> json) {
    final brut = json['documents'];
    return DossierKyc(
      id: json['id'] as String? ?? '',
      statut: StatutDossierKyc.depuisApi(json['statut'] as String?),
      motifRejet: json['motifRejet'] as String?,
      donnees: DonneesCni.depuisJson(json),
      consentementLe: DateTime.tryParse(
        json['consentementLe'] as String? ?? '',
      ),
      documents: [
        if (brut is List<dynamic>)
          for (final d in brut)
            if (d is Map<String, dynamic>) ?DocumentKyc.fromJson(d),
      ],
    );
  }

  final String id;
  final StatutDossierKyc statut;
  final List<DocumentKyc> documents;
  final String? motifRejet;
  final DonneesCni donnees;
  final DateTime? consentementLe;

  DocumentKyc? document(TypeDocumentKyc type) {
    for (final doc in documents) {
      if (doc.type == type) return doc;
    }
    return null;
  }

  bool get documentsComplets =>
      TypeDocumentKyc.values.every((t) => document(t) != null);
}
