import 'package:flutter/material.dart';

class CartResetDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const CartResetDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: 323,
        height: 186,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3E8),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 16, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "다른 매장의 상품이 이미 담겨 있습니다.\n장바구니를 비우고 현재 상품을 담으시겠습니까?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF676C5A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(
                        label: "예",
                        backgroundColor: const Color(0xFF4FA55B),
                        textColor: Colors.white,
                        onTap: onConfirm,
                      ),
                      const SizedBox(width: 11),
                      _buildButton(
                        label: "아니오",
                        backgroundColor: Colors.transparent,
                        textColor: const Color(0xFFB3BA9F),
                        borderColor: const Color(0xFFB3BA9F),
                        onTap: onCancel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 15,
              right: 20,
              child: GestureDetector(
                onTap: onCancel,
                child: const Icon(Icons.close, size: 18, color: Color(0xFFB3BA9F)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 134,
        height: 37,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}