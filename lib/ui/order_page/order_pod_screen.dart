import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:konek2move/widgets/custom_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/utils/app_colors.dart';

Future<bool?> showProofOfDeliveryBottomSheet(
    BuildContext context, {
      required String orderNo,
      required String customerName,
    }) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PODSheet(
      orderNo: orderNo,
      customerName: customerName,
    ),
  );
}
class PODSheet extends StatefulWidget {
  final String orderNo;
  final String customerName;

  const PODSheet({
    super.key,
    required this.orderNo,
    required this.customerName,
  });

  @override
  State<PODSheet> createState() => _PODSheetState();
}

class _PODSheetState extends State<PODSheet> {
  final _picker = ImagePicker();

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  File? _photo;
  File? _signatureFile;
  bool _isSending = false;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  // ───────────────── PHOTO ─────────────────
  Future<void> _takePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1280,
      );

      if (image != null && mounted) {
        setState(() => _photo = File(image.path));
      }
    } catch (_) {
      // Show custom dialog instead of toast
      if (!mounted) return;
      await showCustomDialog(
        context: context,
        title: "Camera Error",
        message: "Failed to open camera. Please try again.",
        icon: Icons.error_outline,
        color: Colors.red,
        buttonText: "Okay!",
      );
    }
  }
  // ───────────────── SIGNATURE ─────────────────
  Future<void> _showSignatureDialog() async {
    _signatureController.clear();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.of(context).size.height * .6,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),

                const Text(
                  "Recipient Signature",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 14),

                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Signature(
                      controller: _signatureController,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _signatureController.clear,
                        child: const Text("Clear"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_signatureController.isEmpty) return;

                          final file = await _convertSignatureToFile();
                          if (!mounted) return;

                          setState(() => _signatureFile = file);
                          Navigator.pop(context);
                        },
                        child: const Text("Save Signature"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<File> _convertSignatureToFile() async {
    final bytes = await _signatureController.toPngBytes();
    final dir = await getTemporaryDirectory();
    final path =
        "${dir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png";
    return File(path).writeAsBytes(bytes!);
  }

  // ───────────────── SUBMIT ─────────────────
  Future<void> _submitPOD() async {
    if (_photo == null || _signatureFile == null) return;

    setState(() => _isSending = true);

    try {
      final api = ApiServices();
      final response = await api.uploadProofOfDelivery(
        orderNo: widget.orderNo,
        recipientName: widget.customerName,
        photoItem: _photo!,
        signature: _signatureFile!,
      );

      if (!mounted) return;

      final isSuccess = response.retCode == "200";

      setState(() => _isSending = false);

      await showCustomDialog(
        context: context,
        title: isSuccess ? "Success" : "Failed",
        message: isSuccess ? response.message! : response.error!,
        icon: isSuccess ? Icons.check_circle_rounded : Icons.error_outline,
        color: isSuccess ? AppColors.primary : Colors.red,
        buttonText: "Okay!",
      );

      // ✅ If success, close the bottom sheet and return true
      if (isSuccess && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSending = false);

      await showCustomDialog(
        context: context,
        title: "Failed",
        message: "Something went wrong. Please try again.",
        icon: Icons.error_outline,
        color: Colors.red,
        buttonText: "Okay!",
      );
    }
  }









  // ───────────────── UI ─────────────────
  @override
  Widget build(BuildContext context) {
    final isReady = _photo != null && _signatureFile != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Drag handle
              Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(.25),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),

              /// ── Title + Info Card ──
              const Text(
                "Submit Proof of Delivery",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Upload required proof to confirm this order has been delivered.",
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rowInfo("Order No", widget.orderNo),
                    const SizedBox(height: 6),
                    _rowInfo("Customer", widget.customerName),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _buildUploadSection(
                title: "Package Photo",
                subtitle: "Clear photo of the delivered package",
                imageFile: _photo,
                onTap: _takePhoto,
                isSignature: false,
              ),

              const SizedBox(height: 18),

              _buildUploadSection(
                title: "Recipient Signature",
                subtitle: "Capture recipient’s digital signature",
                imageFile: _signatureFile,
                onTap: _showSignatureDialog,
                isSignature: true,
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (!isReady || _isSending) ? null : _submitPOD,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(.4),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSending
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Submitting...",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                      : const Text(
                    "Submit Proof of Delivery",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── HELPERS ─────────────────
  Widget _rowInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection({
    required String title,
    required String subtitle,
    required File? imageFile,
    required VoidCallback onTap,
    required bool isSignature,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style:
                  const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: imageFile == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSignature
                      ? Icons.edit_outlined
                      : Icons.add_a_photo_outlined,
                  color: Colors.grey,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  isSignature ? "Sign" : "Upload",
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12),
                ),
              ],
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(imageFile, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }
}




