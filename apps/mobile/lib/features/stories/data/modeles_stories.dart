import '../../../shared/modeles/contenu.dart';

class Story {
  const Story({
    required this.id,
    required this.boutique,
    required this.media,
    required this.dateCreation,
    this.vue = false,
  });

  final String id;
  final BoutiqueResume boutique;
  final MediaContenu media;
  final DateTime dateCreation;

  /// Connu du serveur pour les boutiques suivies seulement.
  final bool vue;

  Story copierVue() => Story(
    id: id,
    boutique: boutique,
    media: media,
    dateCreation: dateCreation,
    vue: true,
  );

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: json['id'] as String,
    boutique: BoutiqueResume.fromJson(json['boutique'] as Map<String, dynamic>),
    media: MediaContenu.fromJson(json['media'] as Map<String, dynamic>),
    dateCreation: dateDepuis(json['dateCreation']),
    vue: json['vue'] as bool? ?? false,
  );
}

/// Les stories d'une boutique, de la plus ancienne à la plus récente.
class GroupeStories {
  const GroupeStories({required this.boutique, required this.stories});

  final BoutiqueResume boutique;
  final List<Story> stories;

  bool get toutesVues => stories.every((s) => s.vue);

  /// Où reprendre la lecture : la première non vue, sinon le début.
  int get premiereNonVue {
    final i = stories.indexWhere((s) => !s.vue);
    return i < 0 ? 0 : i;
  }

  factory GroupeStories.fromJson(Map<String, dynamic> json) => GroupeStories(
    boutique: BoutiqueResume.fromJson(json['boutique'] as Map<String, dynamic>),
    stories: (json['stories'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Story.fromJson)
        .toList(),
  );
}
