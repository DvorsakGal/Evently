import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evently_app/pages/task_page.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    'tasks': [], // Inicializiraj prazno polje tasks
    'expenses': [],
  });

  return eventRef.id;
}

//----------------------------------------------
//  Za zdaj je kar se tice dela z id-jem zelo scuffed
//----------------------------------------------
  // eventi ki jih je ustvaril user (user trenutno nima v sebi gleda se glede na events createdBy)
  Future<List<Map<String, dynamic>>> getUserCreatedEvents(
      String uid
      ) async {

        //dobiš referenco
        var userRef = _firestore.collection('users').doc(uid);

        // vstop na events, vzames vse evente kjer je createdBy enak user referenci 
        var eventsSnapshot = await _firestore
        .collection('events')            
        .where('createdBy', isEqualTo: userRef)  
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

  // pridobivanje eventov glede na id eventa
  Future<Map<String, dynamic>> getSelectedEvent(
      String eid
      ) async {

        // vstop na events, vzames vse evente kjer je createdBy enak user referenci 
        var event = await _firestore
        .collection('events')            
        .doc(eid)  
        .get();                            


        if (event.exists) {
          // Return the event data as a Map
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

  Future<void> addTask({
  required String eventId,
  required String title,
  required String description,
  required String assignee,
  required String status,
}) async {
  try {
    print("Adding task to event: $eventId");
    print("Task details: $title, $description, $assignee, $status");

    // Ustvari podatke za nalogo, ki bo postala dokument v kolekciji `tasks`
    var task = {
      'title': title,
      'description': description,
      'assignee': assignee,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Ustvari nalogo kot nov dokument v kolekciji `tasks`
    var taskRef = await _firestore.collection('tasks').add(task);

    // Sedaj bomo dodali referenco na nalogo v kolekcijo `events`
    await _firestore.collection('events').doc(eventId).update({
      'tasks': FieldValue.arrayUnion([taskRef]),
    });

    print("Task added successfully to event: $eventId");
  } catch (e) {
    print("Error adding task: $e");
    throw Exception("Failed to add task");
  }
}





  Future<List<Map<String, dynamic>>> getTasks(String eventId) async {
  try {
    // Dobimo dokument dogodka
    var eventDoc = await _firestore.collection('events').doc(eventId).get();

    if (eventDoc.exists) {
      // Dobimo seznam referenc na naloge (vsaka je DocumentReference)
      List<dynamic> taskRefs = eventDoc['tasks'] ?? [];
      List<Map<String, dynamic>> tasks = [];

      // Preberemo naloge s pomočjo njihovih referenc
      for (var taskRef in taskRefs) {
        if (taskRef is DocumentReference) {
          var taskDoc = await taskRef.get();

          if (taskDoc.exists) {
            // Naloga bo shranjena v seznam
            Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;
            taskData['id'] = taskDoc.id; // Dodajemo ID naloge za lokalno uporabo
            tasks.add(taskData);
          }
        } else {
          print("Invalid reference found: $taskRef");
        }
      }

      return tasks;
    } else {
      throw Exception('Event not found');
    }
  } catch (e) {
    print("Error retrieving tasks: $e");
    throw Exception('Failed to get tasks');
  }
}



  Future<void> updateTask({
  required String eventId,
  required String taskId,
  String? title,
  String? description,
  String? status,
}) async {
  try {
    // Dobimo dokument dogodka
    var eventDoc = await _firestore.collection('events').doc(eventId).get();
    
    if (eventDoc.exists) {
      // Dobimo seznam referenc na naloge (vsaka je DocumentReference)
      List<dynamic> taskRefs = eventDoc['tasks'] ?? [];
      DocumentReference? taskRef;

      // Poiščemo referenco naloge z ustreznim taskId
      for (var ref in taskRefs) {
        if (ref is DocumentReference && ref.id == taskId) {
          taskRef = ref;
          break;
        }
      }

      if (taskRef != null) {
        // Posodabljanje naloge v kolekciji tasks
        var taskDoc = await taskRef.get();
        if (taskDoc.exists) {
          var updatedData = <String, dynamic>{};
          if (title != null) updatedData['title'] = title;
          if (description != null) updatedData['description'] = description;
          if (status != null) updatedData['status'] = status;

          // Posodabljamo nalogo v kolekciji tasks
          await taskRef.update(updatedData);
          print("Task updated successfully");
        } else {
          throw Exception('Task not found');
        }
      } else {
        throw Exception('Task reference not found in the event');
      }
    } else {
      throw Exception('Event not found');
    }
  } catch (e) {
    print("Error updating task: $e");
    throw Exception('Failed to update task');
  }
}


  Future<void> deleteTask({
  required String eventId,
  required String taskId,
}) async {
  try {
    // Dobimo dokument dogodka
    var eventDoc = await _firestore.collection('events').doc(eventId).get();
    
    if (eventDoc.exists) {
      // Dobimo seznam referenc na naloge (vsaka je DocumentReference)
      List<dynamic> taskRefs = eventDoc['tasks'] ?? [];
      DocumentReference? taskRef;

      // Poiščemo referenco naloge z ustreznim taskId
      for (var ref in taskRefs) {
        if (ref is DocumentReference && ref.id == taskId) {
          taskRef = ref;
          break;
        }
      }

      if (taskRef != null) {
        // Najprej odstranimo nalogo iz kolekcije tasks
        await taskRef.delete();
        print("Task deleted successfully");

        // Odstranimo referenco naloge iz eventa
        await _firestore.collection('events').doc(eventId).update({
          'tasks': FieldValue.arrayRemove([taskRef]),
        });
      } else {
        throw Exception('Task reference not found in the event');
      }
    } else {
      throw Exception('Event not found');
    }
  } catch (e) {
    print("Error deleting task: $e");
    throw Exception('Failed to delete task');
  }
}

}
