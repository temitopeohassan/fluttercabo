import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';
import '../format.dart';
import '../theme.dart';
import 'common.dart';
import 'live.dart';

enum DocStatus { approved, review, needed, rejected, expiring }

/// Every document Cabo can ask a host for: label, hint and icon by type.
const documentTypes = <String, (String, String, IconData)>{
  'drivers_licence': ("Driver's licence", 'A clear photo of the front', Icons.badge_outlined),
  'national_id': ('National ID (NIN)', 'NIN slip or card', Icons.perm_identity_rounded),
  'proof_of_address': ('Proof of address', 'Utility bill from the last 3 months • optional', Icons.home_work_outlined),
  'lasdri_card': ('LASDRI card', 'Lagos State Drivers Institute', Icons.credit_card_rounded),
  'state_permit': ('State permit', 'Optional • e.g. hackney permit', Icons.verified_outlined),
  'vehicle_licence': ('Vehicle licence', 'Must be valid for 30 more days', Icons.directions_car_outlined),
  'roadworthiness': ('Roadworthiness certificate', 'Must be valid for 30 more days', Icons.build_circle_outlined),
  'insurance': ('Insurance certificate', 'Third party or comprehensive', Icons.shield_outlined),
  'vehicle_photo': ('Vehicle photo', 'Front of the car with the plate visible', Icons.directions_car_filled_rounded),
  'selfie': ('Selfie', 'Your face, in good light', Icons.face_retouching_natural_rounded),
};

const personalDocuments = ['drivers_licence', 'national_id', 'lasdri_card', 'proof_of_address', 'state_permit'];
const vehicleDocuments = ['vehicle_licence', 'roadworthiness', 'insurance'];

/// The documents Cabo needs before an application can be submitted.
const requiredDocuments = ['drivers_licence', 'national_id', 'lasdri_card', 'vehicle_licence', 'roadworthiness', 'insurance'];

DocStatus docStatus(Json? doc) {
  if (doc == null) return DocStatus.needed;
  final expires = doc.date('expires_at');
  if (doc.str('status') == 'rejected') return DocStatus.rejected;
  if (expires != null && expires.isBefore(DateTime.now().add(const Duration(days: 30)))) return DocStatus.expiring;
  return doc.str('status') == 'approved' ? DocStatus.approved : DocStatus.review;
}

String docSubtitle(String type, Json? doc) {
  if (doc == null) return documentTypes[type]?.$2 ?? '';
  final expires = doc.date('expires_at');
  return [
    if (doc.strOrNull('rejection_reason') != null) doc.str('rejection_reason') else 'Uploaded ${timeAgo(doc.date('updated_at'))}',
    if (expires != null) '${expires.isBefore(DateTime.now()) ? 'Expired' : 'Expires'} ${fmtDate(expires)}',
  ].join(' • ');
}

class DocTile extends StatelessWidget {
  const DocTile(this.title, this.subtitle, this.status, {super.key, this.icon = Icons.description_outlined, this.onTap});
  final String title;
  final String subtitle;
  final DocStatus status;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color, pillIcon) = switch (status) {
      DocStatus.approved => ('Approved', CaboColors.brightGreen, Icons.check_circle),
      DocStatus.review => ('In review', CaboColors.yellow, Icons.hourglass_top_rounded),
      DocStatus.needed => ('Upload', CaboColors.yellow, Icons.upload_rounded),
      DocStatus.rejected => ('Resubmit', CaboColors.red, Icons.error_rounded),
      DocStatus.expiring => ('Renew', CaboColors.orange, Icons.update_rounded),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CaboCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        borderColor: status == DocStatus.needed ? CaboColors.surfaceHigh : null,
        child: Row(
          children: [
            IconBadge(icon, color: color, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CaboText.body.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: CaboText.muted.copyWith(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Pill(label, color: color, icon: pillIcon, solid: status == DocStatus.needed),
          ],
        ),
      ),
    );
  }
}

/// Asks for a photo from the camera or gallery and uploads it as [type].
/// Returns true when a document was uploaded.
Future<bool> uploadDocument(BuildContext context, String type, {int? vehicleId, bool cameraOnly = false}) async {
  final state = AppScope.read(context);
  final source = cameraOnly
      ? ImageSource.camera
      : await showModalBottomSheet<ImageSource>(
          context: context,
          builder: (sheet) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded, color: CaboColors.yellow),
                  title: const Text('Take a photo'),
                  onTap: () => Navigator.of(sheet).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: CaboColors.yellow),
                  title: const Text('Choose from gallery'),
                  onTap: () => Navigator.of(sheet).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
  if (source == null || !context.mounted) return false;
  try {
    final photo = await ImagePicker().pickImage(source: source, maxWidth: 2200, imageQuality: 85);
    if (photo == null) return false;
    final name = photo.name.toLowerCase();
    await state.api.upload(
      '/driver/documents',
      field: 'file',
      bytes: await photo.readAsBytes(),
      filename: name.endsWith('.png') || name.endsWith('.jpg') || name.endsWith('.jpeg') ? photo.name : '$type.jpg',
      fields: {'type': type, 'vehicle_id': ?vehicleId?.toString()},
    );
    if (context.mounted) showMessage(context, '${documentTypes[type]?.$1 ?? 'Document'} uploaded. We will review it shortly.');
    return true;
  } catch (e) {
    if (context.mounted) {
      showMessage(
        context,
        e is ApiException ? e.message : 'Could not open the camera or gallery. Check the app\'s permissions.',
        error: true,
      );
    }
    return false;
  }
}

/// Live list of the host's documents of the given [types], each uploadable.
class DocumentTiles extends StatelessWidget {
  const DocumentTiles(this.types, {super.key, this.vehicleId, this.onChanged});
  final List<String> types;
  final int? vehicleId;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<List<Json>>(
      padding: const EdgeInsets.all(12),
      load: () async => asJsonList(unwrap(await state.api.get('/driver/documents'))),
      builder: (context, docs, reload) => Column(
        children: [
          for (final type in types)
            () {
              final doc = docs.where((d) => d.str('type') == type).firstOrNull;
              final (label, _, icon) = documentTypes[type]!;
              return DocTile(
                label,
                docSubtitle(type, doc),
                docStatus(doc),
                icon: icon,
                onTap: () async {
                  if (await uploadDocument(context, type, vehicleId: vehicleId)) {
                    await reload();
                    onChanged?.call();
                  }
                },
              );
            }(),
        ],
      ),
    );
  }
}
