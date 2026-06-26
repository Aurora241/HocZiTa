import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_background.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/models/nks_user_model.dart';
import '../auth/auth_providers.dart';
import 'my_progress_screen.dart';
import 'stub_screens.dart';
import 'update_cccd_screen.dart';
import 'update_info_screen.dart';

// ── Provider thống kê ──────────────────────────────────────────────────────

final _statsProvider = FutureProvider.autoDispose<_Stats>((ref) async {
  ref.watch(scoreVersionProvider);

  // Ưu tiên NKS user
  final nksUser = ref.watch(currentNKSUserProvider);
  final userId = nksUser?.id.toString();

  // Fallback local user
  final localUserId = userId ??
      (await ref.watch(currentUserProvider.future))?.id;

  if (localUserId == null) return const _Stats(totalStars: 0, gamesPlayed: 0);

  final ds = LocalDataSource();
  final totalStars = await ds.getTotalStarsByUser(localUserId);
  final allScores = await ds.getAllScores();
  final gamesPlayed =
      allScores.where((s) => s.userId == localUserId).length;
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
    final nksUser = ref.watch(currentNKSUserProvider);
    final nksState = ref.watch(nksAuthProvider);

    if (nksUser != null) {
      return _AccountBody(key: ValueKey('${nksUser.id}_${nksUser.avatar}'));
    }

    // Session NKS đang được restore từ SharedPreferences — chờ
    if (nksState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Fallback: local auth (tài khoản cũ trước khi tích hợp NKS)
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Scaffold(
        body: Center(child: Text('Có lỗi xảy ra')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
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
    final nksUser = ref.watch(currentNKSUserProvider);
    final statsAsync = ref.watch(_statsProvider);

    // Lấy thông tin hiển thị — ưu tiên NKS, fallback local
    final localUser = ref.watch(currentUserProvider).valueOrNull;
    final displayName = nksUser?.displayName ?? localUser?.name ?? '';
    final displayEmail = nksUser?.email ?? localUser?.email ?? '';
    final avatarUrl = nksUser?.avatar;
    final avatarPath = (nksUser == null) ? localUser?.avatarPath : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppAuroraBackground(),
          SingleChildScrollView(
            child: Column(
              children: [
                // ── Header ───────────────────────────────────────────────
                _ProfileHeader(
                  name: displayName,
                  email: displayEmail,
                  avatarUrl: avatarUrl,
                  avatarPath: avatarPath,
                  totalStars: statsAsync.valueOrNull?.totalStars ?? 0,
                  onTapAvatar: () => _pickAvatar(context, ref, nksUser),
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

                // ── Stats row ─────────────────────────────────────────────
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

                // ── Menu items ────────────────────────────────────────────
                ..._buildMenuItems(context, ref, nksUser, localUser?.id),
                const SizedBox(height: 24),

                // ── Đăng xuất ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.error),
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

                SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(
    BuildContext context,
    WidgetRef ref,
    NKSUserModel? nksUser,
    String? localUserId,
  ) {
    final items = [
      _MenuItem(
        icon: Icons.emoji_events_rounded,
        label: 'Tiến độ của tôi',
        delay: 250,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyProgressScreen())),
      ),
      if (nksUser != null)
        _MenuItem(
          icon: Icons.edit_note_rounded,
          label: 'Cập nhật thông tin',
          delay: 330,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => UpdateInfoScreen(nksUser: nksUser))),
        ),
      if (nksUser != null)
        _MenuItem(
          icon: Icons.credit_card_rounded,
          label: 'Cập nhật CCCD',
          delay: 410,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => UpdateCccdScreen(nksUser: nksUser))),
        ),
      _MenuItem(
        icon: Icons.person_outline_rounded,
        label: 'Chỉnh sửa tên',
        delay: 490,
        onTap: () => _showEditName(context, ref, nksUser),
      ),
      _MenuItem(
        icon: Icons.lock_outline_rounded,
        label: 'Đổi mật khẩu',
        delay: 570,
        onTap: () => _showChangePassword(context, ref, nksUser, localUserId),
      ),
      if (nksUser != null)
        _MenuItem(
          icon: Icons.card_membership_rounded,
          label: 'Thành viên',
          delay: 650,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MembershipScreen())),
        ),
      if (nksUser != null)
        _MenuItem(
          icon: Icons.history_rounded,
          label: 'Lịch sử giao dịch',
          delay: 730,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HistoryScreen())),
        ),
      if (nksUser != null)
        _MenuItem(
          icon: Icons.redeem_rounded,
          label: 'Điểm thưởng',
          delay: 810,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RewardScreen())),
        ),
      if (nksUser != null)
        _MenuItem(
          icon: Icons.account_balance_rounded,
          label: 'Thông tin ngân hàng',
          delay: 890,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BankInfoScreen())),
        ),
    ];

    return items.asMap().entries.map((e) {
      final item = e.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: _MenuItemCard(
          icon: item.icon,
          label: item.label,
          onTap: item.onTap,
        )
            .animate()
            .slideY(
              begin: 0.4,
              end: 0,
              delay: Duration(milliseconds: item.delay),
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeIn(
              delay: Duration(milliseconds: item.delay),
              duration: 350.ms,
            ),
      );
    }).toList();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _pickAvatar(
      BuildContext context, WidgetRef ref, NKSUserModel? nksUser) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AvatarSourceSheet(),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90, maxWidth: 1024);
    if (picked == null) return;

    // Crop/edit step
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Chỉnh sửa ảnh',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.original,
          ],
        ),
        IOSUiSettings(
          title: 'Chỉnh sửa ảnh',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.original,
          ],
        ),
      ],
    );
    if (cropped == null) return;

    if (nksUser?.accessToken != null) {
      final bytes = await File(cropped.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      try {
        final updated = await ref.read(nksApiServiceProvider).updateAvatar(
              token: nksUser!.accessToken!,
              base64Image: base64Image,
            );
        ref.read(nksAuthProvider.notifier).updateUser(updated);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Đã cập nhật ảnh đại diện'),
            backgroundColor: AppColors.success,
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ));
        }
      }
    } else {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) return;
      await ref
          .read(authRepoProvider)
          .updateProfile(userId: user.id, avatarPath: cropped.path);
      ref.invalidate(currentUserProvider);
    }
  }

  void _showEditName(
      BuildContext context, WidgetRef ref, NKSUserModel? nksUser) {
    final currentName = nksUser?.displayName ??
        ref.read(currentUserProvider).valueOrNull?.name ??
        '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditNameSheet(
        currentName: currentName,
        onSave: (newName) async {
          if (nksUser?.accessToken != null) {
            // Tách họ và tên: từ đầu = họ, phần còn lại = tên
            final parts = newName.trim().split(' ');
            final lastname = parts.first;
            final firstname =
                parts.length > 1 ? parts.sublist(1).join(' ') : '';
            final updated =
                await ref.read(nksApiServiceProvider).updateInfo(
                      token: nksUser!.accessToken!,
                      firstname: firstname,
                      lastname: lastname,
                    );
            ref.read(nksAuthProvider.notifier).updateUser(updated);
          } else {
            final user = ref.read(currentUserProvider).valueOrNull;
            if (user == null) return;
            await ref
                .read(authRepoProvider)
                .updateProfile(userId: user.id, name: newName);
            ref.invalidate(currentUserProvider);
          }
        },
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref,
      NKSUserModel? nksUser, String? localUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ChangePasswordSheet(
        onSave: (oldPw, newPw) async {
          if (nksUser?.accessToken != null) {
            try {
              await ref.read(nksApiServiceProvider).updatePassword(
                    token: nksUser!.accessToken!,
                    oldPassword: oldPw,
                    newPassword: newPw,
                  );
              return null;
            } catch (e) {
              return e.toString();
            }
          } else {
            return ref.read(authRepoProvider).changePassword(
                  userId: localUserId ?? '',
                  oldPassword: oldPw,
                  newPassword: newPw,
                );
          }
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

    await ref.read(nksAuthProvider.notifier).logout();
    await ref.read(authRepoProvider).logout();
    ref.invalidate(authProvider);
    ref.invalidate(currentUserProvider);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String label;
  final int delay;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.delay,
      required this.onTap});
}

