import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evently_app/auth.dart';
import 'package:evently_app/firestore/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
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

        return CircleAvatar(
          backgroundColor: color,
          radius: 20,
          child: const Icon(Icons.person),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _profileIcon(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _userUid(),
                _profileIcon(),
              ],
            ),
            _signOutButton(),
          ],
        ),
      ),
    );
  }
}
