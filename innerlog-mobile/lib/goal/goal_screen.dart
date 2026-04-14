import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api.dart';

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
    try {
      final res = await _api.getGoals();
      setState(() { _goals = res.data; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mục tiêu')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? const Center(child: Text('Chưa có mục tiêu nào'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _goals.length,
                  itemBuilder: (_, i) {
                    final g = _goals[i];
                    return Card(
                      child: ExpansionTile(
                        title: Text(g['title']),
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
                                title: Text(task['title'], style: TextStyle(
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
                            child: Row(children: [
                              Expanded(child: TextField(
                                decoration: const InputDecoration(hintText: 'Thêm task...', isDense: true),
                                onSubmitted: (v) async {
                                  if (v.isNotEmpty) {
                                    await _api.addTask(g['_id'], v);
                                    _loadGoals();
                                  }
                                },
                              )),
                            ]),
                          ),
                        ],
                      ),
                    );
                    });
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoal(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (i) {
          final routes = ['/checkin', '/insights', '/goals', '/profile'];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.mood), label: 'Check-in'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Goals'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _showAddGoal(BuildContext context) {
    final titleCtrl = TextEditingController();
    String category = 'other';
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tên mục tiêu')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: category,
            items: ['study', 'work', 'health', 'finance', 'other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => category = v ?? 'other',
            decoration: const InputDecoration(labelText: 'Loại'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await _api.createGoal(titleCtrl.text, category);
              if (mounted) Navigator.pop(context);
              _loadGoals();
            },
            child: const Text('Tạo mục tiêu'),
          ),
        ]),
      ),
    );
  }
}
