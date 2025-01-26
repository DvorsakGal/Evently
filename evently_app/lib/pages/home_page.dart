import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evently_app/pages/profile_page.dart';
import 'package:evently_app/pages/event_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:evently_app/auth.dart';
import 'package:evently_app/firestore/firestore_service.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Future<String> _getProfilePictureColor() async {
    final doc =
        await _firebaseFirestore.collection('users').doc(user!.uid).get();
    return doc.data()?['profilePicture'] ?? '#000000';
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(),
      ),
    );
  }

  Future<void> _showEventCreationDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Create Event"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Event Name"),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: "Location"),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () async {
                  selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2050),
                  );
                  if (selectedDate != null) {
                    TimeOfDay? selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (selectedTime != null) {
                      selectedDate = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          selectedTime.hour,
                          selectedTime.minute);
                    }
                  }
                },
                child: const Text("Select Date and Time"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    locationController.text.isNotEmpty &&
                    selectedDate != null) {
                  await _firestoreService.addEvent(
                    name: nameController.text,
                    date: selectedDate!,
                    location: locationController.text,
                    createdByUid: user!.uid,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  Widget _title() {
    return const Text("Evently");
  }

  Widget _userUid() {
    return Text(user?.email ?? "User email");
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: signOut,
      child: const Text("Sign Out"),
    );
  }

Future<List<Map<String, dynamic>>> _getUserCreatedEvents() async {
  final doc = await _firestoreService.getUserCreatedEvents(user!.uid);
  return doc;
}

Widget _userCreatedEvents() {
  return FutureBuilder(
    future: _getUserCreatedEvents(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: CircularProgressIndicator(), // Show loading indicator while fetching data
        );
      }

      if (snapshot.hasError) {
        return Center(
          child: Text('Error: ${snapshot.error}'), // Error message if there is a problem fetching data
        );
      }

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(
          child: Text('No events found for this user.'), // No data returned
        );
      }

      List<Map<String, dynamic>> events = snapshot.data!;

      return ListView.builder(
        itemCount: events.length, // Number of events to display
        itemBuilder: (context, index) {
          var event = events[index];
          var eventDate = event['date'];
          DateTime dateTime;

          if (eventDate is Timestamp) {
            dateTime = eventDate.toDate();
          } else if (eventDate is DateTime) {
            dateTime = eventDate;
          } else if (eventDate is String) {
            dateTime = DateTime.parse(eventDate);
          } else {
            dateTime = DateTime.now(); // Fallback to current date if type is unknown
          }

          var formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(dateTime);

          // Display each event's information
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: ListTile(
              title: Text(event['name'] ?? 'No name'), // Event name
              subtitle: Text(event['location'] ?? 'No location'), // Event location
              trailing: Text(formattedDate), // Event date
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventPage(eventId: event["id"]),
                  ),
                );
              },
            ),
          );
        },
      );
    },
  );
}
  Future<List<Map<String, dynamic>>> _getAllEvents() async {
    final doc = await _firestoreService.getAllEvents(user!.uid);
    return doc;
  }

  Widget _AllEvents() {
    return FutureBuilder(
      future: _getAllEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child:
                  CircularProgressIndicator()); // Show loading indicator while fetching data
        }

        if (snapshot.hasError) {
          return Center(
              child: Text(
                  'Error: ${snapshot.error}')); // error message ce ma problem prejeti data
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child:
                  Text('No events found for this user.')); //  no data returned
        }

        List<Map<String, dynamic>> events = snapshot.data!;

        return ListView.builder(
          itemCount: events.length, // Number of events to display
          itemBuilder: (context, index) {
            var event = events[index];

            // Display each event's information
            return Card(
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: ListTile(
                title: Text(event['name'] ?? 'No name'), // Event name
                subtitle:
                    Text(event['location'] ?? 'No location'), // Event location
                trailing: Text(event['date']?.toDate().toString() ??
                    'No date'), // Event date
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EventPage(eventId: event["id"]), ///////
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getUserEvents() async {
    final doc = await _firestoreService.getUserEvents(user!.uid);
    return doc;
  }

Widget _userEvents() {
  return FutureBuilder(
    future: _getUserEvents(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: CircularProgressIndicator(), // Show loading indicator while fetching data
        );
      }

      if (snapshot.hasError) {
        return Center(
          child: Text('Error: ${snapshot.error}'), // Error message if there is a problem fetching data
        );
      }

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(
          child: Text('No events found for this user.'), // No data returned
        );
      }

      List<Map<String, dynamic>> events = snapshot.data!;

      return ListView.builder(
        itemCount: events.length, // Number of events to display
        itemBuilder: (context, index) {
          var event = events[index];
          var eventDate = event['date'];
          DateTime dateTime;

          if (eventDate is Timestamp) {
            dateTime = eventDate.toDate();
          } else if (eventDate is DateTime) {
            dateTime = eventDate;
          } else if (eventDate is String) {
            dateTime = DateTime.parse(eventDate);
          } else {
            dateTime = DateTime.now(); // Fallback to current date if type is unknown
          }

          var formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(dateTime);

          // Display each event's information
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: ListTile(
              title: Text(event['name'] ?? 'No name'), // Event name
              subtitle: Text(event['location'] ?? 'No location'), // Event location
              trailing: Text(formattedDate), // Event date
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventPage(eventId: event["id"]),
                  ),
                );
              },
            ),
          );
        },
      );
    },
  );
}

  Widget _profileIcon() {
    return FutureBuilder(
      future: _getProfilePictureColor(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Icon(Icons.error);
        }
        final colorHex = snapshot.data!;
        final color =
            Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);

        return GestureDetector(
          onTap: () => _navigateToProfile(context),
          child: CircleAvatar(
            backgroundColor: color,
            radius: 20,
            child: const Icon(Icons.person),
          ),
        );
      },
    );
  }

  int _selectedIndex = 0;
  void _onButtonPressed(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _profileIcon(),
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onButtonPressed(0),
                    child: Text("My Events"), //jih je user ustvaro
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onButtonPressed(1),
                    child: Text("Attending"), //jih ima user v sebi
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onButtonPressed(2),
                    child: Text("All Events"), //cisto vsi eventi
                  ),
                ),
              ],
            ),
            // Only display the selected event list
            Expanded(
              child: _selectedIndex == 0
                  ? _userCreatedEvents() // Show User Created Events
                  : _selectedIndex == 1
                      ? _userEvents() // Show User Events
                      : _AllEvents(), // Show All Events
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEventCreationDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
