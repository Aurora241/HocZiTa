import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_background.dart';
import '../../data/models/nks_user_model.dart';
import '../auth/auth_providers.dart';

class UpdateCccdScreen extends ConsumerStatefulWidget {
  final NKSUserModel nksUser;
  const UpdateCccdScreen({super.key, required this.nksUser});

  @override
  ConsumerState<UpdateCccdScreen> createState() => _UpdateCccdScreenState();
}

class _UpdateCccdScreenState extends ConsumerState<UpdateCccdScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _numberCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _placeCtrl;

  File? _frontFile;
  File? _backFile;
  bool _loading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final u = widget.nksUser;
    _numberCtrl = TextEditingController(text: u.idNumber ?? '');
    _dateCtrl = TextEditingController(text: u.idDate ?? '');
    _placeCtrl = TextEditingController(text: u.idPlace ?? '');
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _dateCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ImageSourceSheet(label: isFront ? 'mặt trước' : 'mặt sau'),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() {
      if (isFront) {
        _frontFile = File(picked.path);
      } else {
        _backFile = File(picked.path);
      }
    });
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    if (_dateCtrl.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_dateCtrl.text);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Ngày cấp CCCD',
    );
    if (picked != null) {
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      _dateCtrl.text = '$y-$m-$d';
    }
  }

  Future<void> _save() async {
    setState(() => _errorMsg = null);
    if (!_formKey.currentState!.validate()) return;

    final hasExistingFront = widget.nksUser.cccdFront != null &&
        widget.nksUser.cccdFront!.isNotEmpty;
    final hasExistingBack = widget.nksUser.cccdBack != null &&
        widget.nksUser.cccdBack!.isNotEmpty;

    if (_frontFile == null && !hasExistingFront) {
      setState(() => _errorMsg = 'Vui lòng chụp/chọn ảnh mặt trước CCCD');
      return;
    }
    if (_backFile == null && !hasExistingBack) {
      setState(() => _errorMsg = 'Vui lòng chụp/chọn ảnh mặt sau CCCD');
      return;
    }

    // Nếu không chọn ảnh mới, dùng placeholder (API vẫn yêu cầu trường này)
    // Thực tế: gửi ảnh mới nếu có, không gửi nếu không thay đổi
    if (_frontFile == null && _backFile == null) {
      // Chỉ cập nhật số/ngày/nơi cấp — không có ảnh mới
      // Gửi chuỗi rỗng để giữ ảnh cũ (tùy backend)
      setState(() => _errorMsg = 'Chọn lại ảnh CCCD để lưu thay đổi');
      return;
    }

    setState(() => _loading = true);

    try {
      String frontBase64 = '';
      String backBase64 = '';

      if (_frontFile != null) {
        frontBase64 = base64Encode(await _frontFile!.readAsBytes());
      }
      if (_backFile != null) {
        backBase64 = base64Encode(await _backFile!.readAsBytes());
      }

      // Nếu chỉ chọn 1 ảnh, ảnh còn lại bắt buộc
      if (frontBase64.isEmpty || backBase64.isEmpty) {
        setState(() {
          _loading = false;
          _errorMsg = frontBase64.isEmpty
              ? 'Vui lòng chụp/chọn lại ảnh mặt trước'
              : 'Vui lòng chụp/chọn lại ảnh mặt sau';
        });
        return;
      }

      final updated = await ref.read(nksApiServiceProvider).updateCccd(
            token: widget.nksUser.accessToken!,
            frontBase64: frontBase64,
            backBase64: backBase64,
            number: _numberCtrl.text.trim(),
            date: _dateCtrl.text.trim(),
            place: _placeCtrl.text.trim(),
          );
      ref.read(nksAuthProvider.notifier).updateUser(updated);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đã cập nhật CCCD'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.nksUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppAuroraBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Cập nhật CCCD',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Ảnh CCCD ──────────────────────────────────────
                          _card(children: [
                            _sectionLabel('Ảnh CCCD / CMND'),
                            const SizedBox(height: 6),
                            const Text(
                              'Chụp rõ nét, đủ 4 góc, không bị chói sáng',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _ImagePicker(
                                    label: 'Mặt trước',
                                    file: _frontFile,
                                    existingUrl: u.cccdFront,
                                    onTap: () => _pickImage(true),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ImagePicker(
                                    label: 'Mặt sau',
                                    file: _backFile,
                                    existingUrl: u.cccdBack,
                                    onTap: () => _pickImage(false),
                                  ),
                                ),
                              ],
                            ),
                          ]),

                          const SizedBox(height: 16),

                          // ── Thông tin CCCD ────────────────────────────────
                          _card(children: [
                            _sectionLabel('Thông tin giấy tờ'),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _numberCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Số CCCD / CMND',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Vui lòng nhập số CCCD';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _dateCtrl,
                              readOnly: true,
                              onTap: _pickDate,
                              decoration: const InputDecoration(
                                labelText: 'Ngày cấp',
                                prefixIcon: Icon(Icons.calendar_today_rounded),
                                suffixIcon:
                                    Icon(Icons.edit_calendar_rounded, size: 18),
                                hintText: 'yyyy-mm-dd',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Vui lòng chọn ngày cấp';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _placeCtrl,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Nơi cấp',
                                prefixIcon: Icon(Icons.location_city_rounded),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Vui lòng nhập nơi cấp';
                                }
                                return null;
                              },
                            ),
                          ]),

                          if (_errorMsg != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        AppColors.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: AppColors.error, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMsg!,
                                      style: const TextStyle(
                                          color: AppColors.error, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _save,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'LƯU CCCD',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Image picker card ────────────────────────────────────────────────────────

class _ImagePicker extends StatelessWidget {
  final String label;
  final File? file;
  final String? existingUrl;
  final VoidCallback onTap;

  const _ImagePicker({
    required this.label,
    required this.file,
    required this.existingUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasNew = file != null;
    final hasExisting = existingUrl != null && existingUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasNew
                ? AppColors.success
                : AppColors.primary.withValues(alpha: 0.3),
            width: hasNew ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: hasNew
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(file!, fit: BoxFit.cover),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                )
              : hasExisting
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          existingUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) =>
                              _placeholder(label, hasExisting: true),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.black54,
                            child: const Text(
                              'Nhấn để thay thế',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _placeholder(label, hasExisting: false),
        ),
      ),
    );
  }

  Widget _placeholder(String label, {required bool hasExisting}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 32,
          color: AppColors.primary.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hasExisting ? 'Nhấn để thay thế' : 'Chụp hoặc chọn ảnh',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Bottom sheet chọn nguồn ảnh ─────────────────────────────────────────────

class _ImageSourceSheet extends StatelessWidget {
  final String label;
  const _ImageSourceSheet({required this.label});

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
          Text(
            'Chọn ảnh $label',
            style: const TextStyle(
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
                  color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
