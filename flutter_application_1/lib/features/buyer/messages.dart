import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/buyer/chat.dart';
import 'package:flutter_application_1/features/buyer/mock_data.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

/// Bandeja de entrada del comprador con conversaciones simuladas.
class BuyerMessages extends StatefulWidget {
  const BuyerMessages({super.key});

  @override
  State<BuyerMessages> createState() => _BuyerMessagesState();
}

class _BuyerMessagesState extends State<BuyerMessages> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      appBar: AppBar(
        backgroundColor: AppColors.blackGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Mensajes', style: AppText.appBarText),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.phone_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: mockConversations.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          thickness: 1,
          color: AppColors.dark.withValues(alpha: 0.06),
        ),
        itemBuilder: (context, index) {
          final c = mockConversations[index];
          return InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BuyerChat(conversation: c),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md + AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF3E6),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        c.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          c.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTints.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        c.time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: c.unread > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: c.unread > 0
                              ? AppColors.blackGreen
                              : AppTints.muted,
                        ),
                      ),
                      if (c.unread > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.blackGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${c.unread}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
