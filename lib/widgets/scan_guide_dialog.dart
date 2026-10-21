import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_translations.dart';

/// Interactive 4-Page Controlled Grading & Inspection Guide Modal
/// Explains the Field Manager role, controlled station environment,
/// visual scan/do-not-scan bounds, and animated 3-knock tapping protocol.
class ScanGuideDialog extends StatefulWidget {
  final bool isHelpMode;

  const ScanGuideDialog({super.key, this.isHelpMode = false});

  /// Static helper to check SharedPreferences and show the dialog if not suppressed
  static Future<bool> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool hideGuide = prefs.getBool('hide_pre_scan_guide') ?? false;
    if (hideGuide) return true;

    if (!context.mounted) return true;
    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ScanGuideDialog(),
    );
    return proceed == true;
  }

  @override
  State<ScanGuideDialog> createState() => _ScanGuideDialogState();
}

class _ScanGuideDialogState extends State<ScanGuideDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _dontShowAgain = prefs.getBool('hide_pre_scan_guide') ?? false;
      });
    }
  }

  Future<void> _savePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_pre_scan_guide', value);
  }

  void _onDone(bool proceed) async {
    if (!widget.isHelpMode) {
      await _savePreference(_dontShowAgain);
    }
    if (mounted) {
      Navigator.of(context).pop(proceed);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              // Header with Page Dots and Close
              _buildHeader(),

              // 4-Page Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  children: [
                    _buildPage1Environment(),
                    _buildPage2VisualBounds(),
                    _buildPage3DosAndDonts(),
                    _buildPage4AudioKnock(),
                  ],
                ),
              ),

              // Bottom Navigation & Persistence Controls
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      AppTranslations.text('guide_badge_manager'),
                      style: const TextStyle(
                        color: Color(0xFF065F46),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${_currentPage + 1} / 4",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Dots Indicator
          Row(
            children: List.generate(4, (i) {
              final bool isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF059669) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),

          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 22),
            onPressed: () => _onDone(false),
            tooltip: AppTranslations.text('close'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PAGE 1: ROLE & CONTROLLED GRADING ENVIRONMENT
  // -------------------------------------------------------------
  Widget _buildPage1Environment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
              ),
              child: const Icon(Icons.gavel_rounded, color: Color(0xFF059669), size: 30),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              AppTranslations.text('guide_p1_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              AppTranslations.text('guide_p1_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 18),

          _buildInfoTile(
            icon: Icons.person_pin_rounded,
            color: const Color(0xFF0284C7),
            title: AppTranslations.text('guide_p1_card1_title'),
            desc: AppTranslations.text('guide_p1_card1_desc'),
          ),
          const SizedBox(height: 10),

          _buildInfoTile(
            icon: Icons.table_restaurant_rounded,
            color: const Color(0xFF059669),
            title: AppTranslations.text('guide_p1_card2_title'),
            desc: AppTranslations.text('guide_p1_card2_desc'),
          ),
          const SizedBox(height: 10),

          _buildInfoTile(
            icon: Icons.hub_rounded,
            color: const Color(0xFFD97706),
            title: AppTranslations.text('guide_p1_card3_title'),
            desc: AppTranslations.text('guide_p1_card3_desc'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PAGE 2: WHAT TO SCAN VS. WHAT NOT TO SCAN (IMAGE COMPARISON)
  // -------------------------------------------------------------
  Widget _buildPage2VisualBounds() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              AppTranslations.text('guide_p2_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              AppTranslations.text('guide_p2_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // VALID OBJECT: COCONUT
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981), width: 1.8),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 78,
                    height: 78,
                    color: Colors.white,
                    child: Image.asset(
                      'assets/guide/scan_ok/coconut_green.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            AppTranslations.text('guide_p2_valid_badge'),
                            style: const TextStyle(
                              color: Color(0xFF065F46),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppTranslations.text('guide_p2_valid_title'),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppTranslations.text('guide_p2_valid_desc'),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // REJECTED OBJECTS: GREEN FRUITS, TABLES, CLOTH
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEF4444), width: 1.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      AppTranslations.text('guide_p2_invalid_badge'),
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3 Bad Examples Grid
                Row(
                  children: [
                    _buildRejectThumbnail('assets/guide/scan_no/green_apple.jpg', AppTranslations.text('guide_p2_item_apple')),
                    const SizedBox(width: 8),
                    _buildRejectThumbnail('assets/guide/scan_no/green_table.jpg', AppTranslations.text('guide_p2_item_table')),
                    const SizedBox(width: 8),
                    _buildRejectThumbnail('assets/guide/scan_no/green_cloth.jpg', AppTranslations.text('guide_p2_item_cloth')),
                  ],
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppTranslations.text('guide_p2_rule_warn'),
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectThumbnail(String path, String label) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 64,
                  width: double.infinity,
                  color: Colors.white,
                  child: Image.asset(path, fit: BoxFit.cover),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7F1D1D),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PAGE 3: CONTROLLED STATION DO'S & DON'TS
  // -------------------------------------------------------------
  Widget _buildPage3DosAndDonts() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              AppTranslations.text('guide_p3_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              AppTranslations.text('guide_p3_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // DO CARD
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.text('guide_p3_do_header'),
                      style: const TextStyle(
                        color: Color(0xFF065F46),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildBulletPoint("• ${AppTranslations.text('guide_p3_do_1')}", const Color(0xFF047857)),
                _buildBulletPoint("• ${AppTranslations.text('guide_p3_do_2')}", const Color(0xFF047857)),
                _buildBulletPoint("• ${AppTranslations.text('guide_p3_do_3')}", const Color(0xFF047857)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // DON'T CARD
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.highlight_off_rounded, color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.text('guide_p3_dont_header'),
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildBulletPoint("• ${AppTranslations.text('guide_p3_dont_1')}", const Color(0xFFB91C1C)),
                _buildBulletPoint("• ${AppTranslations.text('guide_p3_dont_2')}", const Color(0xFFB91C1C)),
                _buildBulletPoint("• ${AppTranslations.text('guide_p3_dont_3')}", const Color(0xFFB91C1C)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // PAGE 4: ACOUSTIC TAPPING PROTOCOL & ANIMATION
  // -------------------------------------------------------------
  Widget _buildPage4AudioKnock() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              AppTranslations.text('guide_p4_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              AppTranslations.text('guide_p4_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Native Flutter Knocking Animation Widget
          const KnockAnimationWidget(),
          const SizedBox(height: 14),

          // 3 Numbered Steps
          _buildStepRow("1", AppTranslations.text('guide_p4_step1_title'), AppTranslations.text('guide_p4_step1_desc')),
          const SizedBox(height: 8),
          _buildStepRow("2", AppTranslations.text('guide_p4_step2_title'), AppTranslations.text('guide_p4_step2_desc')),
          const SizedBox(height: 8),
          _buildStepRow("3", AppTranslations.text('guide_p4_step3_title'), AppTranslations.text('guide_p4_step3_desc')),
        ],
      ),
    );
  }

  Widget _buildStepRow(String number, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF059669),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: color.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // BOTTOM CONTROLS & CHECKBOX
  // -------------------------------------------------------------
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Don't show again checkbox (shown on Page 4 or if not in help mode)
          if (!widget.isHelpMode && _currentPage == 3) ...[
            InkWell(
              onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _dontShowAgain,
                        activeColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        onChanged: (val) => setState(() => _dontShowAgain = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.text('guide_dont_show_again'),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(
                      AppTranslations.text('back'),
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 10),

              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: () {
                    if (_currentPage < 3) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _onDone(true);
                    }
                  },
                  child: Text(
                    _currentPage == 3
                        ? (widget.isHelpMode
                            ? AppTranslations.text('guide_close_btn')
                            : AppTranslations.text('guide_start_btn'))
                        : AppTranslations.text('next'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Native Flutter Looping Animated Knocker & Soundwave Illustration
/// Accurately shows the standard acoustic knock spot (upper shoulder near stem cap),
/// animated hand knuckle striking the target zone 3 times, and expanding soundwaves.
class KnockAnimationWidget extends StatefulWidget {
  const KnockAnimationWidget({super.key});

  @override
  State<KnockAnimationWidget> createState() => _KnockAnimationWidgetState();
}

class _KnockAnimationWidgetState extends State<KnockAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    // 3.6 second loop: 3 knocks (~1s cadence) + 0.6s pause
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final double progress = _animController.value; // 0.0 .. 1.0

        // Determine current knock index (1, 2, 3) or pause (0)
        // 0.00 - 0.25 -> Knock 1
        // 0.25 - 0.50 -> Knock 2
        // 0.50 - 0.75 -> Knock 3
        // 0.75 - 1.00 -> Rest / Loop
        int knockIndex = 0;
        double knockPhase = 0.0;
        if (progress < 0.25) {
          knockIndex = 1;
          knockPhase = progress / 0.25;
        } else if (progress < 0.50) {
          knockIndex = 2;
          knockPhase = (progress - 0.25) / 0.25;
        } else if (progress < 0.75) {
          knockIndex = 3;
          knockPhase = (progress - 0.50) / 0.25;
        } else {
          knockIndex = 0; // Rest
          knockPhase = 0.0;
        }

        // Hand movement towards upper shoulder target spot:
        // Moves down and slightly left towards the target spot on impact (at knockPhase ~0.22)
        double strikeDelta = 0.0;
        if (knockIndex > 0) {
          if (knockPhase < 0.22) {
            // Forward strike down-left
            strikeDelta = (knockPhase / 0.22);
          } else if (knockPhase < 0.55) {
            // Spring bounce back
            strikeDelta = 1.0 - ((knockPhase - 0.22) / 0.33);
          }
        }

        // Ripple expansion on impact
        double rippleRadius = 0.0;
        double rippleOpacity = 0.0;
        if (knockIndex > 0 && knockPhase >= 0.20) {
          final double waveProgress = (knockPhase - 0.20) / 0.80;
          rippleRadius = waveProgress * 54.0;
          rippleOpacity = (1.0 - waveProgress).clamp(0.0, 1.0);
        }

        return Container(
          height: 155,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double cardW = constraints.maxWidth;
              // Target spot coordinate on the card (upper shoulder near stem)
              // Coconut is centered slightly left
              final double coconutLeft = (cardW / 2) - 85;
              const double coconutTop = 38;
              const double coconutW = 95;
              const double coconutH = 92;

              // The upper shoulder target spot relative to card coordinates
              final double targetX = coconutLeft + 68;
              final double targetY = coconutTop + 34;

              // Hand positioning: top right of coconut, striking towards (targetX, targetY)
              final double handRestX = coconutLeft + 105;
              final double handRestY = coconutTop - 18;

              // Hand movement vector towards target
              final double handX = handRestX - (strikeDelta * 22);
              final double handY = handRestY + (strikeDelta * 20);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Soundwave Ripples expanding from exact target spot on the coconut
                  CustomPaint(
                    size: Size(cardW, 155),
                    painter: _SoundwavePainter(
                      origin: Offset(targetX, targetY),
                      rippleRadius: rippleRadius,
                      rippleOpacity: rippleOpacity,
                    ),
                  ),

                  // Central Coconut Image
                  Positioned(
                    left: coconutLeft,
                    top: coconutTop,
                    width: coconutW,
                    height: coconutH,
                    child: Image.asset(
                      'assets/guide/scan_ok/coconut_knock_clean.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Standard Acoustic Knock Target Zone (Glowing Red Curved Outline & Fill)
                  Positioned(
                    left: coconutLeft + 42,
                    top: coconutTop + 14,
                    child: CustomPaint(
                      size: const Size(40, 36),
                      painter: _TargetZonePainter(
                        isImpact: knockIndex > 0 && strikeDelta > 0.8,
                      ),
                    ),
                  ),

                  // Red Target Callout Label / Pill
                  Positioned(
                    left: coconutLeft - 10,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 10),
                          SizedBox(width: 4),
                          Text(
                            "Target: Upper Shoulder",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Animated Knocking Hand (Transparent PNG)
                  Positioned(
                    left: handX,
                    top: handY,
                    width: 52,
                    height: 96,
                    child: Transform.rotate(
                      angle: -0.22, // Slight natural angle towards coconut upper shoulder
                      child: Image.asset(
                        'assets/guide/scan_ok/knock_hand.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Phone Microphone Indicator (5-10cm left positioning)
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                          ),
                          child: const Icon(Icons.mic, color: Color(0xFF10B981), size: 14),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Mic 5–10 cm\nfrom coconut",
                          style: TextStyle(color: Colors.white70, fontSize: 9, height: 1.2),
                        ),
                      ],
                    ),
                  ),

                  // Live Tap Step Badge (Top Right)
                  Positioned(
                    top: 10,
                    right: 12,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: knockIndex > 0 ? const Color(0xFF065F46) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: knockIndex > 0 ? const Color(0xFF10B981) : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            knockIndex > 0 ? Icons.volume_up_rounded : Icons.pause_rounded,
                            color: knockIndex > 0 ? const Color(0xFF34D399) : Colors.white38,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            knockIndex > 0 ? "Knock $knockIndex of 3" : "Wait 1s...",
                            style: TextStyle(
                              color: knockIndex > 0 ? Colors.white : Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Custom painter to draw the glowing red target zone on the upper shoulder near the stem
class _TargetZonePainter extends CustomPainter {
  final bool isImpact;

  _TargetZonePainter({required this.isImpact});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 4, size.width - 4, size.height - 8);

    // Glowing background fill
    final fillPaint = Paint()
      ..color = (isImpact ? const Color(0xFFEF4444) : const Color(0xFFF87171))
          .withValues(alpha: isImpact ? 0.45 : 0.25)
      ..style = PaintingStyle.fill;

    // Glowing border outline
    final strokePaint = Paint()
      ..color = (isImpact ? Colors.white : const Color(0xFFEF4444))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isImpact ? 2.5 : 1.8;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _TargetZonePainter oldDelegate) {
    return oldDelegate.isImpact != isImpact;
  }
}

class _SoundwavePainter extends CustomPainter {
  final Offset origin;
  final double rippleRadius;
  final double rippleOpacity;

  _SoundwavePainter({
    required this.origin,
    required this.rippleRadius,
    required this.rippleOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rippleRadius <= 0.0 || rippleOpacity <= 0.0) return;

    final paint1 = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: rippleOpacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final paint2 = Paint()
      ..color = const Color(0xFF34D399).withValues(alpha: rippleOpacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(origin, rippleRadius, paint1);
    if (rippleRadius > 14.0) {
      canvas.drawCircle(origin, rippleRadius - 12.0, paint2);
    }
  }

  @override
  bool shouldRepaint(covariant _SoundwavePainter oldDelegate) {
    return oldDelegate.rippleRadius != rippleRadius ||
        oldDelegate.rippleOpacity != rippleOpacity ||
        oldDelegate.origin != origin;
  }
}
