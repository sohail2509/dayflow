import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const DayflowApp());

class DayflowApp extends StatelessWidget {
  const DayflowApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DAYFLOW',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF77D6B2), brightness: Brightness.dark), scaffoldBackgroundColor: const Color(0xFF101820), useMaterial3: true),
    home: const HomePage(),
  );
}

class Task {
  String title, category;
  bool done;
  Task(this.title, this.category, {this.done = false});
  Map<String, dynamic> toJson() => {'title': title, 'category': category, 'done': done};
  factory Task.fromJson(Map<String, dynamic> j) => Task(j['title'] ?? '', j['category'] ?? 'Personal', done: j['done'] ?? false);
}

class Goal {
  String title;
  int target, progress;
  Goal(this.title, this.target, this.progress);
  Map<String, dynamic> toJson() => {'title': title, 'target': target, 'progress': progress};
  factory Goal.fromJson(Map<String, dynamic> j) => Goal(j['title'] ?? '', j['target'] ?? 1, j['progress'] ?? 0);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  List<Task> tasks = [Task('Plan my day', 'Personal'), Task('Complete important work', 'Work'), Task('Exercise or walk', 'Health'), Task('Learn something new', 'Learning'), Task('Review my day', 'Personal')];
  List<Goal> goals = [Goal('Workouts this month', 20, 0), Goal('Learning sessions', 20, 0)];
  String activity = '';
  DateTime? started;
  Duration elapsed = Duration.zero;
  Timer? ticker;
  final activityController = TextEditingController();
  final taskController = TextEditingController();
  final goalController = TextEditingController();
  final targetController = TextEditingController(text: '10');

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { ticker?.cancel(); activityController.dispose(); taskController.dispose(); goalController.dispose(); targetController.dispose(); super.dispose(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final ts = p.getString('tasks'); final gs = p.getString('goals');
    if (!mounted) return;
    setState(() {
      if (ts != null) tasks = (jsonDecode(ts) as List).map((e) => Task.fromJson(e)).toList();
      if (gs != null) goals = (jsonDecode(gs) as List).map((e) => Goal.fromJson(e)).toList();
      elapsed = Duration(seconds: p.getInt('elapsed') ?? 0);
    });
  }
  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('tasks', jsonEncode(tasks.map((e) => e.toJson()).toList()));
    await p.setString('goals', jsonEncode(goals.map((e) => e.toJson()).toList()));
    await p.setInt('elapsed', elapsed.inSeconds);
  }
  int get completed => tasks.where((e) => e.done).length;
  int get percent => tasks.isEmpty ? 0 : (completed * 100 / tasks.length).round();
  String fmt(Duration d) => '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  void _startTimer() {
    if (activityController.text.trim().isEmpty) { _snack('Enter an activity first'); return; }
    setState(() { activity = activityController.text.trim(); started = DateTime.now(); });
    ticker?.cancel();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => elapsed += const Duration(seconds: 1)); _save(); });
  }
  void _stopTimer() { ticker?.cancel(); setState(() { started = null; }); _save(); _snack('Activity timer paused'); }
  void _snack(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _addTask() async {
    taskController.clear();
    await showDialog(context: context, builder: (c) => AlertDialog(title: const Text('New task'), content: TextField(controller: taskController, autofocus: true, decoration: const InputDecoration(hintText: 'What do you need to do?')), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), FilledButton(onPressed: () { if (taskController.text.trim().isNotEmpty) setState(() => tasks.add(Task(taskController.text.trim(), 'Personal'))); _save(); Navigator.pop(c); }, child: const Text('Add'))]));
  }
  Future<void> _addGoal() async {
    goalController.clear(); targetController.text = '10';
    await showDialog(context: context, builder: (c) => AlertDialog(title: const Text('New goal'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: goalController, decoration: const InputDecoration(hintText: 'Goal name')), TextField(controller: targetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target number'))]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), FilledButton(onPressed: () { final n = int.tryParse(targetController.text) ?? 1; if (goalController.text.trim().isNotEmpty && n > 0) setState(() => goals.add(Goal(goalController.text.trim(), n, 0))); _save(); Navigator.pop(c); }, child: const Text('Add'))]));
  }

  Widget _dashboard() => ListView(padding: const EdgeInsets.all(18), children: [
    Text('YOUR DAY, IN FLOW', style: TextStyle(color: Colors.teal.shade200, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8), Text('Good day.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
    Text(DateTime.now().toLocal().toString().substring(0, 10), style: const TextStyle(color: Colors.white60)),
    const SizedBox(height: 20),
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("TODAY'S PROGRESS", style: TextStyle(color: Colors.white70, letterSpacing: 1)),
      const SizedBox(height: 12), Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('$percent%', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold)), const Spacer(), Text('$completed of ${tasks.length} tasks', style: const TextStyle(color: Colors.white60))]),
      const SizedBox(height: 10), LinearProgressIndicator(value: percent / 100, minHeight: 9, borderRadius: BorderRadius.circular(9)),
    ]))),
    const SizedBox(height: 12),
    Row(children: [Expanded(child: _stat('Tracked time', fmt(elapsed), Icons.timer_outlined)), const SizedBox(width: 10), Expanded(child: _stat('Goals', '${goals.length}', Icons.flag_outlined))]),
    const SizedBox(height: 22), _heading('Today’s tasks', onAdd: _addTask),
    ...tasks.map((t) => CheckboxListTile(value: t.done, onChanged: (v) { setState(() => t.done = v ?? false); _save(); }, title: Text(t.title, style: TextStyle(decoration: t.done ? TextDecoration.lineThrough : null)), subtitle: Text(t.category), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero)),
    const SizedBox(height: 12), const Text('Tip: choose your three most important tasks first.', style: TextStyle(color: Colors.white54)),
  ]);

  Widget _stat(String label, String value, IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Colors.tealAccent), const SizedBox(height: 10), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12))])));
  Widget _heading(String s, {VoidCallback? onAdd}) => Row(children: [Expanded(child: Text(s, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))), if (onAdd != null) IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle_outline))]);

  Widget _planner() => ListView(padding: const EdgeInsets.all(18), children: [_heading('Daily planner', onAdd: _addTask), const Text('Add tasks as they come up, then check them off when complete.'), const SizedBox(height: 12), ...tasks.map((t) => Card(child: ListTile(leading: Icon(t.done ? Icons.check_circle : Icons.radio_button_unchecked, color: t.done ? Colors.tealAccent : null), title: Text(t.title), subtitle: Text(t.category), trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { setState(() => tasks.remove(t)); _save(); }))))]);

  Widget _timer() => ListView(padding: const EdgeInsets.all(18), children: [_heading('Activity timer'), const SizedBox(height: 20), TextField(controller: activityController, enabled: started == null, decoration: const InputDecoration(labelText: 'What are you doing?', hintText: 'e.g. Work, learning, gym', border: OutlineInputBorder())), const SizedBox(height: 26), Center(child: Text(fmt(elapsed), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, fontFeatures: []))), Center(child: Text(started == null ? 'Timer paused' : 'Tracking: $activity', style: const TextStyle(color: Colors.white60))), const SizedBox(height: 26), if (started == null) FilledButton.icon(onPressed: _startTimer, icon: const Icon(Icons.play_arrow), label: const Text('Start tracking')) else FilledButton.icon(onPressed: _stopTimer, icon: const Icon(Icons.pause), label: const Text('Pause timer')), const SizedBox(height: 12), const Text('The timer tracks one activity at a time. Your accumulated time is saved on this device.')]);

  Widget _goals() => ListView(padding: const EdgeInsets.all(18), children: [_heading('My goals', onAdd: _addGoal), const Text('Track measurable goals and update progress as you go.'), const SizedBox(height: 12), ...goals.map((g) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(g.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 10), LinearProgressIndicator(value: (g.progress / g.target).clamp(0, 1)), const SizedBox(height: 8), Row(children: [Text('${g.progress} / ${g.target}'), const Spacer(), IconButton(onPressed: () { setState(() => g.progress = (g.progress - 1).clamp(0, g.target)); _save(); }, icon: const Icon(Icons.remove_circle_outline)), IconButton(onPressed: () { setState(() => g.progress = (g.progress + 1).clamp(0, g.target)); _save(); }, icon: const Icon(Icons.add_circle_outline))]),]))))]);

  Widget _reports() => ListView(padding: const EdgeInsets.all(18), children: [_heading('Your report'), Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('TASK COMPLETION', style: TextStyle(color: Colors.white60)), Text('$percent%', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold)), LinearProgressIndicator(value: percent / 100), const SizedBox(height: 16), Text('$completed completed · ${tasks.length - completed} remaining'), const Divider(height: 28), const Text('TIME TRACKED', style: TextStyle(color: Colors.white60)), Text(fmt(elapsed), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), const Text('Total accumulated timer time on this device') ]))), const SizedBox(height: 12), const Text('This first version reports current saved tasks and timer totals. Historical daily and weekly charts can be added in the next version.')]);

  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), _planner(), _timer(), _goals(), _reports()];
    return Scaffold(
      appBar: AppBar(title: const Text('DAYFLOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)), actions: [IconButton(onPressed: () => _snack('Local data is saved on this device.'), icon: const Icon(Icons.cloud_done_outlined), tooltip: 'Backup status')]),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), label: 'Today'), NavigationDestination(icon: Icon(Icons.checklist), label: 'Planner'), NavigationDestination(icon: Icon(Icons.timer_outlined), label: 'Timer'), NavigationDestination(icon: Icon(Icons.flag_outlined), label: 'Goals'), NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports')]),
    );
  }
}
