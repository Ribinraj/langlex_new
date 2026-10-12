import 'package:langlex_new_app/core/app_toast.dart';
import 'package:langlex_new_app/features/dashboard/widgets/flow_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/api_exception.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/authentication/auth_repo.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_bloc.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_event.dart';
import 'package:langlex_new_app/features/authentication/models/app_user.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.user,
    required this.homeLanguage,
  });

  final AppUser user;
  final String homeLanguage;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _schoolController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  bool _saving = false;

  AppLocalizations get t => AppLocalizations(widget.homeLanguage);

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _fullNameController = TextEditingController(text: user.fullName);
    _mobileController = TextEditingController(text: user.mobileNumber);
    _emailController = TextEditingController(text: user.email ?? '');
    _schoolController = TextEditingController(text: user.school ?? '');
    _cityController = TextEditingController(text: user.city ?? '');
    _stateController = TextEditingController(text: user.state ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final user = await context.read<AuthRepository>().updateProfile(
        fullName: _fullNameController.text,
        email: _emailController.text,
        school: _schoolController.text,
        city: _cityController.text,
        state: _stateController.text,
      );

      if (!mounted) return;
      context.read<AuthBloc>().add(UserChangedEvent(user));
      AppToast.success(context, t.profileUpdated);
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      AppToast.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, t.couldNotUpdateProfile);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.kscreenWarmBackground,

      bottomNavigationBar: _SaveProfileBar(
        label: _saving ? t.saving : t.saveChanges,
        saving: _saving,
        onSave: _saving ? null : _save,
      ),
      body: FlowScrollView(
        header: FlowPageHeader(title: t.editProfile),
        padding: ResponsiveUtils.pagePadding(
          context,
          mobileHorizontalPercent: 6,
          tabletHorizontal: 42,
          desktopHorizontal: 56,
          top: 12,
          bottom: 112,
        ),
        child: ResponsiveUtils.constrainWidth(
          context: context,
          maxWidth: 680,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  t.editProfileSubtitle,
                  fontSize: 14,
                  weight: FontWeight.w700,
                  color: Appcolors.kdashboardMutedText,
                  overflow: TextOverflow.visible,
                ),
                ResponsiveSizedBox.height(2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Appcolors.kwhitecolor.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Appcolors.kauthDivider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        t.accountDetails,
                        fontSize: 16,
                        weight: FontWeight.w800,
                        color: Appcolors.ktextdark,
                        overflow: TextOverflow.visible,
                      ),
                      ResponsiveSizedBox.height(1.6),
                      _ProfileTextField(
                        controller: _fullNameController,
                        label: t.fullName,
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if ((value ?? '').trim().length < 2) {
                            return t.fullNameRequired;
                          }
                          return null;
                        },
                      ),
                      ResponsiveSizedBox.height(1.4),
                      _ProfileTextField(
                        controller: _mobileController,
                        label: t.mobileNumber,
                        icon: Icons.phone_outlined,
                        enabled: false,
                        helperText: t.mobileCannotBeChanged,
                      ),
                      ResponsiveSizedBox.height(1.4),
                      _ProfileTextField(
                        controller: _emailController,
                        label: t.email,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = (value ?? '').trim();
                          if (email.isEmpty) return null;
                          final isValid = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email);
                          return isValid ? null : t.invalidEmail;
                        },
                      ),
                      ResponsiveSizedBox.height(1.4),
                      _ProfileTextField(
                        controller: _schoolController,
                        label: t.school,
                        icon: Icons.school_outlined,
                        textCapitalization: TextCapitalization.words,
                      ),
                      ResponsiveSizedBox.height(1.4),
                      _ProfileTextField(
                        controller: _cityController,
                        label: t.city,
                        icon: Icons.location_city_outlined,
                        textCapitalization: TextCapitalization.words,
                      ),
                      ResponsiveSizedBox.height(1.4),
                      _ProfileTextField(
                        controller: _stateController,
                        label: t.state,
                        icon: Icons.map_outlined,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.helperText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: enabled
            ? Appcolors.kwhitecolor
            : Appcolors.ksoftPrimarySurface.withValues(alpha: 0.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Appcolors.kauthDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Appcolors.kauthDivider),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Appcolors.kauthDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Appcolors.kprimarycolor,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _SaveProfileBar extends StatelessWidget {
  const _SaveProfileBar({
    required this.label,
    required this.saving,
    required this.onSave,
  });

  final String label;
  final bool saving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.isMobile(context) ? 20.0 : 42.0;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Appcolors.kscreenWarmBackground.withValues(alpha: 0.97),
          border: Border(
            top: BorderSide(
              color: Appcolors.kprimarycolor.withValues(alpha: 0.08),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Appcolors.ktextdark.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            10,
            horizontalPadding,
            12,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSave,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(label),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
