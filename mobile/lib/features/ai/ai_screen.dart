import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/shell.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/afri_colors.dart';
import '../../core/widgets/afri_components.dart';
import '../../core/widgets/afri_motion.dart';
import '../../core/widgets/afri_premium.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <({String text, bool isUser})>[];
  String? _conversationId;
  bool _loading = false;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _messages.add((
      text: 'Bonjour ! Je suis ton assistant AfriOS. Demande-moi ton chiffre '
          'du mois, tes impayés ou une idée pour vendre plus.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _loadSuggestions() async {
    try {
      final suggestions = await ref.read(apiClientProvider).aiSuggestions();
      if (mounted) setState(() => _suggestions = suggestions);
    } catch (_) {
      if (!mounted) return;
      setState(() => _suggestions = [
            'Combien j\'ai facturé ce mois ?',
            'Factures impayées ?',
            'Stock faible ?',
          ]);
    }
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    setState(() {
      _messages.add((text: text, isUser: true));
      _loading = true;
    });
    _controller.clear();
    _scrollToEnd();

    try {
      final res = await ref
          .read(apiClientProvider)
          .aiChat(text, conversationId: _conversationId);
      _conversationId = res['conversation_id'] as String?;
      if (!mounted) return;
      setState(() {
        _messages.add((text: res['message'] as String, isUser: false));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add((
          text: 'Désolé, une erreur est survenue. Réessaie.',
          isUser: false
        ));
      });
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = shellBottomClearance(context);

    return Scaffold(
      body: AfriMeshBackground(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    20, AfriSpace.md, 20, AfriSpace.xs),
                child: Row(
                  children: [
                    const _AssistantAvatar(),
                    const SizedBox(width: AfriSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assistant AfriOS',
                            style: GoogleFonts.sora(
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                              letterSpacing: -0.4,
                              color: AfriColors.ink,
                            ),
                          ),
                          Text(
                            'Pose une question, AfriOS agit.',
                            style: GoogleFonts.dmSans(
                              color: AfriColors.slateLight,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AfriPill(
                      label: 'EN LIGNE',
                      color: AfriColors.success,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 420.ms).slideY(begin: -0.15, end: 0),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(vertical: AfriSpace.sm),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i >= _messages.length) return const AfriTypingBubble();
                  return AfriChatBubble(
                    message: _messages[i].text,
                    isUser: _messages[i].isUser,
                  );
                },
              ),
            ),
            if (_suggestions.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AfriSpace.md),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AfriSpace.xs),
                  itemBuilder: (_, i) => Center(
                    child: AfriPressable(
                      onTap: () => _send(_suggestions[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AfriRadius.pill),
                          border: Border.all(
                              color: AfriColors.tealSoft, width: 1.4),
                          boxShadow: AfriShadow.subtle,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: AfriColors.teal,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _suggestions[i],
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AfriColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (60 * i).ms, duration: 350.ms)
                      .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  AfriSpace.md, AfriSpace.sm, AfriSpace.md, bottomPad),
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AfriRadius.pill),
                  border: Border.all(color: AfriColors.line),
                  boxShadow: AfriShadow.card,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        decoration: const InputDecoration(
                          hintText: 'Pose ta question...',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        onSubmitted: _send,
                      ),
                    ),
                    AfriPressable(
                      onTap: () => _send(_controller.text),
                      scale: 0.9,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AfriColors.tealGlow,
                          shape: BoxShape.circle,
                          boxShadow:
                              AfriShadow.glow(AfriColors.teal, opacity: 0.28),
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 21,
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
    );
  }
}

/// Assistant mark with a slow breathing halo, so the screen never feels static.
class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AfriColors.teal.withValues(alpha: 0.30),
                  AfriColors.teal.withValues(alpha: 0),
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.15, 1.15),
                duration: 2200.ms,
                curve: Curves.easeInOut,
              ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AfriColors.tealGlow,
              borderRadius: AfriRadius.rSm,
              boxShadow: AfriShadow.glow(AfriColors.teal, opacity: 0.30),
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 21),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
        begin: const Offset(0.85, 0.85),
        end: const Offset(1, 1),
        curve: Curves.easeOutBack);
  }
}
