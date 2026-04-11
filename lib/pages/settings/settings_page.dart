import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../components/fade_in_animation.dart';
import '../../models/app_user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/glass_container.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  bool _isUpdatingPhoto = false;
  bool _isRemovingPhoto = false;
  bool _isUpdatingName = false;

  void _log(String message) {
    debugPrint('PROFILE PHOTO SETTINGS UI: $message');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final profileState = ref.watch(userProfileProvider);
    final authUser = authState.value;
    final profile = profileState.asData?.value;
    final userName = _resolveDisplayName(profile, authUser?.displayName);
    final userEmail = _resolveEmail(profile, authUser?.email);
    final photoDataBase64 = _resolvePhotoDataBase64(profile);
    final photoUrl = _resolvePhotoUrl(profile, authUser?.photoURL);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isWebDesktop = kIsWeb && isDesktop;

    if (authState.isLoading && authUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          child: const SafeArea(
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: FadeInAnimation(
            child: Stack(
              children: [
                if (isWebDesktop) ...[
                  Positioned(
                    top: -120,
                    right: -40,
                    child: _buildAmbientGlow(
                      size: 320,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  Positioned(
                    left: -90,
                    bottom: -120,
                    child: _buildAmbientGlow(
                      size: 360,
                      colors: [
                        AppColors.accentOrange.withValues(alpha: 0.14),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ],
                isWebDesktop
                    ? _buildWebSettings(
                        context,
                        profile,
                        userName,
                        userEmail,
                        photoDataBase64,
                        photoUrl,
                      )
                    : _buildMobileSettings(
                        context,
                        profile,
                        userName,
                        userEmail,
                        photoDataBase64,
                        photoUrl,
                      ),
                if (profileState.hasError)
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.24),
                        ),
                      ),
                      child: const Text(
                        'Profile data is unavailable. Showing account info from auth.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebSettings(
    BuildContext context,
    AppUserProfile? profile,
    String userName,
    String userEmail,
    String? photoDataBase64,
    String? photoUrl,
  ) {
    final items = _buildAccountItems(
      userName,
      userEmail,
      photoDataBase64,
      photoUrl,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWebHeader(context),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildProfilePanel(
                      profile: profile,
                      userName: userName,
                      userEmail: userEmail,
                      photoDataBase64: photoDataBase64,
                      photoUrl: photoUrl,
                      compact: false,
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        _buildAccountPanel(items, crossAxisCount: 3),
                        const SizedBox(height: 18),
                        _buildSessionPanel(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSettings(
    BuildContext context,
    AppUserProfile? profile,
    String userName,
    String userEmail,
    String? photoDataBase64,
    String? photoUrl,
  ) {
    final items = _buildAccountItems(
      userName,
      userEmail,
      photoDataBase64,
      photoUrl,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildProfilePanel(
                profile: profile,
                userName: userName,
                userEmail: userEmail,
                photoDataBase64: photoDataBase64,
                photoUrl: photoUrl,
                compact: true,
              ),
              const SizedBox(height: 18),
              _buildAccountPanel(items, crossAxisCount: 1),
              const SizedBox(height: 18),
              _buildSessionPanel(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderBadge(
                icon: Icons.manage_accounts_rounded,
                label: 'Settings',
              ),
              const SizedBox(height: 14),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1.1,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 520,
                child: Text(
                  'Manage your account and profile photo.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.textSecondary.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
            padding: const EdgeInsets.all(18),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePanel({
    required AppUserProfile? profile,
    required String userName,
    required String userEmail,
    required String? photoDataBase64,
    required String? photoUrl,
    required bool compact,
  }) {
    final isBusy = _isUpdatingPhoto || _isRemovingPhoto;
    final subtitle = profile?.updatedAt != null
        ? 'Updated ${_formatDateTime(profile!.updatedAt!)}'
        : 'Profile ready';

    return GlassContainer(
      padding: EdgeInsets.all(compact ? 24 : 32),
      borderRadius: BorderRadius.circular(compact ? 28 : 36),
      opacity: 0.09,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact)
            Text(
              'Profile photo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          if (!compact) const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoActionAvatar(
                userName: userName,
                photoDataBase64: photoDataBase64,
                photoUrl: photoUrl,
                size: compact ? 92 : 112,
                onTap: isBusy ? null : _pickAndUploadProfilePhoto,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: compact ? 24 : 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.08,
                        letterSpacing: compact ? -0.4 : -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: compact ? 14 : 15,
                        height: 1.5,
                        color: AppColors.textSecondary.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload, replace, or remove your profile photo.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildPrimaryButton(
                        label: isBusy
                            ? 'Working...'
                            : ((photoDataBase64 == null && photoUrl == null)
                                  ? 'Add photo'
                                  : 'Change photo'),
                        onPressed: isBusy ? null : _pickAndUploadProfilePhoto,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSecondaryButton(
                        label: (photoDataBase64 != null || photoUrl != null)
                            ? (_isRemovingPhoto
                                  ? 'Removing...'
                                  : 'Remove photo')
                            : (_isUpdatingName ? 'Saving...' : 'Edit name'),
                        onPressed: (photoDataBase64 != null || photoUrl != null)
                            ? (_isRemovingPhoto ? null : _removeProfilePhoto)
                            : (_isUpdatingName
                                  ? null
                                  : () => _showEditNameDialog(userName)),
                      ),
                    ),
                  ],
                ),
                if (photoDataBase64 != null || photoUrl != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _isUpdatingName
                          ? null
                          : () => _showEditNameDialog(userName),
                      child: const Text('Edit name'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountPanel(
    List<_SettingsItem> items, {
    required int crossAxisCount,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(28),
      borderRadius: BorderRadius.circular(34),
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          if (crossAxisCount == 1)
            Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _buildDetailCard(items[i]),
                  if (i < items.length - 1) const SizedBox(height: 16),
                ],
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  Expanded(child: _buildDetailCard(items[i])),
                  if (i < items.length - 1) const SizedBox(width: 16),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSessionPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.red.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _showLogoutDialog,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.24)),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(_SettingsItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 18),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary.withValues(alpha: 0.74),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          if (item.actionLabel != null && item.onAction != null) ...[
            const SizedBox(height: 18),
            _buildTonalAction(
              label: item.actionLabel!,
              icon: Icons.arrow_forward_rounded,
              onPressed: item.onAction!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        backgroundColor: Colors.white.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildTonalAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildPhotoActionAvatar({
    required String userName,
    required String? photoDataBase64,
    required String? photoUrl,
    required double size,
    required VoidCallback? onTap,
  }) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: _buildAvatar(userName, photoDataBase64, photoUrl, size: size),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.edit_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: onTap == null ? 0.5 : 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(
    String userName,
    String? photoDataBase64,
    String? photoUrl, {
    double size = 100,
  }) {
    final imageProvider = _buildPhotoProvider(photoDataBase64, photoUrl);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageProvider == null ? AppColors.primaryGradient : null,
        image: imageProvider != null
            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
            : null,
      ),
      child: imageProvider == null
          ? Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeaderBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientGlow({
    required double size,
    required List<Color> colors,
  }) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }

  String _resolveDisplayName(AppUserProfile? profile, String? authDisplayName) {
    final profileName = profile?.displayName.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;

    final fallback = authDisplayName?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return 'User';
  }

  String _resolveEmail(AppUserProfile? profile, String? authEmail) {
    final email = profile?.email.trim();
    if (email != null && email.isNotEmpty) return email;
    return authEmail?.trim().isNotEmpty == true
        ? authEmail!.trim()
        : 'No email available';
  }

  String? _resolvePhotoUrl(AppUserProfile? profile, String? authPhotoUrl) {
    final photo = profile?.photoUrl?.trim();
    if (photo != null && photo.isNotEmpty) return photo;
    final fallback = authPhotoUrl?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  String? _resolvePhotoDataBase64(AppUserProfile? profile) {
    final data = profile?.photoDataBase64?.trim();
    if (data != null && data.isNotEmpty) return data;
    return null;
  }

  ImageProvider<Object>? _buildPhotoProvider(
    String? photoDataBase64,
    String? photoUrl,
  ) {
    if (photoDataBase64 != null && photoDataBase64.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(photoDataBase64));
      } catch (e) {
        _log('photo decode failed error=$e');
      }
    }

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return NetworkImage(photoUrl);
    }

    return null;
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} $hour:$minute $suffix';
  }

  List<_SettingsItem> _buildAccountItems(
    String userName,
    String userEmail,
    String? photoDataBase64,
    String? photoUrl,
  ) {
    return [
      _SettingsItem(
        icon: Icons.badge_rounded,
        title: 'Display name',
        value: userName,
        actionLabel: _isUpdatingName ? 'Saving...' : 'Edit',
        onAction: _isUpdatingName ? null : () => _showEditNameDialog(userName),
      ),
      _SettingsItem(
        icon: Icons.mail_outline_rounded,
        title: 'Email',
        value: userEmail,
      ),
      _SettingsItem(
        icon: Icons.photo_library_outlined,
        title: 'Profile photo',
        value: (photoDataBase64 == null && photoUrl == null)
            ? 'Not set'
            : photoDataBase64 != null
            ? 'Embedded'
            : 'Configured',
        actionLabel: _isUpdatingPhoto || _isRemovingPhoto
            ? 'Working...'
            : 'Change',
        onAction: _isUpdatingPhoto || _isRemovingPhoto
            ? null
            : _pickAndUploadProfilePhoto,
      ),
    ];
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    _log('direct photo pick start');
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (file == null) {
        _log('direct photo pick cancelled');
        return;
      }

      _log('direct photo pick success fileName=${file.name}');
      await _uploadProfilePhoto(file);
    } catch (e, stackTrace) {
      _log('direct photo pick error error=$e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showSnackBar('Failed to choose photo', error: true);
    }
  }

  void _showEditNameDialog(String currentName) {
    _nameController.text = currentName;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Edit name',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              autofocus: true,
              enabled: !isLoading,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name cannot be empty';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;

                      final navigator = Navigator.of(dialogContext);
                      final newName = _nameController.text.trim();

                      setDialogState(() => isLoading = true);
                      setState(() => _isUpdatingName = true);

                      try {
                        await ref
                            .read(authControllerProvider.notifier)
                            .updateDisplayName(newName);
                        ref.invalidate(authStateProvider);
                        ref.invalidate(userProfileProvider);

                        if (!mounted) return;
                        navigator.pop();
                        _showSnackBar('Name updated');
                      } catch (_) {
                        if (!mounted) return;
                        _showSnackBar('Failed to update name', error: true);
                      } finally {
                        if (mounted) {
                          setDialogState(() => isLoading = false);
                          setState(() => _isUpdatingName = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProfilePhoto(XFile imageFile) async {
    final authUser = ref.read(authStateProvider).value;
    if (authUser == null) {
      _log('upload aborted no auth user');
      return;
    }

    _log(
      'upload start userId=${authUser.uid} fileName=${imageFile.name} filePath=${imageFile.path}',
    );
    setState(() => _isUpdatingPhoto = true);

    try {
      _log('photo processing start userId=${authUser.uid}');
      final processedBytes = await _prepareProfilePhotoBytes(
        imageFile,
      ).timeout(const Duration(seconds: 20));
      final photoDataBase64 = base64Encode(processedBytes);
      _log(
        'photo processing complete userId=${authUser.uid} processedBytes=${processedBytes.length} base64Length=${photoDataBase64.length}',
      );
      _log('embedded photo firestore sync start userId=${authUser.uid}');
      await ref
          .read(authControllerProvider.notifier)
          .updateEmbeddedProfilePhoto(
            photoDataBase64: photoDataBase64,
            photoMimeType: 'image/png',
          )
          .timeout(const Duration(seconds: 12));
      _log('embedded photo firestore sync complete userId=${authUser.uid}');
      ref.invalidate(userProfileProvider);
      _log('userProfileProvider invalidated after upload');
      if (!mounted) return;
      _showSnackBar('Profile photo updated');
    } catch (e) {
      _log(
        'upload error userId=${authUser.uid} errorType=${e.runtimeType} error=$e',
      );
      if (!mounted) return;
      _showSnackBar(
        e is TimeoutException
            ? 'Photo save timed out'
            : 'Failed to upload photo',
        error: true,
      );
    } finally {
      if (mounted) {
        _log('upload end resetting busy state');
        setState(() => _isUpdatingPhoto = false);
      }
    }
  }

  Future<void> _removeProfilePhoto() async {
    final authUser = ref.read(authStateProvider).value;
    if (authUser == null) {
      _log('remove aborted no auth user');
      return;
    }

    _log('remove start userId=${authUser.uid}');
    setState(() => _isRemovingPhoto = true);

    try {
      _log('remove firestore sync start userId=${authUser.uid}');
      await ref
          .read(authControllerProvider.notifier)
          .clearProfilePhoto()
          .timeout(const Duration(seconds: 8));
      _log('remove firestore sync complete userId=${authUser.uid}');
      ref.invalidate(userProfileProvider);
      _log('userProfileProvider invalidated after remove');
      if (!mounted) return;
      _showSnackBar('Profile photo removed');
    } catch (e) {
      _log(
        'remove error userId=${authUser.uid} errorType=${e.runtimeType} error=$e',
      );
      if (!mounted) return;
      _showSnackBar(
        e is TimeoutException
            ? 'Photo removal timed out'
            : 'Failed to remove photo',
        error: true,
      );
    } finally {
      if (mounted) {
        _log('remove end resetting busy state');
        setState(() => _isRemovingPhoto = false);
      }
    }
  }

  void _showSnackBar(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<Uint8List> _prepareProfilePhotoBytes(XFile imageFile) async {
    final originalBytes = await imageFile.readAsBytes();
    _log('photo processing decode start originalBytes=${originalBytes.length}');
    final codec = await ui.instantiateImageCodec(
      originalBytes,
      targetWidth: 256,
      targetHeight: 256,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw StateError('Could not encode processed image bytes');
    }
    return byteData.buffer.asUint8List();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.value,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? actionLabel;
  final VoidCallback? onAction;
}
