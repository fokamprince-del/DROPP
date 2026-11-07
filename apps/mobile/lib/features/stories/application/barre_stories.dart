import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/session.dart';
import '../data/modeles_stories.dart';
import '../data/stories_repository.dart';

final barreStoriesProvider =
    AsyncNotifierProvider<BarreStoriesNotifier, List<GroupeStories>>(
      BarreStoriesNotifier.new,
    );

/// Stories de la barre du fil, une entrée par boutique.
class BarreStoriesNotifier extends AsyncNotifier<List<GroupeStories>> {
  /// Vues pendant ce lancement : le serveur ne les connaît pas pour un
  /// visiteur ni pour les boutiques non suivies.
  final _vuesLocales = <String>{};

  @override
  Future<List<GroupeStories>> build() async {
    final connecte = ref.watch(utilisateurConnecteProvider) != null;
    final depot = ref.watch(storiesRepositoryProvider);

    final suivies = connecte
        ? await depot.abonnements()
        : const <GroupeStories>[];
    var publiques = const <Story>[];
    try {
      publiques = (await depot.publiques()).donnees;
    } on ApiException {
      // Sans les stories publiques, celles des abonnements suffisent.
      if (suivies.isEmpty) rethrow;
    }
    return composerBarre(suivies, publiques, vuesLocales: _vuesLocales);
  }

  /// Grise l'anneau tout de suite ; prévient le serveur si on est connecté.
  Future<void> marquerVue(String storyId) async {
    if (!_vuesLocales.add(storyId)) return;
    final actuel = state.value;
    if (actuel != null) state = AsyncData(appliquerVues(actuel, {storyId}));

    if (ref.read(utilisateurConnecteProvider) == null) return;
    try {
      await ref.read(storiesRepositoryProvider).marquerVue(storyId);
    } on ApiException {
      // Sans gravité : la story réapparaîtra comme non vue au prochain
      // chargement.
    }
  }
}

/// Boutiques suivies d'abord (ordre du serveur), puis les autres boutiques
/// ayant des stories publiques. Dans chaque partie, les boutiques avec des
/// stories non vues passent devant.
List<GroupeStories> composerBarre(
  List<GroupeStories> suivies,
  List<Story> publiques, {
  Set<String> vuesLocales = const {},
}) {
  final dejaPresentes = {for (final g in suivies) g.boutique.id};
  final parBoutique = <String, List<Story>>{};
  for (final story in publiques) {
    if (dejaPresentes.contains(story.boutique.id)) continue;
    parBoutique.putIfAbsent(story.boutique.id, () => []).add(story);
  }
  final autres = [
    for (final stories in parBoutique.values)
      GroupeStories(
        boutique: stories.first.boutique,
        stories: stories
          ..sort((a, b) => a.dateCreation.compareTo(b.dateCreation)),
      ),
  ];

  List<GroupeStories> nonVuesDabord(List<GroupeStories> groupes) {
    final marques = appliquerVues(groupes, vuesLocales);
    return [
      ...marques.where((g) => !g.toutesVues),
      ...marques.where((g) => g.toutesVues),
    ];
  }

  return [...nonVuesDabord(suivies), ...nonVuesDabord(autres)];
}

List<GroupeStories> appliquerVues(
  List<GroupeStories> groupes,
  Set<String> vues,
) {
  if (vues.isEmpty) return groupes;
  return [
    for (final g in groupes)
      GroupeStories(
        boutique: g.boutique,
        stories: [
          for (final s in g.stories) vues.contains(s.id) ? s.copierVue() : s,
        ],
      ),
  ];
}