// ─────────────────────────────────────────────────────────────────────────────
// Header gradient + avatar
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final String? avatarPath;
  final int totalStars;
  final VoidCallback onTapAvatar;

  const _ProfileHeader({
    required this.name,
    required this.email,
    this.avatarUrl,
    this.avatarPath,
    required this.totalStars,
    required this.onTapAvatar,
  });

  ImageProvider? get _imageProvider {
    if (avatarUrl != null &&
        avatarUrl!.isNotEmpty &&
        !avatarUrl!.contains('default.png')) {
      return NetworkImage(avatarUrl!);
    }
    if (avatarPath != null) return FileImage(File(avatarPath!));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final image = _imageProvider;

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
                  backgroundImage: image,
                  child: image == null
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.star, size: 18),
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
// Menu item card
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
// Bottom sheet: đổi mật khẩu (có random password generator)
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

  // Random password generator
  bool _showGenerator = false;
  int _charCount = 12;
  bool _useUpper = true;
  bool _useLower = true;
  bool _useDigit = true;
  bool _useSpecial = false;
  String? _generatedPassword;

  // Xác nhận đã lưu mật khẩu
  bool _confirmedSaved = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _generatePassword() {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const digits = '0123456789';
    const special = r'!@#$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (_useUpper) chars += upper;
    if (_useLower) chars += lower;
    if (_useDigit) chars += digits;
    if (_useSpecial) chars += special;
    if (chars.isEmpty) chars = lower + digits;

    final rng = math.Random.secure();
    return List.generate(_charCount, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  void _onGeneratePressed() {
    setState(() => _generatedPassword = _generatePassword());
  }

  Future<void> _confirmGeneratedPassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đổi mật khẩu'),
        content: const Text('Bạn có chắc muốn dùng mật khẩu vừa tạo không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed == true && _generatedPassword != null) {
      setState(() {
        _newCtrl.text = _generatedPassword!;
        _confirmCtrl.text = _generatedPassword!;
        _obscureNew = false;
        _obscureConfirm = false;
        _showGenerator = false;
        _generatedPassword = null;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _errorMsg = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_confirmedSaved) {
      setState(() => _errorMsg = 'Vui lòng xác nhận đã lưu mật khẩu mới');
      return;
    }
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
    return SingleChildScrollView(
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
              'Đổi mật khẩu',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),

            // Mật khẩu cũ
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

            // Mật khẩu mới + nút dice
            TextFormField(
              controller: _newCtrl,
              obscureText: _obscureNew,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.casino_rounded,
                        color: _showGenerator
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      tooltip: 'Tạo mật khẩu ngẫu nhiên',
                      onPressed: () =>
                          setState(() => _showGenerator = !_showGenerator),
                    ),
                    IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ],
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                if (v.length < 6) return 'Ít nhất 6 ký tự';
                if (v == _oldCtrl.text) return 'Phải khác mật khẩu cũ';
                return null;
              },
            ),

            // Generator panel (animated)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _showGenerator
                  ? _GeneratorPanel(
                      charCount: _charCount,
                      useUpper: _useUpper,
                      useLower: _useLower,
                      useDigit: _useDigit,
                      useSpecial: _useSpecial,
                      generatedPassword: _generatedPassword,
                      onCharCountChanged: (v) =>
                          setState(() => _charCount = v.round()),
                      onUpperChanged: (v) =>
                          setState(() => _useUpper = v ?? _useUpper),
                      onLowerChanged: (v) =>
                          setState(() => _useLower = v ?? _useLower),
                      onDigitChanged: (v) =>
                          setState(() => _useDigit = v ?? _useDigit),
                      onSpecialChanged: (v) =>
                          setState(() => _useSpecial = v ?? _useSpecial),
                      onGenerate: _onGeneratePressed,
                      onConfirm: _confirmGeneratedPassword,
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 12),

            // Xác nhận mật khẩu mới
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

            const SizedBox(height: 8),

            // Xác nhận đã lưu mật khẩu
            InkWell(
              onTap: () => setState(() => _confirmedSaved = !_confirmedSaved),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Checkbox(
                    value: _confirmedSaved,
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onChanged: (v) =>
                        setState(() => _confirmedSaved = v ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'Tôi đã lưu mật khẩu mới vào nơi an toàn',
                      style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMsg != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_loading || !_confirmedSaved) ? null : _save,
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

// ─────────────────────────────────────────────────────────────────────────────
// Generator panel
// ─────────────────────────────────────────────────────────────────────────────

class _GeneratorPanel extends StatelessWidget {
  final int charCount;
  final bool useUpper;
  final bool useLower;
  final bool useDigit;
  final bool useSpecial;
  final String? generatedPassword;
  final ValueChanged<double> onCharCountChanged;
  final ValueChanged<bool?> onUpperChanged;
  final ValueChanged<bool?> onLowerChanged;
  final ValueChanged<bool?> onDigitChanged;
  final ValueChanged<bool?> onSpecialChanged;
  final VoidCallback onGenerate;
  final VoidCallback onConfirm;

  const _GeneratorPanel({
    required this.charCount,
    required this.useUpper,
    required this.useLower,
    required this.useDigit,
    required this.useSpecial,
    required this.generatedPassword,
    required this.onCharCountChanged,
    required this.onUpperChanged,
    required this.onLowerChanged,
    required this.onDigitChanged,
    required this.onSpecialChanged,
    required this.onGenerate,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.casino_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Tạo mật khẩu ngẫu nhiên',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Số ký tự:', style: TextStyle(fontSize: 13)),
              Expanded(
                child: Slider(
                  value: charCount.toDouble(),
                  min: 6,
                  max: 32,
                  divisions: 26,
                  activeColor: AppColors.primary,
                  onChanged: onCharCountChanged,
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '$charCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          _CheckOption('Ký tự hoa (A–Z)', useUpper, onUpperChanged),
          _CheckOption('Ký tự thường (a–z)', useLower, onLowerChanged),
          _CheckOption('Ký tự số (0–9)', useDigit, onDigitChanged),
          _CheckOption('Ký tự đặc biệt (!@#...)', useSpecial, onSpecialChanged),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tạo mật khẩu'),
              onPressed: onGenerate,
            ),
          ),
          if (generatedPassword != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      generatedPassword!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: AppColors.textSecondary,
                    tooltip: 'Sao chép',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: generatedPassword!));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                onPressed: onConfirm,
                child: const Text('Xác nhận dùng mật khẩu này'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckOption extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckOption(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: onChanged,
          ),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

