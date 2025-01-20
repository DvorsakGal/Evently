import 'package:evently_app/firestore/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evently_app/pages/task_page.dart';
import 'package:evently_app/pages/guestlist_page.dart'; // Uvoz za novo stran
import 'package:intl/intl.dart'; // Import intl package
import 'package:evently_app/pages/weather_page.dart';
import 'package:evently_app/auth.dart';

class EventPage extends StatefulWidget {
  final String eventId;

  const EventPage({Key? key, required this.eventId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EventPage();
}

class _EventPage extends State<EventPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final User? user = Auth().currentUser;
  late Future<Map<String, dynamic>> _eventDetails;

  //OGLASNA DESKA PARAMETRI
  final TextEditingController _postController = TextEditingController();
  // Each post now contains both the text and the user's profile color
  final List<Map<String, String>> _bulletinBoardPosts = [];
  //konec

  // BARVA
  Future<String> _getProfilePictureColor() async {
    final doc =
        await _firebaseFirestore.collection('users').doc(user!.uid).get();
    return doc.data()?['profilePicture'] ?? '#000000';
  }

  @override
  void initState() {
    super.initState();
    _eventDetails = _firestoreService.getSelectedEvent(widget.eventId);
    // Populate with dummy data

    _bulletinBoardPosts.addAll([
      {
        "text": "Will the event be cancelled in case of rain?",
        "color": "#FF5722"
      },
      {
        "text":
            "No. So please check the weather before arrival for proper wardrobe :)",
        "color": "#4CAF50"
      },
      {"text": "Sadly I won't be making it :(", "color": "#2196F3"},
    ]);
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
          Timestamp eventDate = event['date'];
          List<dynamic> participants = event['participants'] ?? [];

          // Filtriraj potrjene udeležence in pridobi njihova imena
          var confirmedParticipants = participants
              .where((p) => p['status'] == 'confirmed')
              .map((p) => p['name'])
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ime dogodka z lila barvo
                    Text(
                      event['name'],
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(
                            255, 103, 79, 163), // Lila barva za naslov
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Datum dogodka z ikono
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: const Color.fromARGB(
                                255, 103, 79, 163)), // Lila ikona
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(eventDate),
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Lokacija dogodka z ikono
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: const Color.fromARGB(
                                255, 103, 79, 163)), // Lila ikona
                        const SizedBox(width: 8),
                        Text(
                          event['location'],
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Udeleženci (prikaz potrjenih udeležencev)
                    Text(
                      'Confirmed Participants:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(
                            255, 103, 79, 163), // Lila barva za naslov
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Prikaz imen potrjenih udeležencev v obliki seznama
                    if (confirmedParticipants.isEmpty)
                      Text(
                        'No confirmed participants yet.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      )
                    else
                      ...confirmedParticipants.map(
                        (name) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: const Color.fromARGB(255, 8, 161, 67),
                                  size: 20),
                              const SizedBox(width: 8),
                              Text(
                                name,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  // ADD POST ZA OGLASNO DESKO
  void _addPost() async {
    if (_postController.text.isNotEmpty) {
      final userColor = await _getProfilePictureColor(); // Fetch user's color
      setState(() {
        _bulletinBoardPosts.add({
          "text": _postController.text,
          "color": userColor, // Store the user's color with the post
        });
        _postController.clear();
      });
    }
  }

  // OGLASNA DESKA WIDGET
  Widget _bulletinBoard() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _postController,
            decoration: const InputDecoration(
              labelText: 'Add an announcement',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: _addPost,
            child: const Text('Post Announcement'),
          ),
        ),
        Container(
          height: 300, // Specify a fixed height for the bulletin board
          child: ListView.builder(
            itemCount: _bulletinBoardPosts.length,
            itemBuilder: (context, index) {
              final post = _bulletinBoardPosts[index];
              final colorHex = post['color']!;
              final borderColor = Color(
                  int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);

              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 2.0),
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.white, // Background color for the tile
                ),
                child: ListTile(
                  title: Text(
                    post['text']!,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ),
              );
            },
          ),
        )
      ],
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _eventDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Event not found'));
          } else {
            // Extract event details once the Future is resolved
            final event = snapshot.data!;
            final location = event['location']; // Access the location here

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailsOfEvent(),
                  const Divider(),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 125,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TaskPage(eventId: widget.eventId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.task),
                          label: const Text('Manage Tasks'),
                        ),
                      ),
                      SizedBox(
                        width: 125,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    GuestListPage(eventId: widget.eventId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.people),
                          label: const Text('Manage Guests'),
                        ),
                      ),
                      SizedBox(
                        width: 125,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WeatherPage(location: location),
                              ),
                            );
                          },
                          icon: const Icon(Icons.sunny),
                          label: const Text('Check Weather'),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  // OGLASNA DESKA
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Bulletin Board',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 103, 79, 163),
                      ),
                    ),
                  ),
                  _bulletinBoard(),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
