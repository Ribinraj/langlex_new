import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/api_exception.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/payments/payment_repo.dart';

class PaymentCheckoutPage extends StatefulWidget {
  const PaymentCheckoutPage({
    super.key,
    required this.plans,
    required this.homeLanguage,
  });

  final List<SubscriptionPlan> plans;
  final String homeLanguage;

  @override
  State<PaymentCheckoutPage> createState() => _PaymentCheckoutPageState();
}

class _PaymentCheckoutPageState extends State<PaymentCheckoutPage> {
  SubscriptionPlan? _selectedPlan;
  bool _loading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final paidPlans = widget.plans
        .where((plan) => plan.type.toLowerCase() != 'free')
        .toList();
    if (paidPlans.isNotEmpty) {
      _selectedPlan = paidPlans.first;
    } else if (widget.plans.isNotEmpty) {
      _selectedPlan = widget.plans.first;
    }
  }

  Future<void> _pay() async {
    final plan = _selectedPlan;
    if (plan == null || _loading) return;
    final t = AppLocalizations(widget.homeLanguage);

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final paymentRepository = context.read<PaymentRepository>();
      final created = await paymentRepository.createOrder(planId: plan.id);
      final order = created['order'] as Map<String, dynamic>? ?? {};
      final orderId = int.tryParse(order['id']?.toString() ?? '') ?? 0;
      await Future<void>.delayed(const Duration(milliseconds: 450));
      await paymentRepository.verifyPayment(orderId: orderId);

      if (!mounted) return;
      setState(() => _message = t.dummyPaymentComplete);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t.subscriptionActivated)));
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paidPlans = widget.plans
        .where((plan) => plan.type.toLowerCase() != 'free')
        .toList();
    final t = AppLocalizations(widget.homeLanguage);

    return Scaffold(
      backgroundColor: Appcolors.kscreenWarmBackground,
      appBar: AppBar(title: Text(t.upgradePlanPage)),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.pagePadding(
          context,
          mobileHorizontalPercent: 6,
          tabletHorizontal: 42,
          desktopHorizontal: 56,
          top: 14,
          bottom: 36,
        ),
        child: ResponsiveUtils.constrainWidth(
          context: context,
          maxWidth: 680,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                t.chooseLearningPlan,
                fontSize: 26,
                weight: FontWeight.w900,
                color: Appcolors.ktextdark,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: 8),
              ResponsiveText(
                t.dummyCheckoutMessage,
                fontSize: 13,
                weight: FontWeight.w700,
                color: Appcolors.kdashboardMutedText,
                overflow: TextOverflow.visible,
              ),
              ResponsiveSizedBox.height(2.4),
              if (paidPlans.isEmpty)
                _CheckoutStatus(message: t.noPaidPlans)
              else
                for (final plan in paidPlans) ...[
                  _PlanCard(
                    plan: plan,
                    t: t,
                    selected: _selectedPlan?.id == plan.id,
                    onTap: () => setState(() => _selectedPlan = plan),
                  ),
                  const SizedBox(height: 12),
                ],
              ResponsiveSizedBox.height(1.2),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading || _selectedPlan == null ? null : _pay,
                  icon: Icon(
                    _loading
                        ? Icons.hourglass_top_rounded
                        : Icons.lock_open_rounded,
                  ),
                  label: Text(_loading ? t.processing : t.payWithDummy),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 14),
                _CheckoutStatus(message: _message!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.t,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final AppLocalizations t;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Appcolors.ktransparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Appcolors.kwhitecolor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? Appcolors.kprimarycolor
                  : Appcolors.kauthDivider,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Appcolors.kmetricInventorySurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Appcolors.kmetricInventory,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      plan.name,
                      fontSize: 16,
                      weight: FontWeight.w900,
                      color: Appcolors.ktextdark,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 4),
                    ResponsiveText(
                      t.periodAmount(plan.period, plan.amount),
                      fontSize: 12.5,
                      weight: FontWeight.w700,
                      color: Appcolors.kdashboardMutedText,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? Appcolors.kprimarycolor
                    : Appcolors.kdashboardMutedIcon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutStatus extends StatelessWidget {
  const _CheckoutStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Appcolors.ksoftPrimarySurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ResponsiveText(
        message,
        fontSize: 13,
        weight: FontWeight.w800,
        color: Appcolors.kprimarycolor,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
