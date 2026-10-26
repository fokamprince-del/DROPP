import 'package:flutter/foundation.dart';

/// Ce que l'utilisateur connecté a aimé, mis en favori ou suivi, plus les
/// compteurs modifiés depuis l'ouverture de l'app (ils priment sur ceux
/// reçus avec les publications, déjà en cache dans les listes).
@immutable
class EtatsInteractions {
  const EtatsInteractions({
    this.likesPublications = const {},
    this.likesCommentaires = const {},
    this.favorisPublications = const {},
    this.favorisProduits = const {},
    this.abonnements = const {},
    this.likesParPublication = const {},
    this.likesParCommentaire = const {},
    this.abonnesParBoutique = const {},
    this.commentairesAjoutes = const {},
  });

  final Set<String> likesPublications;
  final Set<String> likesCommentaires;
  final Set<String> favorisPublications;
  final Set<String> favorisProduits;

  /// Identifiants des boutiques suivies (= identifiants des vendeurs).
  final Set<String> abonnements;

  final Map<String, int> likesParPublication;
  final Map<String, int> likesParCommentaire;
  final Map<String, int> abonnesParBoutique;

  /// Commentaires publiés ou supprimés ici, par publication (+1 / -1).
  final Map<String, int> commentairesAjoutes;

  int likesPublication(String id, int recu) => likesParPublication[id] ?? recu;
  int likesCommentaire(String id, int recu) => likesParCommentaire[id] ?? recu;
  int abonnes(String boutiqueId, int recu) =>
      abonnesParBoutique[boutiqueId] ?? recu;
  int commentaires(String publicationId, int recu) =>
      recu + (commentairesAjoutes[publicationId] ?? 0);

  EtatsInteractions copyWith({
    Set<String>? likesPublications,
    Set<String>? likesCommentaires,
    Set<String>? favorisPublications,
    Set<String>? favorisProduits,
    Set<String>? abonnements,
    Map<String, int>? likesParPublication,
    Map<String, int>? likesParCommentaire,
    Map<String, int>? abonnesParBoutique,
    Map<String, int>? commentairesAjoutes,
  }) => EtatsInteractions(
    likesPublications: likesPublications ?? this.likesPublications,
    likesCommentaires: likesCommentaires ?? this.likesCommentaires,
    favorisPublications: favorisPublications ?? this.favorisPublications,
    favorisProduits: favorisProduits ?? this.favorisProduits,
    abonnements: abonnements ?? this.abonnements,
    likesParPublication: likesParPublication ?? this.likesParPublication,
    likesParCommentaire: likesParCommentaire ?? this.likesParCommentaire,
    abonnesParBoutique: abonnesParBoutique ?? this.abonnesParBoutique,
    commentairesAjoutes: commentairesAjoutes ?? this.commentairesAjoutes,
  );

  /// Réponse de `GET /moi/etats`.
  factory EtatsInteractions.fromJson(Map<String, dynamic> json) {
    Set<String> ids(String cle) =>
        (json[cle] as List<dynamic>? ?? const []).cast<String>().toSet();
    return EtatsInteractions(
      likesPublications: ids('likesPublications'),
      likesCommentaires: ids('likesCommentaires'),
      favorisPublications: ids('favorisPublications'),
      favorisProduits: ids('favorisProduits'),
      abonnements: ids('abonnements'),
    );
  }
}

/// Copie de [ensemble] avec [id] ajouté (`present`) ou retiré.
Set<String> avecOuSans(
  Set<String> ensemble,
  String id, {
  required bool present,
}) => present ? {...ensemble, id} : ({...ensemble}..remove(id));
