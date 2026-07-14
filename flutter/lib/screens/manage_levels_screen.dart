import 'package:flutter/material.dart';
import '../data/levels.dart';
import 'admin_screen.dart';

class ManageLevelsScreen extends StatefulWidget {
  const ManageLevelsScreen({super.key});

  @override
  State<ManageLevelsScreen> createState() => _ManageLevelsScreenState();
}

class _ManageLevelsScreenState extends State<ManageLevelsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshLevels();
  }

  Future<void> _refreshLevels() async {
    setState(() => _isLoading = true);
    await Levels.loadCustomLevels();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _deleteLevel(LevelData level) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Level?'),
        content: const Text('Are you sure you want to delete this level? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('DELETE', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true && level.id != null) {
      setState(() => _isLoading = true);
      await Levels.deleteCustomLevel(level.id!);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8DFD0),
      appBar: AppBar(
        title: const Text('MANAGE LEVELS', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF8B4513),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLevels,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Levels.customLevels.isEmpty
          ? const Center(child: Text('No custom levels found in Firebase.'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: Levels.customLevels.length,
              onReorder: (oldIndex, newIndex) async {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = Levels.customLevels.removeAt(oldIndex);
                  Levels.customLevels.insert(newIndex, item);
                });
                await Levels.updateLevelsOrder(Levels.customLevels);
                // We don't necessarily need to reload, just let it be updated.
              },
              itemBuilder: (context, index) {
                final level = Levels.customLevels[index];
                return Card(
                  key: ValueKey(level.id ?? 'level_$index'), // Required for ReorderableListView
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle, color: Colors.grey),
                    ),
                    title: Text('Level ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${level.rows}x${level.cols} Grid • ${level.blocks.length} Blocks'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(level: level)));
                            _refreshLevels();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteLevel(level),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
          _refreshLevels();
        },
        label: const Text('CREATE NEW'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF5BA3E0),
      ),
    );
  }
}
