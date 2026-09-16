import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_config.dart';
import '../../core/network/api_url_dialog.dart';
import '../../core/theme/afri_colors.dart';
import '../../core/widgets/afri_button.dart';
import '../../core/widgets/afri_logo.dart';
import '../../core/widgets/afri_motion.dart';
import '../../core/widgets/afri_premium.dart';
import 'auth_provider.dart';

class _WelcomeSlide {
  const _WelcomeSlide({
    required this.asset,
    required this.eyebrow,
    required this.headline,
    required this.accent,
    required this.body,
  });

  final String asset;
  final String eyebrow;
  final String headline;

  /// Trailing part of the headline, painted with the brand gradient.
  final String accent;
  final String body;
}

const _welcomeSlides = [
  _WelcomeSlide(
    asset: 'assets/images/slide_market.png',
    eyebrow: 'GESTION TOUT-EN-UN',
    headline: "L'OS de ton",
    accent: 'business',
    body:
        'Factures, clients et stock réunis dans une seule app — pensée pour les PME africaines.',
  ),
  _WelcomeSlide(
    asset: 'assets/images/slide_invoice.png',
    eyebrow: 'PAIEMENTS MOBILE MONEY',
    headline: 'Encaisse en',
    accent: 'un geste',
    body:
        'Crée une facture, envoie-la par WhatsApp et suis le paiement Wave ou Orange Money en direct.',
  ),
  _WelcomeSlide(
    asset: 'assets/images/slide_growth.png',
    eyebrow: 'ASSISTANT INTELLIGENT',
    headline: 'Ton business,',
    accent: 'accéléré',
    body:
        'Relances automatiques et conseils IA pour te faire payer plus vite et vendre davantage.',
  ),
];

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const _slideDuration = Duration(milliseconds: 5600);

  final _controller = PageController();
  late final AnimationController _progress;
  int _index = 0;
  bool _userTook = false;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: _slideDuration)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed || _userTook) return;
        if (_index < _welcomeSlides.length - 1) {
          _controller.nextPage(
            duration: const Duration(milliseconds: 620),
            curve: Curves.easeOutCubic,
          );
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Any manual interaction hands control back to the user for good.
  void _stopAutoPlay() {
    if (_userTook) return;
    _userTook = true;
    _progress.stop();
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    if (!_userTook) _progress.forward(from: 0);
  }

  void _next() {
    _stopAutoPlay();
    if (_index < _welcomeSlides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.push('/auth/phone');
    }
  }

  double get _page {
    if (!_controller.hasClients) return _index.toDouble();
    return _controller.page ?? _index.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _welcomeSlides.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AfriColors.ink,
        body: Listener(
          onPointerDown: (_) => _stopAutoPlay(),
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: _welcomeSlides.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (_, i) => AfriHeroImage(
                  asset: _welcomeSlides[i].asset,
                  kenBurns: true,
                  reverse: i.isOdd,
                ),
              ),

              // Slide copy lives above the PageView so it can drift at its own
              // pace — that offset difference is what reads as depth.
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final page = _page;
                    return Stack(
                      children: [
                        for (var i = 0; i < _welcomeSlides.length; i++)
                          _SlideCopy(
                            slide: _welcomeSlides[i],
                            delta: i - page,
                          ),
                      ],
                    );
                  },
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 16, 0),
                  child: Row(
                    children: [
                      const _BrandBadge(),
                      const Spacer(),
                      if (!isLast)
                        TextButton(
                          onPressed: () {
                            _stopAutoPlay();
                            context.push('/auth/phone');
                          },
                          child: Text(
                            'Passer',
                            style: GoogleFonts.dmSans(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(duration: 700.ms, delay: 200.ms),
              ),

              Positioned(
                left: 24,
                right: 24,
                bottom: 20,
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      _StoryProgress(
                        count: _welcomeSlides.length,
                        index: _index,
                        animation: _progress,
                        paused: _userTook,
                      ),
                      const SizedBox(height: AfriSpace.lg),
                      AfriButton(
                        label: isLast ? 'Créer mon compte' : 'Continuer',
                        icon: isLast ? Icons.rocket_launch_rounded : null,
                        onPressed: _next,
                      ),
                      const SizedBox(height: AfriSpace.xxs),
                      TextButton(
                        onPressed: () {
                          _stopAutoPlay();
                          context.push('/auth/phone');
                        },
                        child: Text(
                          "J'ai déjà un compte",
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One slide's text block, translated and faded according to how far the
/// PageView has scrolled away from it.
class _SlideCopy extends StatelessWidget {
  const _SlideCopy({required this.slide, required this.delta});

  final _WelcomeSlide slide;
  final double delta;

  @override
  Widget build(BuildContext context) {
    final distance = delta.abs();
    if (distance >= 1) return const SizedBox.shrink();

    final width = MediaQuery.of(context).size.width;
    final opacity = (1 - distance * 1.6).clamp(0.0, 1.0);

    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(delta * width * 0.42, 0),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 210),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AfriRadius.pill),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: Text(
                      slide.eyebrow,
                      style: GoogleFonts.dmSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                        color: AfriColors.goldBright,
                      ),
                    ),
                  ),
                  const SizedBox(height: AfriSpace.md),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.sora(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.12,
                        letterSpacing: -1.2,
                      ),
                      children: [
                        TextSpan(text: '${slide.headline}\n'),
                        TextSpan(
                          text: slide.accent,
                          style: const TextStyle(color: AfriColors.tealBright),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AfriSpace.sm),
                  Text(
                    slide.body,
                    style: GoogleFonts.dmSans(
                      fontSize: 15.5,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.80),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass chip holding the logo mark plus wordmark.
class _BrandBadge extends StatelessWidget {
  const _BrandBadge();

  @override
  Widget build(BuildContext context) {
    return AfriGlass(
      dark: true,
      radius: AfriRadius.pill,
      blur: 10,
      padding: const EdgeInsets.fromLTRB(8, 7, 16, 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const AfriLogo(height: 22),
          ),
          const SizedBox(width: AfriSpace.xs),
          Text(
            'AfriOS',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Story-style segmented progress: the active bar fills while autoplay runs and
/// stays solid once the user takes over.
class _StoryProgress extends StatelessWidget {
  const _StoryProgress({
    required this.count,
    required this.index,
    required this.animation,
    required this.paused,
  });

  final int count;
  final int index;
  final Animation<double> animation;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AfriRadius.pill),
                child: SizedBox(
                  height: 3,
                  child: Stack(
                    children: [
                      ColoredBox(
                        color: Colors.white.withValues(alpha: 0.22),
                        child: const SizedBox.expand(),
                      ),
                      if (i < index || (i == index && paused))
                        const _ProgressFill(value: 1)
                      else if (i == index)
                        AnimatedBuilder(
                          animation: animation,
                          builder: (context, _) =>
                              _ProgressFill(value: animation.value),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProgressFill extends StatelessWidget {
  const _ProgressFill({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: value.clamp(0.0, 1.0),
      child: const DecoratedBox(
        decoration: BoxDecoration(gradient: AfriColors.goldGlow),
        child: SizedBox.expand(),
      ),
    );
  }
}

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  PhoneNumber? _phoneNumber;
  String _isoCountry = 'SN';
  bool _loading = false;

  String? _validatePhone(PhoneNumber? phone) {
    if (phone == null || phone.number.trim().isEmpty) {
      return 'Saisis ton numéro de téléphone';
    }
    final digits = phone.number.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) return 'Numéro trop court';
    final complete = phone.completeNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (complete.length < 8) return 'Numéro invalide (indicatif inclus)';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: 'URL serveur',
                        onPressed: () async {
                          final changed = await showApiUrlDialog(context);
                          if (changed && mounted) setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AfriFadeSlide(
                    child: Text(
                      'AfriOS',
                      style: GoogleFonts.sora(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AfriColors.ink,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AfriFadeSlide(
                    delay: 60.ms,
                    child: Text(
                      'Entre ton numéro pour créer ton compte ou te connecter.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AfriColors.slate),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AfriFadeSlide(
                    delay: 120.ms,
                    child: IntlPhoneField(
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        hintText: '77 123 45 67',
                      ),
                      initialCountryCode: 'SN',
                      disableLengthCheck: true,
                      onChanged: (phone) {
                        _phoneNumber = phone;
                        _isoCountry = phone.countryISOCode;
                      },
                      onSaved: (phone) {
                        _phoneNumber = phone;
                        if (phone != null) _isoCountry = phone.countryISOCode;
                      },
                      validator: _validatePhone,
                    ),
                  ),
                  if (ApiConfig.likelyNeedsLanUrl) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Serveur local : ${ApiConfig.baseUrl}',
                      style: const TextStyle(
                          fontSize: 11, color: AfriColors.slate),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AfriColors.amberSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.wifi_tethering,
                              size: 18, color: AfriColors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cette installation pointe vers une API locale. '
                              'Pour utiliser AfriOS partout (4G), va dans ⚙️ → URL serveur → Par défaut.',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AfriColors.ink,
                                  height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  AfriButton(
                    label: 'Recevoir le code OTP',
                    isLoading: _loading,
                    icon: Icons.sms_outlined,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      _formKey.currentState!.save();
                      final phone = _phoneNumber?.completeNumber.trim() ?? '';
                      if (phone.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Numéro de téléphone invalide')),
                        );
                        return;
                      }
                      setState(() => _loading = true);
                      try {
                        final res =
                            await ref.read(authStateProvider.notifier).sendOtp(
                                  phone,
                                  isoCountryCode: _isoCountry,
                                );
                        if (context.mounted) {
                          context.push('/auth/otp', extra: {
                            'phone': phone,
                            'devCode': res['dev_code'] as String?,
                            'channel': res['channel'] as String?,
                            'message': res['message'] as String?,
                          });
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ApiConfig.friendlyError(e)),
                              duration: const Duration(seconds: 8),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    this.devCode,
    this.channel,
    this.message,
  });

  final String phone;
  final String? devCode;
  final String? channel;
  final String? message;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _devCode;
  String? _channel;
  String? _statusMessage;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _devCode = widget.devCode;
    _channel = widget.channel;
    _statusMessage = widget.message;
    _startCooldown();
  }

  void _startCooldown([int seconds = 45]) {
    _resendCooldown = seconds;
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown = (_resendCooldown - 1).clamp(0, 999));
      return _resendCooldown > 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      final res = await ref.read(authStateProvider.notifier).sendOtp(widget.phone);
      if (!mounted) return;
      setState(() {
        _devCode = res['dev_code'] as String?;
        _channel = res['channel'] as String?;
        _statusMessage = res['message'] as String?;
      });
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_statusMessage ?? 'Nouveau code envoyé')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiConfig.friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final smsSent = _channel == 'sms' || _channel == 'sms+dev';

    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(height: 12),
                  AfriFadeSlide(
                    child: Text('Vérification',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  const SizedBox(height: 8),
                  AfriFadeSlide(
                    delay: 60.ms,
                    child: Text(
                      smsSent
                          ? 'SMS envoyé au ${widget.phone}'
                          : 'Code pour ${widget.phone}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AfriColors.slate),
                    ),
                  ),
                  if (_statusMessage != null && _devCode == null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage!,
                      style: const TextStyle(
                          fontSize: 13, color: AfriColors.slate, height: 1.35),
                    ),
                  ],
                  if (_devCode != null) ...[
                    const SizedBox(height: 14),
                    AfriFadeSlide(
                      delay: 100.ms,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AfriColors.tealGlow,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              smsSent
                                  ? 'Mode dev — code aussi envoyé par SMS'
                                  : 'Mode développement',
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _devCode!,
                              style: GoogleFonts.sora(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  AfriFadeSlide(
                    delay: 140.ms,
                    child: TextFormField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(
                        fontSize: 28,
                        letterSpacing: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '------',
                      ),
                      validator: (value) {
                        final code = value?.trim() ?? '';
                        if (code.isEmpty) return 'Saisis le code reçu';
                        if (code.length < 4) {
                          return 'Code trop court (4 à 6 chiffres)';
                        }
                        if (!RegExp(r'^\d+$').hasMatch(code)) {
                          return 'Chiffres uniquement';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _resendCooldown > 0 || _resending ? null : _resend,
                      child: Text(
                        _resendCooldown > 0
                            ? 'Renvoyer dans ${_resendCooldown}s'
                            : 'Renvoyer le code',
                      ),
                    ),
                  ),
                  const Spacer(),
                  AfriButton(
                    label: 'Vérifier',
                    isLoading: _loading,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _loading = true);
                      try {
                        await ref.read(authStateProvider.notifier).verifyOtp(
                              widget.phone,
                              _controller.text.trim(),
                            );
                        if (context.mounted) {
                          final auth = ref.read(authStateProvider);
                          if (auth.onboardingCompleted) {
                            context.go('/home');
                          } else {
                            context.go('/onboarding/profile');
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ApiConfig.friendlyError(e))),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taxController = TextEditingController(text: '0');
  String _sector = 'Boutique';
  String _country = 'SN';
  String _currency = 'XOF';
  bool _loading = false;

  static const _countries = [
    ('SN', 'Sénégal'),
    ('CI', "Côte d'Ivoire"),
    ('BF', 'Burkina Faso'),
    ('ML', 'Mali'),
    ('GN', 'Guinée'),
    ('TG', 'Togo'),
    ('BJ', 'Bénin'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = ref.read(authStateProvider);
      if (auth.businessName != null && mounted) {
        context.go('/onboarding/tour');
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('phone_country_code');
      if (code != null && mounted) setState(() => _country = code);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                AfriFadeSlide(
                  child: Text(
                    'AfriOS',
                    style: GoogleFonts.sora(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AfriFadeSlide(
                  delay: 50.ms,
                  child: Text(
                    'Crée ta boutique',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                AfriFadeSlide(
                  delay: 90.ms,
                  child: Text(
                    'Ces infos apparaîtront sur tes factures.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AfriColors.slate),
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'entreprise / boutique *',
                    hintText: 'Ex. Boutique Chez Aminata',
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return 'Indique le nom de ton entreprise';
                    if (name.length < 2) return 'Au moins 2 caractères';
                    if (name.length > 255) return 'Nom trop long';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text('Secteur *',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Boutique',
                    'Restaurant',
                    'Services',
                    'Artisanat',
                    'Autre'
                  ].map((s) {
                    final selected = _sector == s;
                    return ChoiceChip(
                      label: Text(s),
                      selected: selected,
                      onSelected: (_) => setState(() => _sector = s),
                      selectedColor: AfriColors.tealSoft,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? AfriColors.tealDark : AfriColors.ink,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _country,
                  decoration: const InputDecoration(labelText: 'Pays *'),
                  items: _countries
                      .map((c) => DropdownMenuItem(
                          value: c.$1, child: Text('${c.$2} (${c.$1})')))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _country = v;
                      _currency = 'XOF';
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(labelText: 'Devise *'),
                  items: const [
                    DropdownMenuItem(value: 'XOF', child: Text('FCFA (XOF)')),
                    DropdownMenuItem(
                        value: 'GNF', child: Text('Franc guinéen (GNF)')),
                    DropdownMenuItem(value: 'EUR', child: Text('Euro (EUR)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _currency = v);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taxController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Taux de TVA (%)',
                    hintText: '0 si non applicable',
                    helperText: 'Ex. 18 pour 18 %',
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (n == null) return 'Nombre invalide';
                    if (n < 0 || n > 100) return 'Entre 0 et 100';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                AfriButton(
                  label: 'Continuer',
                  isLoading: _loading,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _loading = true);
                    try {
                      await ref.read(authStateProvider.notifier).createBusiness(
                            name: _nameController.text.trim(),
                            sector: _sector,
                            currency: _currency,
                            countryCode: _country,
                            taxRate: double.tryParse(
                                    _taxController.text.replaceAll(',', '.')) ??
                                0,
                          );
                      if (context.mounted) context.go('/onboarding/tour');
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ApiConfig.friendlyError(e)),
                            duration: const Duration(seconds: 6),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingTourScreen extends ConsumerWidget {
  const OnboardingTourScreen({super.key});

  static const _steps = [
    (
      Icons.people_outline_rounded,
      'Ajoute tes premiers clients',
      'Construis ton carnet en quelques taps.'
    ),
    (
      Icons.receipt_long_outlined,
      'Crée ta première facture',
      'Envoie-la WhatsApp ou Mobile Money.'
    ),
    (
      Icons.inventory_2_outlined,
      'Configure ton stock',
      'Alertes automatiques quand ça baisse.'
    ),
    (
      Icons.auto_awesome_outlined,
      'Découvre l\'assistant IA',
      'Demande, AfriOS exécute.'
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                const AfriLogo(height: 72)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1, 1)),
                const SizedBox(height: 20),
                Text('Prêt à démarrer ?',
                        style: Theme.of(context).textTheme.headlineMedium)
                    .animate()
                    .fadeIn(delay: 80.ms),
                const SizedBox(height: 28),
                ..._steps.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return AfriFadeSlide(
                    delay: (120 + i * 70).ms,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AfriColors.mistDeep),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AfriColors.tealSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(s.$1, color: AfriColors.tealDark),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.$2,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(s.$3,
                                    style: const TextStyle(
                                        fontSize: 13, color: AfriColors.slate)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const Spacer(),
                AfriButton(
                  label: 'C\'est parti !',
                  icon: Icons.rocket_launch_rounded,
                  onPressed: () async {
                    try {
                      await ref
                          .read(authStateProvider.notifier)
                          .completeOnboarding();
                      if (context.mounted) context.go('/home');
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ApiConfig.friendlyError(e))),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
