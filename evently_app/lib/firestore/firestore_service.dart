import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> addEvent({
    required String name,
    required DateTime date,
    required String location,
    required String createdByUid,
  }) async {
    await _firestore.collection('events').add({
      'name': name,
      'date': Timestamp.fromDate(date),
      'location': location,
      'createdBy': _firestore.doc('users/$createdByUid'),
      'participants': [],
      'tasks': [],
      'expenses': [],
    });
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
}
