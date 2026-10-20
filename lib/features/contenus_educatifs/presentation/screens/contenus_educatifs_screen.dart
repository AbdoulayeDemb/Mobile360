import 'package:alert360_mobile/core/theme/app_colors.dart';
import 'package:alert360_mobile/features/contenus_educatifs/data/models/contenu_educatif.dart';
import 'package:alert360_mobile/features/contenus_educatifs/presentation/providers/contenu_educatif_provider.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GuideEducationScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const GuideEducationScreen({super.key, this.onBack});

  @override
  ConsumerState<GuideEducationScreen> createState() =>
      _GuideEducationScreenState();
}

class _GuideEducationScreenState extends ConsumerState<GuideEducationScreen> {
  String _selectedFilter = 'TOUS';
  String _searchQuery = '';
  bool _showSearch = false;

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _filters = const [
    {'label': 'Tous', 'value': 'TOUS'},
    {'label': 'Vidéos', 'value': 'VIDEO'},
    {'label': 'Audios', 'value': 'AUDIO'},
    {'label': 'Images', 'value': 'IMAGE'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(contenusEducatifsProvider);

    try {
      await ref.read(contenusEducatifsProvider.future);
    } catch (_) {
      // L'erreur est affichée par l'état AsyncValue.
    }
  }

  List<ContenuEducatif> _filterContenus(List<ContenuEducatif> contenus) {
    return contenus.where((contenu) {
      final format = contenu.format.trim().toUpperCase();

      final matchesFormat =
          _selectedFilter == 'TOUS' || format == _selectedFilter;

      final query = _searchQuery.trim().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          contenu.titre.toLowerCase().contains(query) ||
          contenu.theme.toLowerCase().contains(query) ||
          (contenu.nomAuteur?.toLowerCase().contains(query) ?? false);

      return matchesFormat && matchesSearch;
    }).toList();
  }

  IconData _iconForFormat(String format) {
    switch (format.trim().toUpperCase()) {
      case 'VIDEO':
        return Icons.play_circle_outline_rounded;
      case 'AUDIO':
        return Icons.headphones_rounded;
      case 'IMAGE':
        return Icons.image_outlined;
      default:
        return Icons.menu_book_rounded;
    }
  }

  Color _colorForFormat(String format) {
    switch (format.trim().toUpperCase()) {
      case 'VIDEO':
        return const Color(0xFF2563EB);
      case 'AUDIO':
        return const Color(0xFF7C3AED);
      case 'IMAGE':
        return const Color(0xFF16A34A);
      default:
        return AppColors.darkBlue;
    }
  }

  String _labelForFormat(String format) {
    switch (format.trim().toUpperCase()) {
      case 'VIDEO':
        return 'Vidéo';
      case 'AUDIO':
        return 'Audio';
      case 'IMAGE':
        return 'Image';
      default:
        return format.isEmpty ? 'Contenu' : format;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date non disponible';

    final d = date.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');

    return '$day/$month/${d.year}';
  }

  void _openDetail(ContenuEducatif contenu) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContenuEducatifDetailSheet(
        contenu: contenu,
        icon: _iconForFormat(contenu.format),
        color: _colorForFormat(contenu.format),
        formatLabel: _labelForFormat(contenu.format),
        dateLabel: _formatDate(contenu.datePublication),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contenusAsync = ref.watch(contenusEducatifsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            if (_showSearch) _buildSearchField(),
            _buildFilters(),
            Expanded(
              child: contenusAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.darkBlue),
                ),
                error: (error, stackTrace) => _buildErrorState(),
                data: (contenus) {
                  final filtered = _filterContenus(contenus);

                  if (contenus.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'Aucun contenu éducatif',
                      message: 'Les contenus publiés apparaîtront ici.',
                    );
                  }

                  if (filtered.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Aucun résultat',
                      message: 'Essaie un autre mot-clé ou un autre filtre.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.darkBlue,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                      children: [
                        _buildSectionHeading(filtered.length),
                        const SizedBox(height: 14),
                        ...filtered.map(
                          (contenu) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ContenuCard(
                              contenu: contenu,
                              icon: _iconForFormat(contenu.format),
                              color: _colorForFormat(contenu.format),
                              formatLabel: _labelForFormat(contenu.format),
                              dateLabel: _formatDate(contenu.datePublication),
                              onTap: () => _openDetail(contenu),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap:
                widget.onBack ??
                () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.darkBlue,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guide & Éducation',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Bonnes pratiques et gestes citoyens',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Rechercher',
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;

                  if (!_showSearch) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
              icon: Icon(
                _showSearch ? Icons.close_rounded : Icons.search_rounded,
                color: const Color(0xFF2563EB),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Rechercher un titre ou un thème...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final value = filter['value']!;
            final label = filter['label']!;
            final selected = _selectedFilter == value;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = value;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.darkBlue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.darkBlue
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.darkBlue,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeading(int count) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'CONTENUS ÉDUCATIFS',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
            ),
          ),
        ),
        Text(
          '$count ${count > 1 ? 'contenus' : 'contenu'}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 54,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger les contenus',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vérifie ta connexion puis réessaie.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContenuCard extends ConsumerStatefulWidget {
  final ContenuEducatif contenu;
  final IconData icon;
  final Color color;
  final String formatLabel;
  final String dateLabel;
  final VoidCallback onTap;

  const _ContenuCard({
    required this.contenu,
    required this.icon,
    required this.color,
    required this.formatLabel,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  ConsumerState<_ContenuCard> createState() => _ContenuCardState();
}

class _ContenuCardState extends ConsumerState<_ContenuCard> {
  AudioPlayer? _audioPlayer;
  VideoPlayerController? _videoController;

  bool _audioPlaying = false;
  bool _audioLoading = false;
  bool _videoLoading = false;
  String? _mediaError;

  String get _format => widget.contenu.format.trim().toUpperCase();
  String get _url => widget.contenu.mediaUrl.trim();

  bool get _validUrl {
    final uri = Uri.tryParse(_url);
    return uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  @override
  void initState() {
    super.initState();

    if (_format == 'AUDIO') {
      _initAudio();
    } else if (_format == 'VIDEO') {
      _initVideo();
    }
  }

  void _initAudio() {
    if (!_validUrl) {
      _mediaError = 'URL audio invalide';
      return;
    }

    final player = AudioPlayer();
    _audioPlayer = player;

    player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _audioPlaying = state == PlayerState.playing;
      });
    });
  }

  Future<void> _initVideo() async {
    if (!_validUrl) {
      _mediaError = 'URL vidéo invalide';
      return;
    }

    _videoLoading = true;

    final controller = VideoPlayerController.networkUrl(Uri.parse(_url));

    _videoController = controller;

    try {
      await controller.initialize();
      await controller.setLooping(false);

      if (!mounted) return;

      setState(() {
        _videoLoading = false;
      });
    } catch (e) {
      await controller.dispose();

      if (identical(_videoController, controller)) {
        _videoController = null;
      }

      if (!mounted) return;

      setState(() {
        _videoLoading = false;
        _mediaError = 'Vidéo indisponible';
      });

      debugPrint('Erreur vidéo dans la carte : $e');
    }
  }

  Future<void> _toggleAudio() async {
    final player = _audioPlayer;
    if (player == null || _audioLoading || !_validUrl) return;

    setState(() {
      _audioLoading = true;
      _mediaError = null;
    });

    try {
      if (_audioPlaying) {
        await player.pause();
      } else {
        await player.play(UrlSource(_url));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mediaError = 'Lecture audio impossible';
        });
      }
      debugPrint('Erreur audio dans la carte : $e');
    } finally {
      if (mounted) {
        setState(() {
          _audioLoading = false;
        });
      }
    }
  }

  Future<void> _toggleVideo() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Erreur de lecture vidéo : $e');
    }
  }

  Widget _buildMediaPreview() {
    if (_url.isEmpty || !_validUrl) {
      return _fallbackMedia();
    }

    switch (_format) {
      case 'IMAGE':
        return Image.network(
          _url,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            return _mediaLoading();
          },
          errorBuilder: (context, error, stackTrace) {
            return _fallbackMedia();
          },
        );

      case 'VIDEO':
        final controller = _videoController;

        if (controller != null && controller.value.isInitialized) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: 220,
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  onPressed: _toggleVideo,
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Color(0xFF3B82F6),
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
            ],
          );
        }

        if (_videoLoading) return _mediaLoading();

        return _fallbackMedia();

      case 'AUDIO':
        return Container(
          height: 150,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF312E81), Color(0xFF6D28D9), Color(0xFFA78BFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.graphic_eq_rounded,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              const Text(
                'ÉCOUTER LE CONTENU',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 4,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: _audioPlaying ? 70 : 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      default:
        return _fallbackMedia();
    }
  }

  Widget _mediaLoading() {
    return Container(
      height: 220,
      width: double.infinity,
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B5998)),
      ),
    );
  }

  Widget _fallbackMedia() {
    return Container(
      height: 180,
      width: double.infinity,
      color: widget.color.withValues(alpha: 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 54, color: widget.color),
          const SizedBox(height: 8),
          Text(
            _mediaError ?? 'Aperçu indisponible',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _buildMediaPreview(),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon, size: 15, color: widget.color),
                          const SizedBox(width: 6),
                          Text(
                            widget.formatLabel.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                              color: widget.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.contenu.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.category_outlined,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.contenu.theme,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.dateLabel,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        if (_format == 'AUDIO')
                          IconButton.filled(
                            tooltip: _audioPlaying
                                ? 'Mettre en pause'
                                : 'Écouter',
                            visualDensity: VisualDensity.compact,
                            onPressed: _audioLoading || !_validUrl
                                ? null
                                : _toggleAudio,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF6D28D9),
                              foregroundColor: Colors.white,
                            ),
                            icon: _audioLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _audioPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                          )
                        else
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                      ],
                    ),
                    if (_mediaError != null && _format == 'AUDIO') ...[
                      const SizedBox(height: 6),
                      Text(
                        _mediaError!,
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fiche détaillée avec affichage direct du média correspondant à son format.
class _ContenuEducatifDetailSheet extends StatefulWidget {
  final ContenuEducatif contenu;
  final IconData icon;
  final Color color;
  final String formatLabel;
  final String dateLabel;

  const _ContenuEducatifDetailSheet({
    required this.contenu,
    required this.icon,
    required this.color,
    required this.formatLabel,
    required this.dateLabel,
  });

  @override
  State<_ContenuEducatifDetailSheet> createState() =>
      _ContenuEducatifDetailSheetState();
}

class _ContenuEducatifDetailSheetState
    extends State<_ContenuEducatifDetailSheet> {
  AudioPlayer? _audioPlayer;
  VideoPlayerController? _videoController;
  bool _audioLoading = false;
  bool _audioPlaying = false;
  String? _mediaError;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  String get _format => widget.contenu.format.trim().toUpperCase();
  String get _mediaUrl => widget.contenu.mediaUrl.trim();

  bool get _validUrl {
    final uri = Uri.tryParse(_mediaUrl);
    return uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  void initState() {
    super.initState();
    if (_format == 'AUDIO') _initializeAudio();
    if (_format == 'VIDEO') _initializeVideo();
  }

  void _initializeAudio() {
    if (!_validUrl) {
      _mediaError = 'URL audio invalide.';
      return;
    }

    final player = AudioPlayer();
    _audioPlayer = player;

    player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;

      setState(() {
        _audioPlaying = state == PlayerState.playing;
      });
    });

    player.onPositionChanged.listen((position) {
      if (!mounted) return;

      setState(() {
        _audioPosition = position;
      });
    });

    player.onDurationChanged.listen((duration) {
      if (!mounted) return;

      setState(() {
        _audioDuration = duration;
      });
    });

    player.onPlayerComplete.listen((_) {
      if (!mounted) return;

      setState(() {
        _audioPlaying = false;
        _audioPosition = Duration.zero;
      });
    });
  }

  Future<void> _initializeVideo() async {
    if (!_validUrl) {
      if (mounted) {
        setState(() {
          _mediaError = 'URL de vidéo invalide.';
        });
      }
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(_mediaUrl));

    _videoController = controller;

    try {
      await controller.initialize();

      if (!mounted) return;

      setState(() {});
    } catch (error) {
      await controller.dispose();

      if (identical(_videoController, controller)) {
        _videoController = null;
      }

      if (!mounted) return;

      setState(() {
        _mediaError = 'Impossible de charger cette vidéo. Vérifie son URL ou les autorisations CORS du serveur.';
      });

      debugPrint('Erreur vidéo : $error');
    }
  }

  Future<void> _toggleAudio() async {
    final player = _audioPlayer;
    if (player == null || _audioLoading) return;
    setState(() {
      _audioLoading = true;
      _mediaError = null;
    });
    try {
      if (_audioPlaying) {
        await player.pause();
      } else if (_audioPosition > Duration.zero &&
          _audioPosition < _audioDuration) {
        await player.resume();
      } else {
        await player.play(UrlSource(_mediaUrl));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _mediaError = 'Impossible de lire cet audio. Vérifie son URL.',
        );
      }
    } finally {
      if (mounted) setState(() => _audioLoading = false);
    }
  }

  String _durationLabel(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _mediaErrorBox(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        const Icon(Icons.error_outline_rounded, size: 40, color: Colors.orange),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        widget.contenu.mediaUrl.trim(),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('ERREUR IMAGE : $error');

          return const Center(
            child: Text(
              'Impossible de charger cette image.',
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAudio() {
    final durationMs = _audioDuration.inMilliseconds;
    final maxValue = durationMs > 0 ? durationMs.toDouble() : 1.0;

    final value = _audioPosition.inMilliseconds
        .clamp(0, durationMs > 0 ? durationMs : 0)
        .toDouble()
        .clamp(0.0, maxValue)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.graphic_eq_rounded,
            size: 56,
            color: Color(0xFF7C3AED),
          ),
          const SizedBox(height: 8),
          const Text(
            'Contenu audio',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Text(
                _durationLabel(_audioPosition),
                style: const TextStyle(fontSize: 11),
              ),
              Expanded(
                child: Slider(
                  min: 0,
                  max: maxValue,
                  value: value,
                  onChanged: durationMs <= 0
                      ? null
                      : (position) async {
                          await _audioPlayer?.seek(
                            Duration(milliseconds: position.round()),
                          );
                        },
                ),
              ),
              Text(
                _durationLabel(_audioDuration),
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
          IconButton.filled(
            onPressed: _audioLoading || !_validUrl ? null : _toggleAudio,
            iconSize: 34,
            icon: _audioLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _audioPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
          ),
          Text(_audioPlaying ? 'Lecture en cours' : 'Lire l’audio'),
          if (_mediaError != null) ...[
            const SizedBox(height: 8),
            Text(
              _mediaError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideo() {
    if (_mediaError != null) return _mediaErrorBox(_mediaError!);
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio > 0
                ? controller.value.aspectRatio
                : 16 / 9,
            child: VideoPlayer(controller),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  color: Colors.white,
                  onPressed: () async {
                    if (controller.value.isPlaying) {
                      await controller.pause();
                    } else {
                      await controller.play();
                    }
                    if (mounted) setState(() {});
                  },
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                Expanded(
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFF3B5998),
                      bufferedColor: Colors.white54,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    if (_mediaUrl.isEmpty)
      return _mediaErrorBox('Aucun média disponible pour ce contenu.');
    if (!_validUrl)
      return _mediaErrorBox(
        'URL du média invalide. Vérifie l’adresse enregistrée dans le backend.',
      );
    switch (_format) {
      case 'IMAGE':
        return _buildImage();
      case 'AUDIO':
        return _buildAudio();
      case 'VIDEO':
        return _buildVideo();
      default:
        return _mediaErrorBox('Format de média non pris en charge : $_format');
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contenu = widget.contenu;
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      contenu.titre,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildMedia(),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: widget.icon,
                    label: widget.formatLabel,
                    color: widget.color,
                  ),
                  _InfoChip(
                    icon: Icons.category_outlined,
                    label: contenu.theme,
                    color: AppColors.darkBlue,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DetailLine(
                icon: Icons.calendar_today_outlined,
                label: 'Date de publication',
                value: widget.dateLabel,
              ),
              if (contenu.nomAuteur != null &&
                  contenu.nomAuteur!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _DetailLine(
                  icon: Icons.person_outline_rounded,
                  label: 'Publié par',
                  value: contenu.nomAuteur!,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
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
