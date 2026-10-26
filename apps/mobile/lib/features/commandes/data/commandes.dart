import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagination.dart';
import '../../../shared/modeles/contenu.dart';

/// Délai pour payer une commande avant son annulation automatique (stock
/// rendu). Doit suivre `COMMANDE_DELAI_PAIEMENT_MINUTES` de l'API, qui ne
/// renvoie pas l'échéance (30 min par défaut).
const delaiPaiementCommande = Duration(minutes: 30);

/// Statuts d'une commande et de ses sous-commandes (une par boutique).
enum StatutCommande {
  enAttentePaiement('EN_ATTENTE_PAIEMENT'),
  nouvelle('NOUVELLE'),
  enCours('EN_COURS'),
  expediee('EXPEDIEE'),
  livree('LIVREE'),
  annulee('ANNULEE'),
  enLitige('EN_LITIGE');

  const StatutCommande(this.valeur);
  final String valeur;

  static StatutCommande depuis(Object? valeur) => StatutCommande.values
      .firstWhere((s) => s.valeur == valeur, orElse: () => nouvelle);
}

/// Article commandé, figé au moment de la commande (nom, variante, prix).
class LigneCommande {
  const LigneCommande({
    required this.id,
    required this.nom,
    required this.quantite,
    required this.prixUnitaire,
    this.produitId,
    this.variante,
  });

  final String id;

  /// `null` si le produit a été supprimé depuis.
  final String? produitId;
  final String nom;
  final int quantite;
  final num prixUnitaire;

  /// « M · Rouge » (attributs) ou nom de la variante.
  final String? variante;

  num get total => prixUnitaire * quantite;

  factory LigneCommande.fromJson(Map<String, dynamic> json) => LigneCommande(
    id: json['id'] as String,
    produitId: json['produitId'] as String?,
    nom: json['nomProduitSnapshot'] as String? ?? '',
    quantite: (json['quantite'] as num).toInt(),
    prixUnitaire: lireMontant(json['prixUnitaire']),
    variante: descriptionVariante(json['varianteSnapshot']),
  );
}

/// `{ nom, attributs: {taille: M} }` → « M », ou le nom, ou `null`.
String? descriptionVariante(Object? instantane) {
  if (instantane is! Map) return null;
  final attributs = instantane['attributs'];
  if (attributs is Map && attributs.isNotEmpty) {
    return attributs.values.whereType<String>().join(' · ');
  }
  final nom = instantane['nom'];
  return nom is String && nom.trim().isNotEmpty ? nom : null;
}

/// Part d'une commande chez une boutique.
class SousCommande {
  const SousCommande({
    required this.id,
    required this.boutiqueId,
    required this.statut,
    required this.montantTotal,
    required this.lignes,
    this.boutiqueNom,
  });

  final String id;

  /// Identifiant du vendeur, égal à celui de sa boutique.
  final String boutiqueId;
  final String? boutiqueNom;
  final StatutCommande statut;
  final num montantTotal;
  final List<LigneCommande> lignes;

  factory SousCommande.fromJson(Map<String, dynamic> json) => SousCommande(
    id: json['id'] as String,
    boutiqueId: json['vendeurId'] as String,
    boutiqueNom: json['boutiqueNom'] as String?,
    statut: StatutCommande.depuis(json['statut']),
    montantTotal: lireMontant(json['montantTotal']),
    lignes: (json['lignes'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(LigneCommande.fromJson)
        .toList(),
  );
}

class Commande {
  const Commande({
    required this.id,
    required this.statut,
    required this.montantTotal,
    required this.dateCreation,
    required this.sousCommandes,
  });

  final String id;
  final StatutCommande statut;
  final num montantTotal;
  final DateTime dateCreation;
  final List<SousCommande> sousCommandes;

  int get nombreArticles => sousCommandes.fold(
    0,
    (s, sc) => s + sc.lignes.fold(0, (t, l) => t + l.quantite),
  );

  /// Échéance estimée du paiement (voir [delaiPaiementCommande]).
  DateTime get echeancePaiement => dateCreation.add(delaiPaiementCommande);

  bool get annulable => statut == StatutCommande.enAttentePaiement;

  factory Commande.fromJson(Map<String, dynamic> json) => Commande(
    id: json['id'] as String,
    statut: StatutCommande.depuis(json['statut']),
    montantTotal: lireMontant(json['montantTotal']),
    dateCreation: dateDepuis(json['dateCreation']),
    sousCommandes: (json['sousCommandes'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(SousCommande.fromJson)
        .toList(),
  );
}

final commandesRepositoryProvider = Provider<CommandesRepository>(
  (ref) => CommandesRepository(ref.watch(apiClientProvider)),
);

/// Commandes du client (profil client et téléphone vérifié). Le paiement et
/// la livraison ne sont pas encore branchés côté serveur : une commande
/// reste « en attente de paiement » puis est annulée automatiquement après
/// [delaiPaiementCommande]. Toute erreur est une `ApiException`.
class CommandesRepository {
  CommandesRepository(this._api);

  final ApiClient _api;

  /// `POST /commandes` (sans corps) : transforme **tout le panier** en
  /// commande, réserve le stock et vide le panier. 400 si le panier est
  /// vide ou a changé (produit plus en vente, stock insuffisant) : relire le
  /// panier.
  Future<Commande> passer() async =>
      Commande.fromJson(await _api.post<Map<String, dynamic>>('/commandes'));

  /// `GET /commandes` : les plus récentes d'abord, 20 par page.
  Future<PageResultats<Commande>> lister(int page) =>
      _api.page('/commandes', Commande.fromJson, page: page);

  /// `GET /commandes/:id` : 404 si elle n'appartient pas à l'utilisateur.
  Future<Commande> obtenir(String id) async =>
      Commande.fromJson(await _api.get<Map<String, dynamic>>('/commandes/$id'));

  /// `POST /commandes/:id/annuler` : seulement en attente de paiement
  /// (409 sinon) ; le stock est rendu.
  Future<Commande> annuler(String id) async => Commande.fromJson(
    await _api.post<Map<String, dynamic>>('/commandes/$id/annuler'),
  );
}
