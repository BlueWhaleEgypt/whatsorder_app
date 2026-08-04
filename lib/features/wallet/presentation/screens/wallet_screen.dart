import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/utils/payment_session_storage.dart';
import 'package:whats_order/features/auth/sign_in/data/user_model.dart';
import 'package:whats_order/features/wallet/data/payment_checkout_request.dart';
import 'package:whats_order/features/wallet/data/transaction_model.dart';
import 'package:whats_order/features/wallet/data/wallet_response.dart';
import 'package:whats_order/features/wallet/presentation/bloc/transaction_bloc.dart';
import 'package:whats_order/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:whats_order/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:whats_order/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:whats_order/features/wallet/presentation/screens/payment_web_view_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/*
|--------------------------------------------------------------------------
| WalletScreen — "Your Wallet" tab.
|
| Now wired to the Kashier payment flow:
|   1) User taps "Top up" -> shows an amount dialog.
|   2) StartCheckoutEvent -> WalletBloc calls /payment/checkout and emits
|      CheckoutUrlReadyState(paymentUrl).
|   3) We open PaymentWebViewScreen; it intercepts the whatsorder:// redirect
|      and pops with the resulting Uri.
|   4) _handlePaymentReturn reads paymentStatus + the saved sessionId/walletId
|      and fires ConfirmPaymentEvent -> POST /payment/addPaymentToMyWallet.
|   5) On PaymentConfirmedState we refresh the wallet + transactions.
|--------------------------------------------------------------------------
*/
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ScrollController _controller = ScrollController();
  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      if (_controller.position.pixels >=
          _controller.position.maxScrollExtent - 150) {
        context.read<TransactionBloc>().add(
          const GetTransactionsEvent(loadMore: true),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr("your_wallet"), style: AppTextStyles.heading18),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: BlocListener<WalletBloc, WalletState>(
          listener: (context, state) async {
            if (state is CheckoutUrlReadyState) {
              final resultUri = await Navigator.of(context).push<Uri>(
                MaterialPageRoute(
                  builder: (_) =>
                      PaymentWebViewScreen(paymentUrl: state.paymentUrl),
                ),
              );

              if (!context.mounted) return;

              if (resultUri != null) {
                await _handlePaymentReturn(context, resultUri);
              } else {
                // المستخدم قفل شاشة الدفع يدويًا قبل ما يوصل للـ redirect
                await PaymentSessionStorage.clear();
              }
            } else if (state is PaymentConfirmedState) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr("payment_successful"))),
              );
              context.read<TransactionBloc>().add(const GetTransactionsEvent());
            } else if (state is PaymentFailedState) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          child: RefreshIndicator(
            color: AppColors.primaryGreen,
            onRefresh: () async {
              context.read<WalletBloc>().add(GetWalletEvent());
              context.read<TransactionBloc>().add(const GetTransactionsEvent());
            },
            child: BlocBuilder<WalletBloc, WalletState>(
              builder: (context, state) {
                if (state is WalletLoadingState) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(
                        height: 500,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  );
                }

                if (state is WalletErrorState) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 500,
                        child: Center(child: Text(context.tr(state.message))),
                      ),
                    ],
                  );
                }

                if (state is WalletLoadedState) {
                  return ListView(
                    controller: _controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      bottom: 30,
                      left: 16,
                      right: 16,
                    ),
                    children: [
                      _BalanceCard(
                        wallet: state.response,
                        onTopUp: () => _showTopUpDialog(context),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.tr("recent_activity"),
                        style: AppTextStyles.sectionLabel13,
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<TransactionBloc, TransactionState>(
                        builder: (context, state) {
                          if (state is TransactionLoadingState) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (state is TransactionErrorState) {
                            return Center(
                              child: Text(context.tr(state.message)),
                            );
                          }

                          if (state is TransactionLoadedState) {
                            if (state.response.content.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(context.tr("no_transactions")),
                                ),
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 110),
                              itemCount:
                                  state.response.content.length +
                                  (state.hasReachedEnd ? 0 : 1),
                              itemBuilder: (context, index) {
                                if (index == state.response.content.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                return _ActivityTile(
                                  transaction: state.response.content[index],
                                );
                              },
                            );
                            // return Column(
                            //   children: state.response.content
                            //       .map((e) =>

                            //       _ActivityTile(transaction: e))
                            //       .toList(),
                            // );
                          }

                          return const SizedBox();
                        },
                      ),
                    ],
                  );
                }

                return ListView(physics: const AlwaysScrollableScrollPhysics());
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTopUpDialog(BuildContext context) async {
    final controller = TextEditingController();
    final walletBloc = context.read<WalletBloc>();
    final amount = await showDialog<num>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(context.tr("top_up")),
              content: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: context.tr("enter_amount"),
                  errorText:
                      controller.text.isNotEmpty &&
                          (double.tryParse(controller.text) ?? 0) < 250
                      ? context.tr("less_than_250")
                      : null,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(context.tr("cancel")),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = num.tryParse(controller.text.trim());

                    if (value == null || value < 250) {
                      setState(() {}); // لإظهار رسالة الخطأ
                      return;
                    }

                    Navigator.pop(dialogContext, value);
                  },
                  child: Text(context.tr("confirm")),
                ),
              ],
            );
          },
        );
      },
    );

    if (amount == null || amount <= 0) return;
    if (!context.mounted) return;

    await _startTopUp(walletBloc, amount);
  }

  Future<void> _startTopUp(WalletBloc walletBloc, num amount) async {
    final order = 'WLT-${DateTime.now().millisecondsSinceEpoch}';
    final user = UserModel.fromJson(
      jsonDecode(
        CacheHelper.getDataFromSharedPreference(key: CacheKeys.userModel) ??
            '{}',
      ),
    );

    final request = PaymentCheckoutRequest(
      amount: amount,
      currency: 'EGP',
      order: order,
      customerEmail: user.email ?? '',
      redirectUrl: "https://whatsorder.shop/payment/success",
      webhookUrl: "https://whatsorder.shop/payment/success",
    );

    walletBloc.add(StartCheckoutEvent(request));
  }

  Future<void> _handlePaymentReturn(BuildContext context, Uri uri) async {
    final status = uri.queryParameters['paymentStatus'];
    final sessionId = await PaymentSessionStorage.readSessionId();
    final walletId = await PaymentSessionStorage.readWalletId();

    if (!context.mounted) return;

    if (status == 'SUCCESS' && sessionId != null && walletId != null) {
      // ملحوظة مهمة: paymentStatus=SUCCESS مش دليل نهائي، لازم نستدعي التأكيد دايمًا
      context.read<WalletBloc>().add(
        ConfirmPaymentEvent(sessionId: sessionId, walletId: walletId),
      );
    } else {
      // إلغاء أو فشل أو مفيش session محفوظة -> امسح أي حالة معلقة
      await PaymentSessionStorage.clear();
      if (status != null && status != 'SUCCESS') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr("payment_cancelled_or_failed"))),
        );
      }
    }
  }
}

