import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/page_configuration_invalide.dart';
import 'core/config/environnement.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Environnement.verifier();
  runApp(const ProviderScope(child: DroppApp()));
}
