import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/environnement.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Environnement.verifier();
  debugPrint('API_URL = ${Environnement.apiUrl}');
  runApp(const ProviderScope(child: DroppApp()));
}
