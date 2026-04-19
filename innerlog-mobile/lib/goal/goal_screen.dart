import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/l10n/app_localizations.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});
  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final _api = ApiClient();
  List<dynamic> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getGoals();
      setState(() { _goals = (res.data is List) ? res.data : []; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).goals)),
      body: RefreshIndicator(
        onRefresh: _loadGoals,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _goals.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 120),
                    Center(child: Column(children: [
                      const Text('🎯', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 12),
                      Text(AppLocalizations.of(context).noGoals, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(AppLocalizations.of(context).createFirstGoal, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ])),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _goals.length,
                    itemBuilder: (_, i) {
                      final g = _goals[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          title: Text(g['title'] ?? ''),
                          subtitle: Row(children: [
                            Chip(label: Text(g['category'] ?? 'other')),
                            const SizedBox(width: 8),
                            Text('${g['progress'] ?? 0}%'),
                          ]),
                          trailing: SizedBox(
                            width: 40, height: 40,
                            child: CircularProgressIndicator(value: (g['progress'] ?? 0) / 100, strokeWidth: 4),
                          ),
                          children: [
                            if (g['tasks'] != null)
                              ...List.generate((g['tasks'] as List).length, (ti) {
                                final task = g['tasks'][ti];
                                return CheckboxListTile(
                                  title: Text(task['title'] ?? '', style: TextStyle(
                                    decoration: task['done'] == true ? TextDecoration.lineThrough : null,
                                  )),
                                  value: task['done'] == true,
                                  onChanged: (_) async {
                                    await _api.toggleTask(g['_id'], ti);
                                    _loadGoals();
                                  },
                                );
                              }),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: TextField(
                                decoration: const InputDecoration(hintText: 'Add task...', isDense: true, border: OutlineInputBorder()),
                                onSubmitted: (v) async {
                                  if (v.isNotEmpty) {
                                    await _api.addTask(g['_id'], v);
                                    _loadGoals();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddGoal(BuildContext context) {
    final l = AppLocalizations.of(context);
    final titleCtrl = TextEditingController();
    String category = 'other';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, decoration: InputDecoration(labelText: l.goalName, border: const OutlineInputBorder())),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: category,
            items: ['study', 'work', 'health', 'finance', 'other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => category = v ?? 'other',
            decoration: InputDecoration(labelText: l.goalCategory, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                if (titleCtrl.text.isNotEmpty) {
                  await _api.createGoal(titleCtrl.text, category);
                  if (mounted) Navigator.pop(context);
                  _loadGoals();
                }
              },
              child: Text(l.createGoal),
            ),
          ),
        ]),
      ),
    );
  }
}
