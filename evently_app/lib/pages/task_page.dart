import 'package:evently_app/firestore/firestore_service.dart';
import 'package:flutter/material.dart';

class TaskPage extends StatefulWidget {
  final String eventId;

  const TaskPage({Key? key, required this.eventId}) : super(key: key);

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<Map<String, dynamic>>> _tasks;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Function to reload tasks
  void _loadTasks() {
    setState(() {
      _tasks = _firestoreService.getTasks(widget.eventId);
    });
  }

  Widget _taskList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _tasks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No tasks found'));
        } else {
          var tasks = snapshot.data!;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              var task = tasks[index];
              return ListTile(
                title: Text(task['title']),
                subtitle: Text(task['description']),
                trailing: DropdownButton<String>(
                  value: task['status'],
                  items: ['to-do', 'doing', 'done'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      _firestoreService.updateTask(
                        eventId: widget.eventId,
                        taskId: task['id'],
                        status: newStatus,
                      );
                      _loadTasks();  // Reload tasks after updating status
                    }
                  },
                ),
                onTap: () => _showEditTaskDialog(task),
                onLongPress: () => _deleteTask(task['id']),
              );
            },
          );
        }
      },
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String status = 'to-do';
    String assignee = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                onChanged: (value) => assignee = value,
                decoration: const InputDecoration(labelText: 'Assignee'),
              ),
              DropdownButton<String>(
                value: status,
                items: ['to-do', 'doing', 'done'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) status = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _firestoreService.addTask(
                    eventId: widget.eventId,
                    title: titleController.text,
                    description: descriptionController.text,
                    assignee: assignee,
                    status: status,
                  );
                  _loadTasks();  // Reload tasks after adding a new one
                  Navigator.pop(context);
                } catch (e) {
                  print('Error adding task: $e');
                  // Handle error (optional: show a message to the user)
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTask(String taskId) async {
    try {
      await _firestoreService.deleteTask(eventId: widget.eventId, taskId: taskId);
      _loadTasks();  // Reload tasks after deleting
    } catch (e) {
      print('Error deleting task: $e');
      // Handle error (optional: show a message to the user)
    }
  }

  void _showEditTaskDialog(Map<String, dynamic> task) {
    final titleController = TextEditingController(text: task['title']);
    final descriptionController = TextEditingController(text: task['description']);
    String status = task['status'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              DropdownButton<String>(
                value: status,
                items: ['to-do', 'doing', 'done'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) status = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _firestoreService.updateTask(
                    eventId: widget.eventId,
                    taskId: task['id'],
                    title: titleController.text,
                    description: descriptionController.text,
                    status: status,
                  );
                  _loadTasks();  // Reload tasks after updating
                  Navigator.pop(context);
                } catch (e) {
                  print('Error editing task: $e');
                  // Handle error (optional: show a message to the user)
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tasks'),
      ),
      body: Column(
        children: [
          Expanded(child: _taskList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
