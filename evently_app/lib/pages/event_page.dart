import 'package:evently_app/firestore/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evently_app/pages/task_page.dart';
import 'package:evently_app/pages/guestlist_page.dart';  // Uvoz za novo stran
import 'package:intl/intl.dart';  // Import intl package

class EventPage extends StatefulWidget {
  final String eventId;

  const EventPage({Key? key, required this.eventId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EventPage();
}

class _EventPage extends State<EventPage> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<Map<String, dynamic>> _eventDetails;

  @override
  void initState() {
    super.initState();
    _eventDetails = _firestoreService.getSelectedEvent(widget.eventId);
  }

  String _formatDate(Timestamp timestamp) {
    // Convert the Timestamp to DateTime
    DateTime dateTime = timestamp.toDate();
    // Format the DateTime to a human-readable format
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  Widget _detailsOfEvent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _eventDetails,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return Center(child: Text('Event not found'));
        } else {
          var event = snapshot.data!;
          // Ensure that the 'date' field is a Timestamp
          Timestamp eventDate = event['date'];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Event Name: ${event['name']}', style: TextStyle(fontSize: 24)),
                SizedBox(height: 8),
                Text('Date: ${_formatDate(eventDate)}', style: TextStyle(fontSize: 18)),  // Format the date here
                SizedBox(height: 8),
                Text('Location: ${event['location']}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Participants: ${event['participants'].join(', ')}', style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EventPage"),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _detailsOfEvent()),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskPage(eventId: widget.eventId),
                  ),
                );
              },
              icon: const Icon(Icons.task),
              label: const Text('Manage Tasks'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GuestListPage(eventId: widget.eventId), // Preusmeri na GuestListPage
                  ),
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('Manage Guests'),
            ),
          ),
        ],
      ),
    );
  }
}
