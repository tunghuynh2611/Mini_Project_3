import 'dart:io';
import 'package:flutter/material.dart';

/// Modal dialog allowing user to pinch-zoom and inspect the scanned receipt.
class ReceiptPreviewDialog extends StatelessWidget {
  final String imagePath;
  final String? rawText;

  const ReceiptPreviewDialog({
    super.key,
    required this.imagePath,
    this.rawText,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = imagePath.isNotEmpty && File(imagePath).existsSync();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: hasFile
                  ? InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB), // Receipt thermal paper style
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          rawText?.isNotEmpty == true
                              ? rawText!
                              : 'No image or text available for preview.',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF1E293B),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.6),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

