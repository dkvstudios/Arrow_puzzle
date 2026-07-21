import 'package:in_app_update/in_app_update.dart';
import 'package:flutter/material.dart';

/// Service to handle in-app updates from Play Store
class UpdateService {
  static final UpdateService instance = UpdateService._internal();
  UpdateService._internal();

  /// Check for updates and show Play Store update bottomsheet if available
  Future<void> checkForUpdate(BuildContext context) async {
    try {
      // Check if update is available
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // If immediate update is available (critical update)
        if (updateInfo.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        }
        // If flexible update is available (optional update)
        else if (updateInfo.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          
          // Listen for download completion
          InAppUpdate.completeFlexibleUpdate().then((_) {
            _showUpdateCompletedSnackbar(context);
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      // Silently fail - don't show error to user
    }
  }

  /// Show snackbar when flexible update is downloaded and ready to install
  void _showUpdateCompletedSnackbar(BuildContext context) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Update downloaded! Restart app to install.'),
        action: SnackBarAction(
          label: 'RESTART',
          onPressed: () {
            InAppUpdate.completeFlexibleUpdate();
          },
        ),
        duration: const Duration(seconds: 10),
      ),
    );
  }
}
