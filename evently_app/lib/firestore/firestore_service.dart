import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a new user to the Firestore database
  Future<void> addUser({
    required String uid,
    required String name,
    required String email,
    required String profilePicture,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'events': [],
    });
  }

  // Add an event to Firestore
  Future<String> addEvent({
    required String name,
    required DateTime date,
    required String location,
    required String createdByUid,
  }) async {
    DocumentReference eventRef = await _firestore.collection('events').add({
      'name': name,
      'date': Timestamp.fromDate(date),
      'location': location,
      'createdBy': _firestore.doc('users/$createdByUid'),
      'participants': [],
      'tasks': [],
      'expenses': [],
    });

    return eventRef.id;
  }

  //----------------------------------------------
//  Za zdaj je kar se tice dela z id-jem zelo scuffed
//----------------------------------------------
  // eventi ki jih je ustvaril user (user trenutno nima v sebi gleda se glede na events createdBy)
  Future<List<Map<String, dynamic>>> getUserCreatedEvents(String uid) async {
    var userRef = _firestore.collection('users').doc(uid);
    var eventsSnapshot = await _firestore
        .collection('events')
        .where('createdBy', isEqualTo: userRef)
        .get();

    if (eventsSnapshot.docs.isNotEmpty) {
      return eventsSnapshot.docs.map((eventDoc) {
        Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
        eventData['id'] = eventDoc.id;
        return eventData;
      }).toList();
    } else {
      return [];
    }
  }

  // pridobivanje eventov glede na id eventa
  Future<Map<String, dynamic>> getSelectedEvent(String eid) async {
    var event = await _firestore.collection('events').doc(eid).get();

    if (event.exists) {
      return event.data() as Map<String, dynamic>;
    } else {
      throw Exception('Event not found');
    }
  }

   // not used now
  // pridobivanje čisto vseh eventov
  Future<List<Map<String, dynamic>>> getAllEvents(
      String uid
      ) async {

        // vstop na events, vzames vse evente  
        var eventsSnapshot = await _firestore
        .collection('events')             
        .get();                            

        if (eventsSnapshot.docs.isNotEmpty) {

        // Mapiraj event dokumente na List map (event data)
        List<Map<String, dynamic>> events = eventsSnapshot.docs.map((eventDoc) {
          Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
          eventData['id'] = eventDoc.id; // Add the document ID to the event data

          return eventData;
        }).toList();

        // vrne filtrirane evente
        return events;
        } else {
          return [];  // event ni najden
        }
  }

// not used now
    /*
            TRENUTNO NE DELA kar se ziče prehajanja v event_page
    */
  // eventi katerih je user del (jih ima user v sebi)
  Future<List<Map<String, dynamic>>> getUserEvents(String uid) async {
    
      // Query Firestore for the user's document by UID
      var userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        // Extract the events array from the user's document
        List eventRefs = userDoc['events'];
        List<Map<String, dynamic>> events = [];
        for (var eventRef in eventRefs) {
          // Get the event document from the reference
          var eventDoc = await eventRef.get();

          if (eventDoc.exists) {
            // Add the event data to the events list
            Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
            eventData['id'] = eventDoc.id; // Include the event ID



            events.add(eventData);
          }
        }
        return events;
      } else {
        return [];
      }
    
  }

  // Add a task to a specific event
  Future<void> addTask({
    required String eventId,
    required String title,
    required String description,
    required String assignee,
    required String status,
  }) async {
    var task = {
      'title': title,
      'description': description,
      'assignee': assignee,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };

    var taskRef = await _firestore.collection('tasks').add(task);

    await _firestore.collection('events').doc(eventId).update({
      'tasks': FieldValue.arrayUnion([taskRef]),
    });
  }

  // Get tasks for a specific event
  Future<List<Map<String, dynamic>>> getTasks(String eventId) async {
    var eventDoc = await _firestore.collection('events').doc(eventId).get();

    if (eventDoc.exists) {
      List<dynamic> taskRefs = eventDoc['tasks'] ?? [];
      List<Map<String, dynamic>> tasks = [];

      for (var taskRef in taskRefs) {
        if (taskRef is DocumentReference) {
          var taskDoc = await taskRef.get();
          if (taskDoc.exists) {
            Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;
            taskData['id'] = taskDoc.id;
            tasks.add(taskData);
          }
        }
      }
      return tasks;
    } else {
      throw Exception('Event not found');
    }
  }

  // Update a task's details
  Future<void> updateTask({
    required String eventId,
    required String taskId,
    String? title,
    String? description,
    String? status,
  }) async {
    var eventDoc = await _firestore.collection('events').doc(eventId).get();

    if (eventDoc.exists) {
      List<dynamic> taskRefs = eventDoc['tasks'] ?? [];
      DocumentReference? taskRef;

      for (var ref in taskRefs) {
        if (ref is DocumentReference && ref.id == taskId) {
          taskRef = ref;
          break;
        }
      }

      if (taskRef != null) {
        var updatedData = <String, dynamic>{};
        if (title != null) updatedData['title'] = title;
        if (description != null) updatedData['description'] = description;
        if (status != null) updatedData['status'] = status;

        await taskRef.update(updatedData);
      } else {
        throw Exception('Task reference not found');
      }
    } else {
      throw Exception('Event not found');
    }
  }

  // Delete a task from an event
  Future<void> deleteTask({
    required String eventId,
    required String taskId,
  }) async {
    var eventDoc = await _firestore.collection('events').doc(eventId).get();

    if (eventDoc.exists) {
      List<dynamic> taskRefs = eventDoc['tasks'] ?? [];
      DocumentReference? taskRef;

      for (var ref in taskRefs) {
        if (ref is DocumentReference && ref.id == taskId) {
          taskRef = ref;
          break;
        }
      }

      if (taskRef != null) {
        await taskRef.delete();
        await _firestore.collection('events').doc(eventId).update({
          'tasks': FieldValue.arrayRemove([taskRef]),
        });
      } else {
        throw Exception('Task reference not found');
      }
    } else {
      throw Exception('Event not found');
    }
  }

  // Send an invitation to a guest, creating a user if necessary
  Future<void> sendInvitation({
    required String eventId,
    required String guestEmail,
  }) async {
    try {
      // Check if the guest already exists
      var userQuery = await _firestore.collection('users').where('email', isEqualTo: guestEmail).get();

      String guestId;

      if (userQuery.docs.isEmpty) {
        // Create a new user for the guest
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: guestEmail,
          password: 'guest', // Default password
        );
        guestId = userCredential.user!.uid;

        // Add the new user to the Firestore collection
        await _firestore.collection('users').doc(guestId).set({
          'email': guestEmail,
          'eventInvitations': [eventId],
          'response': 'pending',
        });
      } else {
        // Guest exists; get their ID
        var guestDoc = userQuery.docs.first;
        guestId = guestDoc.id;

        // Update their event invitations
        await guestDoc.reference.update({
          'eventInvitations': FieldValue.arrayUnion([eventId]),
        });
      }

      // Add guest to the event's participants list
      await _firestore.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayUnion([
          {
            'id': guestId,
            'email': guestEmail,
            'status': 'invited',
          }
        ]),
      });

      print("Invitation sent to $guestEmail");
    } catch (e) {
      print("Error sending invitation: $e");
      throw Exception("Failed to send invitation");
    }
  }

  // Update the response of a guest to an invitation
  Future<void> updateGuestResponse({
    required String eventId,
    required String guestId,
    required String response,
  }) async {
    try {
      var eventDoc = await _firestore.collection('events').doc(eventId).get();

      if (eventDoc.exists) {
        // Retrieve participants and find the guest to update
        List<dynamic> participants = eventDoc['participants'] ?? [];
        int index = participants.indexWhere((guest) => guest['id'] == guestId);

        if (index != -1) {
          participants[index]['status'] = response;

          // Update the participants array in Firestore
          await _firestore.collection('events').doc(eventId).update({
            'participants': participants,
          });

          print("Guest response updated: $response");
        } else {
          throw Exception("Guest not found in event participants");
        }
      } else {
        throw Exception("Event not found");
      }
    } catch (e) {
      print("Error updating guest response: $e");
      throw Exception("Failed to update guest response");
    }
  }

  // Get guests for a specific event
