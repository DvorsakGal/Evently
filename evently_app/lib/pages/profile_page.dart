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

  // Controller to manage bio input
  final TextEditingController _bioController = TextEditingController();

  // Boolean to manage edit mode
  bool _isEditing = false;

  // A method to get user's profile information from Firestore
  Future<Map<String, dynamic>> _getUserProfile() async {
    final doc = await _firebaseFirestore.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    } else {
      return {}; // Return an empty map if the document does not exist
    }
  }

  // A method to get user's profile picture color
  Future<String> _getProfilePictureColor() async {
    final doc = await _firebaseFirestore.collection('users').doc(user!.uid).get();
    return doc.data()?['profilePicture'] ?? '#000000';
  }

  // Method to display the profile icon
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
        final color = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);

        return CircleAvatar(
          backgroundColor: color,
          radius: 30,
          child: const Icon(Icons.person, size: 30),
        );
      },
    );
  }

  // Method to update the bio in Firestore
  Future<void> _updateBio() async {
    try {
      final newBio = _bioController.text;
      // Update the bio in Firestore
      await _firebaseFirestore.collection('users').doc(user!.uid).update({
        'bio': newBio,
      });
      // Notify user that bio was updated
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bio updated successfully!")),
      );
      setState(() {
        _isEditing = false; // Exit edit mode after saving the bio
      });
    } catch (e) {
      // Handle error while updating
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error updating bio")),
      );
    }
  }

  // Method to sign out the user
  Future<void> signOut() async {
    await Auth().signOut();
  }

  // Method to display the user's email
  Widget _userUid() {
    return Text(user?.email ?? "User email");
  }

  // Sign out button
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Error loading profile"));
          }

          final userProfile = snapshot.data!;
          final name = userProfile['name'] ?? 'No Name';
          final email = userProfile['email'] ?? 'No Email';
          final bio = userProfile['bio'] ?? 'No bio available'; // Default if bio is missing

          // Set the current bio in the controller when the data is loaded
          _bioController.text = bio;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // This spaces content vertically
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Profile details with borders
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          _profileIcon(),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Name: $name',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Email: $email',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Bio section with a border
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bio:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          // Editable or non-editable Bio
                          _isEditing
                              ? Column(
                                  children: [
                                    // Editable bio field
                                    TextField(
                                      controller: _bioController,
                                      maxLines: 5,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter your bio...',
                                        border: InputBorder.none,
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),
                                    // Save button to save the bio
                                    ElevatedButton(
                                      onPressed: _updateBio,
                                      child: const Text('Save Bio'),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Text(
                                      _bioController.text, // Display the bio text
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 16.0),
                                    // Edit button to toggle edit mode
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = true; // Enable editing
                                        });
                                      },
                                      child: const Text('EDIT'),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Spacer pushes the sign-out button to the bottom
                Spacer(),
                _signOutButton(), // This will be at the bottom center
              ],
            ),
          );
        },
      ),
    );
  }

}
