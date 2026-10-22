// add_kost_page.dart — Redirect ke KostManagementPage (CRUD lengkap)
// File ini dipertahankan untuk menjaga route /owner/kost/add tetap valid.
export 'kost_management_page.dart' show KostManagementPage;
import 'package:flutter/material.dart';
import 'kost_management_page.dart';

/// Wrapper agar route /owner/kost/add tetap mengarah ke KostFormPage (create mode)
class AddKostPage extends StatelessWidget {
  const AddKostPage({super.key});

  @override
  Widget build(BuildContext context) => const KostFormPage();
}
