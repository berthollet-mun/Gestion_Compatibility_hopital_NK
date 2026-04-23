import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/rapport_service.dart';
import '../../core/services/storage_service.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../shared/widgets/loading_widget.dart';

class RapportsPage extends StatefulWidget {
  const RapportsPage({super.key});

  @override
  State<RapportsPage> createState() => _RapportsPageState();
}

class _RapportsPageState extends State<RapportsPage> {
  final RapportService _service = Get.find<RapportService>();
  final StorageService _storage = Get.find<StorageService>();
  Map<String, dynamic>? _balance;
  bool _isLoading = false;
  final int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rapports Financiers')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Report cards
          _reportCard('Balance Générale', 'Situation de tous les comptes',
              Icons.balance, () => _loadBalance()),
          _reportCard('Grand Livre', 'Détail des mouvements par compte',
              Icons.menu_book, () {}),
          _reportCard('Exécution Budgétaire', 'Comparaison prévu vs réalisé',
              Icons.pie_chart, () {}),
          _reportCard('Situation de Trésorerie', 'Flux de trésorerie',
              Icons.account_balance_wallet, () {}),
          const SizedBox(height: 20),

          // Balance display
          if (_isLoading) const LoadingWidget(),
          if (_balance != null) ...[
            const Text('Balance Générale',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (_balance!['comptes'] != null)
              ...(_balance!['comptes'] as List).map((c) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      title: Text('${c['code']} - ${c['libelle']}',
                          style: const TextStyle(fontSize: 13)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            AppHelpers.formatMontantCompact(
                                (c['debit'] ?? 0).toDouble()),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.blue),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: Text(
                            AppHelpers.formatMontantCompact(
                                (c['credit'] ?? 0).toDouble()),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.green),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ]),
                    ),
                  )),
          ],
        ],
      ),
    );
  }

  Widget _reportCard(
      String title, String desc, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(desc,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ])),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ]),
        ),
      ),
    );
  }

  Future<void> _loadBalance() async {
    setState(() => _isLoading = true);
    final result = await _service.getBalance(exerciceId: _storage.exerciceId);
    if (result['success'] == true) {
      setState(() => _balance = result['data']);
    }
    setState(() => _isLoading = false);
  }
}