class _BalanceCard extends StatelessWidget {
  final WalletResponse wallet;
  final VoidCallback onTopUp;

  const _BalanceCard({required this.wallet, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr("total_balance"),
            style: AppTextStyles.cellMuted13.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "${wallet.balance ?? 0} EGP",
            style: AppTextStyles.sectionLabel13.copyWith(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            wallet.user?.firstName ?? "",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryGreen,
                  ),
                  onPressed: onTopUp,
                  child: Text(context.tr("top_up")),
                ),
              ),
              const SizedBox(width: 12),
              // Expanded(
              //   child: OutlinedButton(
              //     style: OutlinedButton.styleFrom(
              //       foregroundColor: Colors.white,
              //       side: const BorderSide(color: Colors.white54),
              //     ),
              //     onPressed: () {},
              //     child: const Text("Withdraw"),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final TransactionModel transaction;

  const _ActivityTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == "PUSH";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.primaryGreen : AppColors.danger)
                  .withOpacity(.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? AppColors.primaryGreen : AppColors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCredit ? "Deposit" : "Withdrawal",
              style: AppTextStyles.cardTitle15,
            ),
          ),
          Text(
            "${isCredit ? "+" : "-"}${transaction.money ?? 0} EGP",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCredit ? AppColors.primaryGreen : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
