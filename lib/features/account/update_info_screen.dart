import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_background.dart';
import '../../data/models/nks_user_model.dart';
import '../auth/auth_providers.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _provincesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(nksApiServiceProvider).getProvinces();
});

// ─────────────────────────────────────────────────────────────────────────────

class UpdateInfoScreen extends ConsumerStatefulWidget {
  final NKSUserModel nksUser;
  const UpdateInfoScreen({super.key, required this.nksUser});

  @override
  ConsumerState<UpdateInfoScreen> createState() => _UpdateInfoScreenState();
}

class _UpdateInfoScreenState extends ConsumerState<UpdateInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _lastnameCtrl;
  late final TextEditingController _firstnameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _introCtrl;

  int _gender = 0;
  String? _selectedProvinceName;
  bool _loading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final u = widget.nksUser;
    _lastnameCtrl = TextEditingController(text: u.lastname ?? '');
    _firstnameCtrl = TextEditingController(text: u.firstname ?? '');
    _phoneCtrl = TextEditingController(text: u.phone ?? '');
    _dobCtrl = TextEditingController(text: u.dob ?? '');
    _websiteCtrl = TextEditingController(text: u.website ?? '');
    _introCtrl = TextEditingController(text: u.intro ?? '');
    _gender = u.gender;
    _selectedProvinceName = u.province;
  }

  @override
  void dispose() {
    _lastnameCtrl.dispose();
    _firstnameCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _websiteCtrl.dispose();
    _introCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    if (_dobCtrl.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_dobCtrl.text);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      helpText: 'Chọn ngày sinh',
      locale: const Locale('vi'),
    );
    if (picked != null) {
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      _dobCtrl.text = '$y-$m-$d';
    }
  }

  Future<void> _save() async {
    setState(() => _errorMsg = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final updated = await ref.read(nksApiServiceProvider).updateInfo(
            token: widget.nksUser.accessToken!,
            lastname: _lastnameCtrl.text.trim().isEmpty ? null : _lastnameCtrl.text.trim(),
            firstname: _firstnameCtrl.text.trim().isEmpty ? null : _firstnameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            gender: _gender,
            dob: _dobCtrl.text.trim().isEmpty ? null : _dobCtrl.text.trim(),
            website: _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
            province: _selectedProvinceName,
            intro: _introCtrl.text.trim().isEmpty ? null : _introCtrl.text.trim(),
          );
      ref.read(nksAuthProvider.notifier).updateUser(updated);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đã cập nhật thông tin'),
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
    final provincesAsync = ref.watch(_provincesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppAuroraBackground(),
          SafeArea(
            child: Column(
              children: [
                // AppBar
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
                          'Cập nhật thông tin',
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

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _card(children: [
                            _sectionLabel('Tên hiển thị'),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _lastnameCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Họ',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _firstnameCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Tên',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 16),

                          _card(children: [
                            _sectionLabel('Liên hệ'),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Số điện thoại',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _websiteCtrl,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'Website (không bắt buộc)',
                                prefixIcon: Icon(Icons.link_rounded),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 16),

                          _card(children: [
                            _sectionLabel('Thông tin cá nhân'),
                            const SizedBox(height: 12),

                            // Giới tính
                            DropdownButtonFormField<int>(
                              initialValue: _gender,
                              decoration: const InputDecoration(
                                labelText: 'Giới tính',
                                prefixIcon: Icon(Icons.wc_rounded),
                              ),
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('Nam')),
                                DropdownMenuItem(value: 1, child: Text('Nữ')),
                              ],
                              onChanged: (v) => setState(() => _gender = v ?? 0),
                            ),

                            const SizedBox(height: 12),

                            // Ngày sinh
                            TextFormField(
                              controller: _dobCtrl,
                              readOnly: true,
                              onTap: _pickDate,
                              decoration: const InputDecoration(
                                labelText: 'Ngày sinh',
                                prefixIcon: Icon(Icons.cake_outlined),
                                suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                                hintText: 'yyyy-mm-dd',
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Tỉnh/thành
                            provincesAsync.when(
                              loading: () => const InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Tỉnh/thành',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 10),
                                    Text('Đang tải...', style: TextStyle(color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              error: (e, _) => TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Tỉnh/thành',
                                  prefixIcon: const Icon(Icons.location_on_outlined),
                                  hintText: 'Không thể tải danh sách',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.refresh_rounded),
                                    onPressed: () => ref.invalidate(_provincesProvider),
                                  ),
                                ),
                              ),
                              data: (provinces) {
                                // Tìm province hiện tại trong danh sách để khớp value
                                final currentMatch = _selectedProvinceName != null
                                    ? provinces.firstWhere(
                                        (p) => p['name'] == _selectedProvinceName,
                                        orElse: () => {},
                                      )
                                    : null;
                                final currentName = (currentMatch != null && currentMatch.isNotEmpty)
                                    ? currentMatch['name'] as String?
                                    : null;

                                return DropdownButtonFormField<String>(
                                  initialValue: currentName,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Tỉnh/thành',
                                    prefixIcon: Icon(Icons.location_on_outlined),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('-- Chọn tỉnh/thành --',
                                          style: TextStyle(color: AppColors.textSecondary)),
                                    ),
                                    ...provinces.map((p) {
                                      final name = p['name'] as String? ?? '';
                                      return DropdownMenuItem<String>(
                                        value: name,
                                        child: Text(name, overflow: TextOverflow.ellipsis),
                                      );
                                    }),
                                  ],
                                  onChanged: (v) => setState(() => _selectedProvinceName = v),
                                );
                              },
                            ),
                          ]),

                          const SizedBox(height: 16),

                          _card(children: [
                            _sectionLabel('Giới thiệu bản thân'),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _introCtrl,
                              maxLines: 3,
                              maxLength: 300,
                              decoration: const InputDecoration(
                                labelText: 'Giới thiệu (không bắt buộc)',
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(bottom: 40),
                                  child: Icon(Icons.notes_rounded),
                                ),
                                alignLabelWithHint: true,
                              ),
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
                                    color: AppColors.error.withValues(alpha: 0.3)),
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
                                padding: const EdgeInsets.symmetric(vertical: 16),
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
                                      'LƯU THÔNG TIN',
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
