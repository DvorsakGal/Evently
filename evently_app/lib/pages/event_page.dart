import 'package:evently_app/firestore/firestore_service.dart';
import 'package:flutter/material.dart';


class EventPage extends StatefulWidget {
  final String eventId;  // Accept eventId in the constructor

  // Constructor to receive the eventId
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
    // Fetch event details using the eventId when the page loads
    _eventDetails = _firestoreService.getSelectedEvent(widget.eventId);
  }
  
  Widget _detailsOfEvent(){
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
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Event Name: ${event['name']}', style: TextStyle(fontSize: 24)),
                SizedBox(height: 8),
                Text('Date: ${event['date']}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Location: ${event['location']}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Tasks: ${event['tasks'].join(', ')}', style: TextStyle(fontSize: 18)),
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
        title: const Text("EventPageX"),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close),
        ),
      ),
      body:/*Text("asd"),*/ _detailsOfEvent(),
    );
  }
}
