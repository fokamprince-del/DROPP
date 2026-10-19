/// Bloc `pagination` renvoyé par toutes les listes paginées de l'API.
class Pagination {
  const Pagination({
    required this.total,
    required this.page,
    required this.limite,
    required this.pages,
  });

  final int total;
  final int page;
  final int limite;
  final int pages;

  bool get aSuivante => page < pages;

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        total: (json['total'] as num).toInt(),
        page: (json['page'] as num).toInt(),
        limite: (json['limite'] as num).toInt(),
        pages: (json['pages'] as num).toInt(),
      );
}

/// Une page de résultats : `{ donnees: [...], pagination: {...} }`.
///
/// Certaines routes ajoutent des champs à côté (`nonLues` pour les
/// notifications, `resume` pour les avis) : ils restent lisibles dans [brut].
class PageResultats<T> {
  const PageResultats({
    required this.donnees,
    required this.pagination,
    this.brut = const {},
  });

  final List<T> donnees;
  final Pagination pagination;
  final Map<String, dynamic> brut;

  factory PageResultats.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) depuisJson,
  ) =>
      PageResultats(
        donnees: (json['donnees'] as List)
            .map((e) => depuisJson(e as Map<String, dynamic>))
            .toList(),
        pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
        brut: json,
      );
}
