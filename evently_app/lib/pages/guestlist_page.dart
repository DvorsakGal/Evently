import 'package:evently_app/firestore/firestore_service.dart';
import 'package:flutter/material.dart';

class GuestListPage extends StatefulWidget {
  final String eventId;

  const GuestListPage({Key? key, required this.eventId}) : super(key: key);

  @override
  State<GuestListPage> createState() => _GuestListPageState();
}

class _GuestListPageState extends State<GuestListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<Map<String, dynamic>>> _guests;

  @override
  void initState() {
    super.initState();
    _loadGuests();
  }

  // Function to reload guests
  void _loadGuests() {
    setState(() {
      _guests = _firestoreService.getGuests(widget.eventId);
    });
  }

  Widget _guestList() {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: _guests,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(child: Text('No guests found'));
      } else {
        var guests = snapshot.data!;
        return ListView.builder(
          itemCount: guests.length,
          itemBuilder: (context, index) {
            var guest = guests[index];
            String status = guest['status'];
            Color statusColor;

            // Določite barvo glede na status
            switch (status) {
              case 'confirmed':
                statusColor = Colors.green;
                break;
              case 'declined':
                statusColor = Colors.red;
                break;
              case 'pending':
              default:
                statusColor = Colors.orange;
                break;
            }

            return ListTile(
              title: Text(guest['name']),
              subtitle: Text(guest['email']),
              trailing: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              onTap: () => _showEditGuestDialog(guest),
              onLongPress: () => _deleteGuest(guest['id']),
            );
          },
        );
      }
    },
  );
}


  void _showAddGuestDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String status = 'pending';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Guest'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              DropdownButton<String>(
                value: status,
                items: ['pending', 'confirmed', 'declined'].map((status) {
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
                  await _firestoreService.addGuest(
                    eventId: widget.eventId,
                    name: nameController.text,
                    email: emailController.text,
                    status: status,
                  );
                  _loadGuests(); // Reload guests after adding a new one
                  Navigator.pop(context);
                } catch (e) {
                  print('Error adding guest: $e');
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteGuest(String guestId) async {
    try {
      await _firestoreService.deleteGuest(eventId: widget.eventId, guestId: guestId);
      _loadGuests(); // Reload guests after deleting
    } catch (e) {
      print('Error deleting guest: $e');
    }
  }

  void _showEditGuestDialog(Map<String, dynamic> guest) {
  final nameController = TextEditingController(text: guest['name']);
  final emailController = TextEditingController(text: guest['email']);
  String status = guest['status']; // Lokalna spremenljivka status

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Guest'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                DropdownButton<String>(
                  value: status,
                  items: ['pending', 'confirmed', 'declined'].map((statusOption) {
                    return DropdownMenuItem(
                      value: statusOption,
                      child: Text(statusOption),
                    );
                  }).toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      setState(() {
                        status = newStatus; // Posodobi lokalno spremenljivko status
                      });
                    }
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
                    // Posodobi gosta s pomočjo imena, emaila in novega statusa
                    await _firestoreService.updateGuest(
                      eventId: widget.eventId,
                      guestName: guest['name'], // Uporabi ime gosta
                      guestEmail: guest['email'], // Uporabi email gosta
                      name: nameController.text,
                      email: emailController.text,
                      status: status, // Posodobi z novim statusom
                    );
                    _loadGuests(); // Reload guests after updating
                    Navigator.pop(context);
                  } catch (e) {
                    print('Error editing guest: $e');
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Guests'),
      ),
      body: Column(
        children: [
          Expanded(child: _guestList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGuestDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
