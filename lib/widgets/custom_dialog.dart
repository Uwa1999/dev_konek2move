// import 'package:flutter/material.dart';
//
// Future<void> showCustomDialog({
//   required BuildContext context,
//   required String title,
//   required String message,
//   required IconData icon,
//   required Color color,
//   required String buttonText,
//   Future<void> Function()? onButtonPressed,
// }) async {
//   bool dialogClosed = false;
//
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     barrierColor: Colors.black.withOpacity(0.45),
//     builder: (dialogContext) {
//       bool isLoading = false;
//
//       return StatefulBuilder(
//         builder: (_, setDialogState) {
//           void safeSetState(VoidCallback fn) {
//             if (!dialogClosed) setDialogState(fn);
//           }
//
//           return Dialog(
//             elevation: 10,
//             insetPadding: const EdgeInsets.symmetric(horizontal: 28),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(24),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // ICON
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: color.withOpacity(0.12),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(icon, size: 42, color: color),
//                   ),
//
//                   const SizedBox(height: 18),
//
//                   // TITLE
//                   Text(
//                     title,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//
//                   const SizedBox(height: 10),
//
//                   // MESSAGE
//                   Text(
//                     message,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.grey.shade700,
//                       fontSize: 15,
//                       height: 1.5,
//                     ),
//                   ),
//
//                   const SizedBox(height: 24),
//
//                   // BUTTON
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: color,
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(28),
//                         ),
//                       ),
//                       onPressed: isLoading
//                           ? null
//                           : () async {
//                         if (onButtonPressed == null) return;
//
//                         safeSetState(() => isLoading = true);
//                         await onButtonPressed();
//                         safeSetState(() => isLoading = false);
//                       },
//                       child: isLoading
//                           ? const SizedBox(
//                         width: 18,
//                         height: 18,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       )
//                           : Text(
//                         buttonText,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w700,
//                           color: Colors.white,
//                           fontSize: 15.5,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );
//     },
//   ).then((_) => dialogClosed = true);
// }
import 'package:flutter/material.dart';

Future<void> showCustomDialog({
  required BuildContext context,
  required String title,
  required String message,
  required IconData icon,
  required Color color,
  required String buttonText,
  Future<void> Function()? onButtonPressed,
}) async {
  bool dialogClosed = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (dialogContext) {
      bool isLoading = false;

      return StatefulBuilder(
        builder: (_, setDialogState) {
          void safeSetState(VoidCallback fn) {
            if (!dialogClosed) setDialogState(fn);
          }

          return Dialog(
            elevation: 10,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ICON
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 42, color: color),
                  ),

                  const SizedBox(height: 18),

                  // TITLE
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // MESSAGE
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () async {
                        if (onButtonPressed != null) {
                          safeSetState(() => isLoading = true);

                          await onButtonPressed();

                          safeSetState(() => isLoading = false);
                        }

                        // always close the dialog
                        if (!dialogClosed) {
                          Navigator.of(dialogContext).pop();
                          dialogClosed = true;
                        }
                      },
                      child: (onButtonPressed != null && isLoading)
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              buttonText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 15.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ).then((_) => dialogClosed = true);
}
