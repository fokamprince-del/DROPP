import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/upload/choix_media.dart';
import '../../../../shared/theme/couleurs.dart';
import '../../../../shared/theme/espacements.dart';
import '../../data/modeles_kyc.dart';

enum _EtatCamera { chargement, pret, refusee, avantIndisponible, erreur }

/// Caméra AVANT uniquement, avec un guide ovale. Renvoie la photo en mémoire
/// (`Navigator.pop`) ou `null` si l'utilisateur ferme l'écran.
class PageCameraSelfie extends StatefulWidget {
  const PageCameraSelfie({super.key});

  @override
  State<PageCameraSelfie> createState() => _PageCameraSelfieState();
}

class _PageCameraSelfieState extends State<PageCameraSelfie>
    with WidgetsBindingObserver {
  CameraController? _controleur;
  _EtatCamera _etat = _EtatCamera.chargement;
  bool _prise = false;
  bool _suspendue = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialiser());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controleur?.dispose());
    super.dispose();
  }

  /// Libère la caméra quand l'app passe en arrière-plan et la rouvre au
  /// retour (le paquet laisse ce travail à l'application).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final controleur = _controleur;
      // Pas pendant l'initialisation (par ex. la demande d'autorisation).
      if (controleur == null || !controleur.value.isInitialized) return;
      _controleur = null;
      _suspendue = true;
      unawaited(controleur.dispose());
      if (mounted) setState(() => _etat = _EtatCamera.chargement);
    } else if (state == AppLifecycleState.resumed && _suspendue) {
      _suspendue = false;
      unawaited(_initialiser());
    }
  }

  void _maj(_EtatCamera etat) {
    if (mounted) setState(() => _etat = etat);
  }

  Future<void> _initialiser() async {
    try {
      final cameras = await availableCameras();
      CameraDescription? avant;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          avant = camera;
          break;
        }
      }
      if (avant == null) return _maj(_EtatCamera.avantIndisponible);

      final controleur = CameraController(
        avant,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _controleur = controleur;
      await controleur.initialize();
      await controleur.lockCaptureOrientation(DeviceOrientation.portraitUp);
      _maj(_EtatCamera.pret);
    } on CameraException catch (e) {
      const refus = {
        'CameraAccessDenied',
        'CameraAccessDeniedWithoutPrompt',
        'CameraAccessRestricted',
      };
      _maj(refus.contains(e.code) ? _EtatCamera.refusee : _EtatCamera.erreur);
    }
  }

  Future<void> _prendre() async {
    final controleur = _controleur;
    if (controleur == null ||
        !controleur.value.isInitialized ||
        controleur.value.isTakingPicture ||
        _prise) {
      return;
    }
    setState(() => _prise = true);
    try {
      final photo = await controleur.takePicture();
      final fichier = await preparerFichier(
        photo,
        tailleMaxImageMo: tailleMaxDocumentKyc,
      );
      if (!mounted) return;
      Navigator.of(context).pop(fichier);
    } on CameraException {
      if (mounted) {
        setState(() {
          _prise = false;
          _etat = _EtatCamera.erreur;
        });
      }
    }
  }

  Widget _message(String texte, {VoidCallback? action, String? libelleAction}) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Espacements.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 56,
              color: Colors.white70,
            ),
            const SizedBox(height: Espacements.l),
            Text(
              texte,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
            if (action != null) ...[
              const SizedBox(height: Espacements.l),
              FilledButton(onPressed: action, child: Text(libelleAction!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _apercu() {
    final l10n = context.l10n;
    final controleur = _controleur!;
    return Column(
      children: [
        const SizedBox(height: Espacements.xxl),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1 / controleur.value.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controleur),
                  const ExcludeSemantics(
                    child: CustomPaint(painter: _PeintreGuideVisage()),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Espacements.xl,
            vertical: Espacements.l,
          ),
          child: Text(
            l10n.kycCameraGuide,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: Colors.white),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: Espacements.xl),
          child: _Declencheur(
            libelle: l10n.kycPrendreSelfie,
            actif: !_prise,
            surAppui: _prendre,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Widget contenu = switch (_etat) {
      _EtatCamera.chargement => const Center(
        child: CircularProgressIndicator(),
      ),
      _EtatCamera.pret => _apercu(),
      _EtatCamera.refusee => _message(l10n.kycCameraRefusee),
      _EtatCamera.avantIndisponible => _message(
        l10n.kycCameraAvantIndisponible,
      ),
      _EtatCamera.erreur => _message(
        l10n.kycCameraErreur,
        action: () {
          setState(() {
            _prise = false;
            _etat = _EtatCamera.chargement;
          });
          unawaited(_initialiser());
        },
        libelleAction: l10n.reessayer,
      ),
    };

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: contenu),
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                color: Colors.white,
                tooltip: l10n.kycFermer,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Declencheur extends StatelessWidget {
  const _Declencheur({
    required this.libelle,
    required this.actif,
    required this.surAppui,
  });

  final String libelle;
  final bool actif;
  final VoidCallback surAppui;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: actif,
      label: libelle,
      child: GestureDetector(
        onTap: actif ? surAppui : null,
        child: Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: actif ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }
}

/// Voile sombre percé d'un ovale pour cadrer le visage.
class _PeintreGuideVisage extends CustomPainter {
  const _PeintreGuideVisage();

  @override
  void paint(Canvas canvas, Size size) {
    final largeur = size.width * 0.72;
    final ovale = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: largeur,
      height: largeur * 1.3,
    );
    final voile = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addOval(ovale),
    );
    canvas
      ..drawPath(voile, Paint()..color = Colors.black54)
      ..drawOval(
        ovale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Couleurs.hibiscusVif,
      );
  }

  @override
  bool shouldRepaint(_PeintreGuideVisage ancien) => false;
}
