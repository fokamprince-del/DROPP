import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provisoire : à brancher sur le vrai panier quand ce module existe.
final nombreArticlesPanierProvider = Provider<int>((ref) => 1);

/// Provisoire : à brancher sur la messagerie (conversations non lues).
final nombreMessagesNonLusProvider = Provider<int>((ref) => 5);
