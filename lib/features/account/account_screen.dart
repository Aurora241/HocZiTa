import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_background.dart';
import '../../data/datasources/local_datasource.dart';
import '../auth/auth_providers.dart';
import 'my_progress_screen.dart';

// ── Provider thống kê ──────────────────────────────────────────────────────

final _statsProvider = FutureProvider.autoDispose<_Stats>((ref) async {
  ref.watch(scoreVersionProvider);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const _Stats(totalStars: 0, gamesPlayed: 0);
  final ds = LocalDataSource();
  final totalStars = await ds.getTotalStarsByUser(user.id);
  final allScores = await ds.getAllScores();
  final gamesPlayed = allScores.where((s) => s.userId == user.id).length;
  return _Stats(totalStars: totalStars, gamesPlayed: gamesPlayed);
});

class _Stats {
  final int totalStars;
  final int gamesPlayed;
  const _Stats({required this.totalStars, required this.gamesPlayed});
}

// ─────────────────────────────────────────────────────────────────────────────

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Scaffold(
        body: Center(child: Text('Có lỗi xảy ra')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Vui lòng đăng nhập')),
          );
        }
        return _AccountBody(
          key: ValueKey(user.name + (user.avatarPath ?? '')),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AccountBody extends ConsumerWidget {
  const _AccountBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(_statsProvider);

    final user = userAsync.valueOrNull;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppAuroraBackground(),
          SingleChildScrollView(
        child: Column(
          children: [
            // ── Header gradient — trượt từ trên xuống ────────────────────
            _ProfileHeader(
              name: user.name,
              email: user.email,
              avatarPath: user.avatarPath,
              totalStars: statsAsync.valueOrNull?.totalStars ?? 0,
              onTapAvatar: () => _pickAvatar(context, ref, user.id),
            )
                .animate()
                .slideY(
                  begin: -1,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // ── Stats row — trượt từ trái sang ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _StatsRow(
                totalStars: statsAsync.valueOrNull?.totalStars ?? 0,
                gamesPlayed: statsAsync.valueOrNull?.gamesPlayed ?? 0,
              ),
            )
                .animate()
                .slideX(
                  begin: -0.3,
                  end: 0,
                  delay: 150.ms,
                  duration: 450.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(delay: 150.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Menu items — từng card trồi lên, stagger ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MenuItemCard(
                icon: Icons.emoji_events_rounded,
                label: 'Tiến độ của tôi',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MyProgressScreen()),
                ),
              ),
            )
                .animate()
                .slideY(
                  begin: 0.4,
                  end: 0,
                  delay: 250.ms,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(delay: 250.ms, duration: 350.ms),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MenuItemCard(
                icon: Icons.person_outline_rounded,
                label: 'Chỉnh sửa tên',
                onTap: () => _showEditName(context, ref, user.name),
              ),
            )
                .animate()
                .slideY(
                  begin: 0.4,
                  end: 0,
                  delay: 330.ms,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(delay: 330.ms, duration: 350.ms),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MenuItemCard(
                icon: Icons.lock_outline_rounded,
                label: 'Đổi mật khẩu',
                onTap: () => _showChangePassword(context, ref, user.id),
              ),
            )
                .animate()
                .slideY(
                  begin: 0.4,
                  end: 0,
                  delay: 410.ms,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(delay: 410.ms, duration: 350.ms),

            const SizedBox(height: 24),

            // ── Đăng xuất — trượt từ phải sang ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _logout(context, ref),
                ),
              ),
            )
                .animate()
                .slideX(
                  begin: 0.3,
                  end: 0,
                  delay: 500.ms,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(delay: 500.ms, duration: 350.ms),

            // Padding để nội dung không bị floating nav bar che
            SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
          ],
        ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar(
      BuildContext context, WidgetRef ref, String userId) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AvatarSourceSheet(),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 400,
    );
    if (picked == null) return;

    final repo = ref.read(authRepoProvider);
    await repo.updateProfile(userId: userId, avatarPath: picked.path);
    ref.invalidate(currentUserProvider);
  }

  void _showEditName(BuildContext context, WidgetRef ref, String currentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditNameSheet(
        currentName: currentName,
        onSave: (newName) async {
          final user = ref.read(currentUserProvider).valueOrNull;
          if (user == null) return;
          await ref
              .read(authRepoProvider)
              .updateProfile(userId: user.id, name: newName);
          ref.invalidate(currentUserProvider);
        },
      ),
    );
  }

  void _showChangePassword(
      BuildContext context, WidgetRef ref, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ChangePasswordSheet(
        onSave: (oldPw, newPw) async {
          return ref.read(authRepoProvider).changePassword(
                userId: userId,
                oldPassword: oldPw,
                newPassword: newPw,
              );
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(authRepoProvider).logout();
    ref.invalidate(authProvider);
    ref.invalidate(currentUserProvider);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header gradient + avatar
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarPath;
  final int totalStars;
  final VoidCallback onTapAvatar;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.avatarPath,
    required this.totalStars,
    required this.onTapAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0077BB), Color(0xFF00AADD)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x330077BB),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, topPad + 20, 24, 32),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTapAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  backgroundImage: avatarPath != null
                      ? FileImage(File(avatarPath!))
                      : null,
                  child: avatarPath == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 16, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: AppColors.star, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$totalStars sao tổng cộng',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int totalStars;
  final int gamesPlayed;
  const _StatsRow({required this.totalStars, required this.gamesPlayed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            iconColor: AppColors.star,
            value: '$totalStars',
            label: 'Tổng sao',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.sports_esports_rounded,
            iconColor: AppColors.primary,
            value: '$gamesPlayed',
            label: 'Lượt chơi',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu item card — mỗi item là 1 card riêng có shadow
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItemCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItemCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 15, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: chọn nguồn ảnh
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarSourceSheet extends StatelessWidget {
  const _AvatarSourceSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chọn ảnh đại diện',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Thư viện',
                  color: AppColors.primary,
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Chụp ảnh',
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: chỉnh sửa tên
// ─────────────────────────────────────────────────────────────────────────────

class _EditNameSheet extends StatefulWidget {
  final String currentName;
  final Future<void> Function(String newName) onSave;

  const _EditNameSheet({required this.currentName, required this.onSave});

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _ctrl;
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await widget.onSave(_ctrl.text.trim());
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật tên'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chỉnh sửa tên',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên';
                if (v.trim().length < 2) return 'Tên ít nhất 2 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Huỷ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Lưu'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: đổi mật khẩu
// ─────────────────────────────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  final Future<String?> Function(String oldPw, String newPw) onSave;
  const _ChangePasswordSheet({required this.onSave});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _errorMsg = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final error = await widget.onSave(_oldCtrl.text, _newCtrl.text);

    setState(() => _loading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
      return;
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Đổi mật khẩu',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _oldCtrl,
              obscureText: _obscureOld,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureOld
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu cũ' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newCtrl,
              obscureText: _obscureNew,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                if (v.length < 6) return 'Ít nhất 6 ký tự';
                if (v == _oldCtrl.text) return 'Phải khác mật khẩu cũ';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng xác nhận';
                if (v != _newCtrl.text) return 'Mật khẩu không khớp';
                return null;
              },
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('ĐỔI MẬT KHẨU'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
