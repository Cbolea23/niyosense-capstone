import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_translations.dart';

class EulaModal {
  static const String prefsKey = 'eula_accepted_v1';

  static Future<bool> isAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  static Future<void> setAccepted(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, accepted);
  }

  /// Shows the full End-User License Agreement (EULA) & Data Privacy Notice dialog.
  /// If [requireAcceptance] is true, the user cannot dismiss the dialog without tapping "I Agree".
  static Future<bool> show(
    BuildContext context, {
    bool requireAcceptance = false,
  }) async {
    final bool isTl = AppTranslations.currentLang.value == 'tl';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !requireAcceptance,
      builder: (ctx) => PopScope(
        canPop: !requireAcceptance,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F2E23),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_user_outlined, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTl ? "Kasunduan sa Gumagamit (EULA)" : "End-User License Agreement",
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isTl ? "Data Privacy Act of 2012 (RA 10173)" : "Terms of Use & RA 10173 Privacy Policy",
                      style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 360,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF081C15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: isTl ? _buildTagalogSections() : _buildEnglishSections(),
                ),
              ),
            ),
          ),
          actions: [
            if (!requireAcceptance)
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  isTl ? "Isara" : "Close",
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await setAccepted(true);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(
                isTl ? "Nabasa Ko at Sumasang-ayon Ako" : "I Agree & Accept",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  static List<Widget> _buildEnglishSections() {
    return [
      _section(
        "1. Scope & Purpose of NiyoSense",
        "NiyoSense is an AI-assisted agricultural decision-support system designed for coconut plantation owners, farm managers, and field operators to classify harvested coconuts into Premature (Buko / Malauhog) or Mature (Magulang) stages using dual-modality visual exocarp imaging and acoustic knock spectrograms.",
      ),
      _section(
        "2. Decision-Support Disclaimer",
        "Predictions generated by the on-device YOLOv8-cls TensorFlow Lite models (30% Visual / 70% Acoustic Late Fusion) are provided strictly as field grading assistance. Environmental lighting, microphone obstruction, or atypical husk varieties may affect readings. Final harvest sorting and commercial trading decisions remain the sole responsibility of the plantation owner or operator.",
      ),
      _section(
        "3. Camera & Microphone Hardware Access",
        "The mobile application requires permission to access your device's camera (to capture coconut husk photos) and microphone (to record 4-second percussive knock audio). Audio and image captures are processed locally on-device and are only used for maturity classification and farm inventory logging.",
      ),
      _section(
        "4. Data Privacy & RA 10173 Compliance",
        "In compliance with the Philippine Data Privacy Act of 2012 (Republic Act No. 10173), NiyoSense only collects operational farm telemetry: operator username, device identifier, coconut husk photos, 4-second knock WAV recordings, maturity grades, and bunch (bungkos) counts. Data is stored locally in SQLite and synchronized over HTTPS to your authorized farm dashboard.",
      ),
      _section(
        "5. Acceptable Use & Intellectual Property",
        "Users agree to scan genuine coconut specimens and not misuse or reverse-engineer the embedded neural network weights or dashboard APIs. All software, models, and documentation remain the intellectual property of the NiyoSense Capstone Research Team.",
      ),
    ];
  }

  static List<Widget> _buildTagalogSections() {
    return [
      _section(
        "1. Layunin at Saklaw ng NiyoSense",
        "Ang NiyoSense ay isang AI-assisted decision-support system para sa mga may-ari ng niyugan, tagapamahala ng sakahan, at mga field worker upang uriin ang naaning niyog bilang Premature (Buko / Malauhog) o Mature (Magulang) gamit ang larawan ng balat (exocarp) at tunog ng pagkatok (acoustic spectrogram).",
      ),
      _section(
        "2. Limitasyon sa Pananagutan (Disclaimer)",
        "Ang mga resulta mula sa YOLOv8-cls TensorFlow Lite model (30% Biswal / 70% Akustika) ay nagsisilbing gabay lamang sa pagsusuri sa bukid. Ang pinal na desisyon sa pagbubukod ng ani at bentahan ay nananatiling responsibilidad ng may-ari o tagapamahala ng niyugan.",
      ),
      _section(
        "3. Paggamit ng Kamera at Mikropono",
        "Humihingi ang app ng pahintulot sa kamera (para sa litrato ng buko) at mikropono (para sa 4-segundong tunog ng pagkatok). Ang mga nakuhang larawan at tunog ay pinoproseso nang lokal sa telepono at ginagamit lamang sa pag-uuri ng niyog at talaan ng ani.",
      ),
      _section(
        "4. Proteksyon sa Datos (RA 10173)",
        "Alinsunod sa Philippine Data Privacy Act of 2012 (RA 10173), tanging mga datos ng operasyon sa sakahan lamang ang kinokolekta: username ng operator, device ID, larawan ng buko, 4s audio recording, grado ng kapanahunan, at bilang sa bungkos. Ang datos ay ligtas na itinatala sa lokal na SQLite at isinasabay sa opisyal na farm dashboard.",
      ),
      _section(
        "5. Wastong Paggamit",
        "Sumasang-ayon ang gumagamit na gagamitin lamang ang sistema sa lehitimong pagsusuri ng niyog at hindi gagawin ang anumang hindi awtorisadong pagkopya o pagbago sa AI model at sistema ng NiyoSense.",
      ),
    ];
  }

  static Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