Future<List<Map<String, dynamic>>> getGuests(String eventId) async {
  var eventDoc = await _firestore.collection('events').doc(eventId).get();

  if (eventDoc.exists) {
    // Pridobimo seznam gostov (participants) iz dogodka
    List<dynamic> participants = eventDoc['participants'] ?? [];
    List<Map<String, dynamic>> guests = [];

    for (var participant in participants) {
      if (participant is Map<String, dynamic>) {
        // Dodamo ID gostu, da bomo vedeli, kateri gost je to
        participant['id'] = eventDoc.id; 
        guests.add(participant);
      }
    }
    return guests;
  } else {
    throw Exception('Event not found');
  }
}


  // Add a new guest to an event
  Future<void> addGuest({
    required String eventId,
    required String name,
    required String email,
    required String status,
  }) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayUnion([
          {
            'name': name,
            'email': email,
            'status': status,
          }
        ]),
      });
      print("Guest added successfully");
    } catch (e) {
      print("Error adding guest: $e");
      throw Exception("Failed to add guest");
    }
  }

  Future<void> updateGuest({
  required String eventId,
  required String guestName, // Uporabimo ime gosta za iskanje
  required String guestEmail, // Uporabimo email gosta za iskanje
  String? name,
  String? email,
  String? status,
}) async {
  var eventDoc = await _firestore.collection('events').doc(eventId).get();

  if (eventDoc.exists) {
    List<dynamic> participants = eventDoc['participants'] ?? [];

    // Poiščemo gosta z uporabo imena in e-poštnega naslova
    var guestIndex = participants.indexWhere((guest) =>
        guest['name'] == guestName && guest['email'] == guestEmail);

    if (guestIndex != -1) {
      var updatedData = <String, dynamic>{};

      // Posodobimo lastnosti, če so podani
      if (name != null) updatedData['name'] = name;
      if (email != null) updatedData['email'] = email;
      if (status != null) updatedData['status'] = status;

      // Posodobimo gosta v seznamu
      participants[guestIndex] = {
        ...participants[guestIndex],
        ...updatedData,
      };

      // Shranimo posodobljeni seznam nazaj v dokument dogodka
      await _firestore.collection('events').doc(eventId).update({
        'participants': participants,
      });
    } else {
      throw Exception('Guest not found');
    }
  } else {
    throw Exception('Event not found');
  }
}






  // Delete a guest from an event
  Future<void> deleteGuest({
    required String eventId,
    required int guestId,
  }) async {
    try {
      var eventDoc = await _firestore.collection('events').doc(eventId).get();

      if (eventDoc.exists) {
        List<dynamic> participants = eventDoc['participants'] ?? [];
        
        if (guestId >= 0 && guestId < participants.length) {
          participants.removeAt(guestId);
        }
        await _firestore.collection('events').doc(eventId).update({
          'participants': participants,
        });

        print("Guest deleted successfully");
      } else {
        throw Exception("Event not found");
      }
    } catch (e) {
      print("Error deleting guest: $e");
      throw Exception("Failed to delete guest");
    }
  }
}