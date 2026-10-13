import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/image_utils.dart';
import '../models/identity_verification_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/face/face_engine.dart';
import '../services/firestore_service.dart';
import 'identity_camera_screen.dart';
import 'login_screen.dart';

/// Mandatory step after sign-up (email or Google): valid ID + live selfie,
/// like GCash / SIM registration. The LGU admin gives the final approval.
class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  late final FaceEngine _engine = createFaceEngine();
  bool _engineReady = false;

  String? _idType;
  IdentityCaptureResult? _idShot;
  IdentityCaptureResult? _selfieShot;
  bool _consent = false;
  bool _submitting = false;
  int _mismatchAttempts = 0;
  String? _message;

  static const int _maxMismatchBeforeManualReview = 3;

  @override
  void initState() {
    super.initState();
    _engine.init().whenComplete(() {
      if (mounted) setState(() => _engineReady = true);
    });
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  bool get _complete => _idType != null && _idShot != null && _selfieShot != null && _consent;

  Future<void> _capture(IdentityCaptureMode mode) async {
    final result = await Navigator.push<IdentityCaptureResult>(
      context,
      MaterialPageRoute(builder: (_) => IdentityCameraScreen(mode: mode, engine: _engine)),
    );
    if (result == null || !mounted) return;
    setState(() {
      _message = null;
      if (mode == IdentityCaptureMode.idCard) {
        _idShot = result;
      } else {
        _selfieShot = result;
      }
    });
  }

  Future<void> _submit() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null || !_complete) return;

    setState(() {
      _submitting = true;
      _message = null;
    });

    try {
      final id = _idShot!;
      final selfie = _selfieShot!;

      final score = await _engine.matchScore(
        idPath: id.file.path,
        idFace: id.face,
        selfiePath: selfie.file.path,
        selfieFace: selfie.face,
      );

      // Honest mismatches are asked to retake (bad light / glare is the usual
      // cause). After a few tries the submission goes to manual review anyway
      // so a worn-out ID photo can't lock a real resident out.
      if (FaceMatchThresholds.levelOf(score) == FaceMatchLevel.mismatch) {
        _mismatchAttempts++;
        if (_mismatchAttempts < _maxMismatchBeforeManualReview) {
          setState(() {
            _submitting = false;
            _message = 'The selfie does not match the portrait on your ID. Retake both photos in good lighting '
                'with no glare. (Attempt $_mismatchAttempts of $_maxMismatchBeforeManualReview)';
            _idShot = null;
            _selfieShot = null;
          });
          return;
        }
      }

      final idB64 = await ImageUtils.processIdentityPhoto(id.bytes);
      final selfieB64 = await ImageUtils.processIdentityPhoto(selfie.bytes, maxDim: 800);

      if (!mounted) return;
      await Provider.of<FirestoreService>(context, listen: false).submitIdentityVerification(
        IdentityVerificationModel(
          userId: user.uid,
          idType: _idType!,
          idImageBase64: idB64,
          selfieBase64: selfieB64,
          faceMatchScore: score,
          livenessPassed: selfie.livenessPassed,
          faceFoundOnId: id.face.hasFace,
          matchEngine: _engine.canMatch ? 'mobilefacenet-tflite' : 'manual-review',
          submittedAt: DateTime.now(),
        ),
      );
      // AuthWrapper swaps this screen for PendingVerificationScreen once the
      // user document flips to 'pending'.
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _message = 'Submission failed: $e';
        });
      }
    }
  }

  Future<void> _logout() async {
    await Provider.of<AuthService>(context, listen: false).logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Provider.of<UserModel?>(context);
    final rejected = user?.verificationStatus == 'rejected';
    final textColor = isDark ? Colors.white : AppColors.retroDarkBorder;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _submitting ? null : _logout,
                    icon: Icon(Icons.logout_rounded, size: 16, color: textColor),
                    label: Text('LOGOUT', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ],
              ),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.retroLilac,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.retroDarkBorder, width: 2),
                    boxShadow: const [BoxShadow(color: AppColors.retroDarkBorder, offset: Offset(3, 3), blurRadius: 0)],
                  ),
                  child: const Icon(Icons.badge_rounded, color: AppColors.retroDarkBorder, size: 34),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'VERIFY YOUR IDENTITY',
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const SizedBox(height: 6),
              Text(
                'To stop prank and fake reports, every citizen must show a valid ID and a live face scan before using GeoSafe.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),

              if (rejected) _banner('Your last submission was rejected', user!.rejectionReason.isNotEmpty ? user.rejectionReason : 'Please resubmit clearer photos.', isDark),
              if (_message != null) _banner('Please try again', _message!, isDark),
              _engineStatus(isDark),
              const SizedBox(height: 14),

              _stepCard(
                isDark: isDark,
                number: 1,
                title: 'Choose your ID',
                done: _idType != null,
                child: DropdownButtonFormField<String>(
                  value: _idType,
                  isExpanded: true,
                  hint: const Text('Select a government-issued ID'),
                  items: [
                    _idGroupHeader('PRIMARY GOVERNMENT IDs'),
                    ...kPrimaryIdTypes.map(_idItem),
                    _idGroupHeader('OTHER GOVERNMENT IDs WITH PHOTO'),
                    ...kOtherIdTypes.map(_idItem),
                  ],
                  onChanged: _submitting ? null : (v) => setState(() => _idType = v),
                  decoration: _inputDecoration(isDark),
                ),
              ),
              const SizedBox(height: 14),
              _stepCard(
                isDark: isDark,
                number: 2,
                title: 'Scan the front of your ID',
                done: _idShot != null,
                child: _captureTile(
                  isDark: isDark,
                  enabled: _idType != null && _engineReady && !_submitting,
                  shot: _idShot,
                  emptyLabel: _idType == null ? 'Select an ID type first' : 'OPEN CAMERA',
                  caption: _idShot == null
                      ? 'Live camera only. The ID must be valid (not expired) and the photo, name and ID number readable.'
                      : (_idShot!.face.hasFace ? 'Portrait detected on ID' : 'Captured (admin will review the portrait)'),
                  onTap: () => _capture(IdentityCaptureMode.idCard),
                ),
              ),
              const SizedBox(height: 14),
              _stepCard(
                isDark: isDark,
                number: 3,
                title: 'Live face scan',
                done: _selfieShot != null,
                child: _captureTile(
                  isDark: isDark,
                  enabled: _idShot != null && _engineReady && !_submitting,
                  shot: _selfieShot,
                  emptyLabel: _idShot == null ? 'Scan your ID first' : 'START FACE SCAN',
                  caption: _selfieShot == null
                      ? 'You will be asked to look straight, turn your head and close your eyes.'
                      : (_selfieShot!.livenessPassed ? 'Liveness check passed' : 'Captured (admin will review)'),
                  onTap: () => _capture(IdentityCaptureMode.selfieLiveness),
                ),
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                value: _consent,
                onChanged: _submitting ? null : (v) => setState(() => _consent = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.retroMint,
                title: Text(
                  'I confirm the ID is genuine, issued to me, and not expired. I consent to the collection and processing of my ID and facial image solely to verify my identity, '
                  'in accordance with the Data Privacy Act of 2012 (RA 10173). They will be visible only to authorized LGU administrators.',
                  style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF4B5563), fontSize: 11, height: 1.4),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: (_complete && !_submitting) ? _submit : null,
                child: Opacity(
                  opacity: _complete ? 1 : 0.5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.retroMint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.retroDarkBorder, width: 2),
                      boxShadow: const [BoxShadow(color: AppColors.retroDarkBorder, offset: Offset(3, 3), blurRadius: 0)],
                    ),
                    child: Center(
                      child: _submitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text(
                              'SUBMIT FOR VERIFICATION',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- widgets

  DropdownMenuItem<String> _idItem(String t) => DropdownMenuItem(value: t, child: Text(t));

  // Non-selectable section label inside the dropdown.
  DropdownMenuItem<String> _idGroupHeader(String label) => DropdownMenuItem(
        enabled: false,
        value: label,
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF6B7280)),
        ),
      );

  InputDecoration _inputDecoration(bool isDark) => InputDecoration(
        filled: true,
        fillColor: isDark ? const Color(0xFF262C38) : const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.retroMint, width: 2),
        ),
      );

  Widget _stepCard({
    required bool isDark,
    required int number,
    required String title,
    required bool done,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.retroDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withOpacity(0.12),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: done ? AppColors.retroMint : AppColors.retroLilac,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : Text('$number', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.retroDarkBorder)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.retroDarkBorder,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _captureTile({
    required bool isDark,
    required bool enabled,
    required IdentityCaptureResult? shot,
    required String emptyLabel,
    required String caption,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shot != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(shot.bytes, height: 150, width: double.infinity, fit: BoxFit.cover),
          ),
        if (shot != null) const SizedBox(height: 8),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.retroPeach,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.retroDarkBorder, width: 1.6),
                boxShadow: const [BoxShadow(color: AppColors.retroDarkBorder, offset: Offset(2, 2), blurRadius: 0)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_camera_rounded, size: 16, color: AppColors.retroDarkBorder),
                  const SizedBox(width: 8),
                  Text(
                    shot == null ? emptyLabel : 'RETAKE',
                    style: const TextStyle(color: AppColors.retroDarkBorder, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(caption, style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF6B7280), fontSize: 11)),
      ],
    );
  }

  Widget _banner(String title, String body, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.retroDarkBorder, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.6)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: Color(0xFF7F1D1D), fontSize: 12, height: 1.35)),
        ],
      ),
    );
  }

  Widget _engineStatus(bool isDark) {
    final String label;
    final IconData icon;
    if (!_engineReady) {
      label = 'Preparing face scanner…';
      icon = Icons.hourglass_top_rounded;
    } else if (_engine.canMatch) {
      label = 'On-device face matching active';
      icon = Icons.verified_user_rounded;
    } else if (_engine.canDetect) {
      label = 'Liveness check active. Face comparison done by LGU admin';
      icon = Icons.face_retouching_natural_rounded;
    } else {
      label = 'Photos will be reviewed by the LGU admin';
      icon = Icons.visibility_rounded;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: AppColors.retroMint),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
