import 'package:flutter/material.dart';
import 'package:rajpurohit/login.dart';
import 'config/api.dart';
import 'sidebar.dart';
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> with TickerProviderStateMixin {
  AnimationController? _heroController;
  AnimationController? _cardsController;
  AnimationController? _floatController;
  AnimationController? _shimmerController;
  AnimationController? _pulseController;

  Animation<double>? _heroFade;
  Animation<Offset>? _heroSlide;
  Animation<double>? _cardsFade;
  Animation<Offset>? _cardsSlide;
  Animation<double>? _floatAnimation;
  Animation<double>? _shimmerAnimation;
  Animation<double>? _pulseAnimation;

  // Fallback animations used before controllers are ready
  static final _zeroOffset = AlwaysStoppedAnimation<Offset>(Offset.zero);
  static final _oneDouble = AlwaysStoppedAnimation<double>(1.0);
  static final _zeroDouble = AlwaysStoppedAnimation<double>(0.0);

  final List<Map<String, dynamic>> _services = [
    {
      'icon': Icons.location_city_rounded,
      'city': 'Mumbai',
      'color': const Color(0xff6C63FF),
      'delay': 0,
    },
    {
      'icon': Icons.account_balance_rounded,
      'city': 'Pune',
      'color': const Color(0xff43E8D8),
      'delay': 80,
    },
    {
      'icon': Icons.fort_rounded,
      'city': 'Aurangabad',
      'color': const Color(0xffFF6584),
      'delay': 160,
    },
    {
      'icon': Icons.grain_rounded,
      'city': 'Ahmadnagar',
      'color': const Color(0xffFFBE43),
      'delay': 240,
    },
    {
      'icon': Icons.water_rounded,
      'city': 'Akola',
      'color': const Color(0xff43A9FF),
      'delay': 320,
    },
    {
      'icon': Icons.park_rounded,
      'city': 'Amravati',
      'color': const Color(0xff6EE28A),
      'delay': 400,
    },
    {
      'icon': Icons.temple_hindu_rounded,
      'city': 'Nagpur',
      'color': const Color(0xffE87D43),
      'delay': 480,
    },
  ];

  final List<Map<String, dynamic>> _stats = [
    {'value': '24+', 'label': 'Years Legacy', 'icon': Icons.history_edu_rounded},
    {'value': '7', 'label': 'Cities Covered', 'icon': Icons.map_rounded},
    {'value': '∞', 'label': 'Trust & Service', 'icon': Icons.favorite_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Use local non-null variables so CurvedAnimation/Tween.animate
    // receive AnimationController (not AnimationController?) — fixes null-safety errors.
    final heroCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _heroController = heroCtrl;
    _heroFade = CurvedAnimation(parent: heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: heroCtrl, curve: Curves.easeOutCubic));

    final cardsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _cardsController = cardsCtrl;
    _cardsFade = CurvedAnimation(parent: cardsCtrl, curve: Curves.easeOut);
    _cardsSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: cardsCtrl, curve: Curves.easeOutCubic));

    final floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _floatController = floatCtrl;
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0)
        .animate(CurvedAnimation(parent: floatCtrl, curve: Curves.easeInOut));

    final shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat();
    _shimmerController = shimmerCtrl;
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: shimmerCtrl, curve: Curves.easeInOut));

    final pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulseController = pulseCtrl;
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: pulseCtrl, curve: Curves.easeInOut));

    heroCtrl.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) cardsCtrl.forward();
    });
  }

  @override
  void dispose() {
    _heroController?.dispose();
    _cardsController?.dispose();
    _floatController?.dispose();
    _shimmerController?.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WatermarkedScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0d1232),
        title: AnimatedBuilder(
          animation: _shimmerAnimation ?? _oneDouble,
          builder: (context, child) {
            final sv = (_shimmerAnimation ?? _oneDouble).value;
            return ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: const [
                  Color(0xffaab4f5),
                  Color(0xffffffff),
                  Color(0xffaab4f5),
                ],
                stops: [
                  (sv - 0.5).clamp(0.0, 1.0),
                  sv.clamp(0.0, 1.0),
                  (sv + 0.5).clamp(0.0, 1.0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: const Text(
                'RAJPUROHIT OTC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
            );
          },
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff0d1232), Color(0xff1a2058)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: sidebar(),
      body: Container(
        color: const Color(0xff060c24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeroSection(context),
              _buildStatsRow(),
              _buildAboutSection(),
              _buildLegacySection(),
              _buildCitiesSection(),
              _buildFooter(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return FadeTransition(
      opacity: _heroFade ?? _oneDouble,
      child: SlideTransition(
        position: _heroSlide ?? _zeroOffset,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 56),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff0d1232), Color(0xff1a2768), Color(0xff0d1232)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Decorative blobs
              Positioned(
                top: -30,
                right: -20,
                child: _GlowBlob(
                  color: const Color(0xff6C63FF),
                  size: 160,
                  opacity: 0.15,
                ),
              ),
              Positioned(
                bottom: -20,
                left: -30,
                child: _GlowBlob(
                  color: const Color(0xff43E8D8),
                  size: 130,
                  opacity: 0.12,
                ),
              ),
              Column(
                children: [

                  const SizedBox(height: 28),

                  // Logo with float animation
                  AnimatedBuilder(
                    animation: _floatAnimation ?? _zeroDouble,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, (_floatAnimation ?? _zeroDouble).value),
                        child: child,
                      );
                    },
                    child: ClipOval(
                      child: Container(
                        color: Colors.white,
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/images/logo1.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'RAJPUROHIT',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xff6C63FF), Color(0xff43E8D8)],
                    ).createShader(bounds),
                    child: const Text(
                      'OTC SERVICE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: 60,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff6C63FF), Color(0xff43E8D8)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Delivering Trust Across Maharashtra',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xffaab4f5),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return FadeTransition(
      opacity: _cardsFade ?? _oneDouble,
      child: SlideTransition(
        position: _cardsSlide ?? _zeroOffset,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          transform: Matrix4.translationValues(0, -28, 0),
          child: Row(
            children: _stats.asMap().entries.map((entry) {
              final stat = entry.value;
              return Expanded(
                child: _AnimatedStatCard(
                  value: stat['value'],
                  label: stat['label'],
                  icon: stat['icon'],
                  delay: entry.key * 120,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return FadeTransition(
      opacity: _cardsFade ?? _oneDouble,
      child: SlideTransition(
        position: _cardsSlide ?? _zeroOffset,
        child: _GlassCard(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff6C63FF), Color(0xff43E8D8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff6C63FF).withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'About Us',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'RAJPUROHIT OTC SERVICE is dedicated to providing reliable courier and logistics solutions across Maharashtra. With our commitment to speed, safety, and customer satisfaction, we simplify every delivery experience.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.75,
                  color: Color(0xffaab4f5),
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegacySection() {
    return FadeTransition(
      opacity: _cardsFade ?? _oneDouble,
      child: SlideTransition(
        position: _cardsSlide ?? _zeroOffset,
        child: _GlassCard(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xffFFBE43), Color(0xffFF6584)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xffFFBE43).withOpacity(0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Our Legacy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Timeline style
              _LegacyTimeline(
                year: '2000',
                name: 'MR. Jogsingh Rajpurohit',
                role: 'Founder',
                icon: Icons.star_rounded,
                color: const Color(0xffFFBE43),
              ),
              const SizedBox(height: 14),
              _LegacyTimeline(
                year: 'Present',
                name: 'MR. Mahendrasingh Rajpurohit',
                role: 'Continuing the Legacy',
                icon: Icons.trending_up_rounded,
                color: const Color(0xff43E8D8),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote_rounded, color: Color(0xffaab4f5), size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Over two decades of trusted service and continuous innovation in logistics.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xffaab4f5),
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCitiesSection() {
    return FadeTransition(
      opacity: _cardsFade ?? _oneDouble,
      child: _GlassCard(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff43A9FF), Color(0xff6C63FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff43A9FF).withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.route_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Daily Routes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xff6C63FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xff6C63FF).withOpacity(0.3)),
                  ),
                  child: Text(
                    '${_services.length} cities',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xff6C63FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _services.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final s = _services[index];
                  return _CityChip(
                    icon: s['icon'] as IconData,
                    city: s['city'] as String,
                    color: s['color'] as Color,
                    delay: s['delay'] as int,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _cardsFade ?? _oneDouble,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff1a2058), Color(0xff0d1232)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xff6C63FF).withOpacity(0.25),
          ),
        ),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation ?? _oneDouble,
              builder: (context, child) {
                return Transform.scale(
                  scale: (_pulseAnimation ?? _oneDouble).value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xff6C63FF), Color(0xff43E8D8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff6C63FF).withOpacity(0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 26),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reliable · Fast · Trusted',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xffaab4f5),
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowBlob({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  const _GlassCard({required this.child, required this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff131a45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AnimatedStatCard extends StatefulWidget {
  final String value;
  final String label;
  final IconData icon;
  final int delay;

  const _AnimatedStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.delay,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scale;
  Animation<double>? _fade;

  static final _one = AlwaysStoppedAnimation<double>(1.0);

  @override
  void initState() {
    super.initState();
    final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _controller = ctrl;
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: ctrl, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(parent: ctrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: 500 + widget.delay), () {
      if (mounted) ctrl.forward();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade ?? _one,
      child: ScaleTransition(
        scale: _scale ?? _one,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff1a2058), Color(0xff131a45)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: const Color(0xff6C63FF), size: 20),
              const SizedBox(height: 6),
              Text(
                widget.value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xffaab4f5),
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegacyTimeline extends StatelessWidget {
  final String year;
  final String name;
  final String role;
  final IconData icon;
  final Color color;

  const _LegacyTimeline({
    required this.year,
    required this.name,
    required this.role,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      year,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xffaab4f5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CityChip extends StatefulWidget {
  final IconData icon;
  final String city;
  final Color color;
  final int delay;

  const _CityChip({
    required this.icon,
    required this.city,
    required this.color,
    required this.delay,
  });

  @override
  State<_CityChip> createState() => _CityChipState();
}

class _CityChipState extends State<_CityChip> with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  Animation<double>? _fade;
  Animation<double>? _scale;

  static final _one = AlwaysStoppedAnimation<double>(1.0);

  @override
  void initState() {
    super.initState();
    final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _ctrl = ctrl;
    _fade = CurvedAnimation(parent: ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: 700 + widget.delay), () {
      if (mounted) ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade ?? _one,
      child: ScaleTransition(
        scale: _scale ?? _one,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: widget.color.withOpacity(0.35), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.color, size: 14),
              const SizedBox(width: 6),
              Text(
                widget.city,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}