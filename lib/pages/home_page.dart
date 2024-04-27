import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class HomePage extends StatefulWidget {
  final Function toggleTheme;

  const HomePage({super.key, required this.toggleTheme});

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  late double _deviceHeight, _deviceWidth;

  Box? _box;
  _HomePageState();
  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: _deviceHeight * 0.10,
        title: const Text(
          "My Tasks",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Stack(
        children: [
          _tasksView(),
          Positioned(
            bottom: 10,
            left: 10,
            child: FloatingActionButton(
              onPressed: () => widget.toggleTheme(),
              child: const Icon(Icons.brightness_6),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              onPressed: () => _displayTaskPopup(),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tasksView() {
    return FutureBuilder(
      future: Hive.openBox('tasks'),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          _box = snapshot.data;
          return _tasksList();
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _tasksList() {
    List tasks = _box!.values.toList();
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (BuildContext context, int index) {
        var task = Task.fromMap(tasks[index]);
        return ListTile(
          title: Text(
            task.content,
            style: TextStyle(
              decoration:
                  task.done ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
          subtitle:
              Text(DateFormat('yyyy-MM-dd h:mm a').format(task.timestamp)),
          trailing: Icon(
            task.done
                ? Icons.check_box_outlined
                : Icons.check_box_outline_blank,
          ),
          onTap: () {
            task.done = !task.done;
            _box!.putAt(index, task.toMap());
            setState(() {});
          },
          onLongPress: () async {
            if (await _confirmDelete()) {
              _box!.deleteAt(index);
              setState(() {});
            }
          },
        );
      },
    );
  }

  void _displayTaskPopup() {
    String? newTaskContent;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add new task"),
          content: TextField(
            onSubmitted: (_) {
              if (newTaskContent != null) {
                var task = Task(
                    content: newTaskContent!,
                    timestamp: DateTime.now(),
                    done: false);

                _box!.add(task.toMap());
                setState(() {});
                Navigator.pop(context);
              }
            },
            onChanged: (value) {
              newTaskContent = value;
            },
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete() async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: const Text('Are you sure you want to delete this task?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Delete'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false; // The ?? operator is used to return false when the result is null (i.e., when the dialog is dismissed)
  }
}
