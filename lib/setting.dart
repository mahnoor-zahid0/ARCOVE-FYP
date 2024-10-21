import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart';

// Main Settings Page
class SettingsMainPage extends StatelessWidget {
  final bool isLoggedIn;

  const SettingsMainPage({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          UserHeader(isLoggedIn: isLoggedIn),
          SettingsItem(
            icon: Icons.person,
            text: 'Account',
            onTap: isLoggedIn
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountSettingsPage()),
              );
            }
                : null, // Disabled when logged out
          ),
          SettingsItem(
            icon: Icons.security,
            text: 'Privacy',
            onTap: isLoggedIn
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacySettingsPage()),
              );
            }
                : null, // Disabled when logged out
          ),
          SettingsItem(
            icon: Icons.notifications,
            text: 'Notifications',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsSettingsPage()),
              );
            },
          ),
          SettingsItem(
            icon: Icons.help,
            text: 'Help & Support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpSupportPage()),
              );
            },
          ),
          SettingsItem(
            icon: isLoggedIn ? Icons.logout : Icons.login,
            text: isLoggedIn ? 'Logout' : 'Login',
            onTap: () {
              if (isLoggedIn) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage(isLoggedIn: false)),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()), // Redirect to login page
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
`

// User Header Widget
class UserHeader extends StatelessWidget {
  final bool isLoggedIn;

  const UserHeader({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: isLoggedIn
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(
                    currentName: 'Current User Name', // Pass the actual current name
                    currentProfilePictureUrl: 'https://via.placeholder.com/150', // Pass current profile pic URL
                  ),
                ),
              ).then((updatedData) {
                // You can update the profile picture or name here if needed based on the returned data
                if (updatedData != null) {
                  print('Updated name: ${updatedData['newName']}');
                  print('Updated profile picture: ${updatedData['newProfilePicture']}');
                }
              });
            }
                : null,
            child: const CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLoggedIn ? 'User Name' : 'Guest',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: isLoggedIn
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(
                        currentName: 'User Name',
                        currentProfilePictureUrl: 'https://via.placeholder.com/150',
                      ),
                    ),
                  );
                }
                    : null, // Disable editing when logged out
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: isLoggedIn ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Edit Profile',
                      style: TextStyle(color: isLoggedIn ? Colors.blue : Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Reusable Settings Item Widget
class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const SettingsItem({
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: onTap,
      enabled: onTap != null, // Disabled if no onTap function is provided
    );
  }
}

// Account Settings Page
class AccountSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: ListView(
        children: [
          SettingsItem(
            icon: Icons.lock,
            text: 'Two-step verification',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TwoStepVerificationPage()),
              );
            },
          ),
          SettingsItem(
            icon: Icons.notifications,
            text: 'Security notifications',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SecurityNotificationsPage()),
              );
            },
          ),
          SettingsItem(
            icon: Icons.email,
            text: 'Change Email',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangeEmailPage()),
              );
            },
          ),
          const Divider(),
          SettingsItem(
            icon: Icons.delete,
            text: 'Delete my account',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeleteAccountPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Privacy Settings Page (Updated)
class PrivacySettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy'),
      ),
      body: ListView(
        children: [
          SettingsItem(
            icon: Icons.block,
            text: 'Blocked contacts',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BlockedContactsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Two-step Verification Page
class TwoStepVerificationPage extends StatefulWidget {
  @override
  _TwoStepVerificationPageState createState() => _TwoStepVerificationPageState();
}

class _TwoStepVerificationPageState extends State<TwoStepVerificationPage> {
  bool isTwoStepEnabled = false;
  String verificationCode = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-step Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enable Two-step Verification to add an extra layer of security to your account.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Enable Two-step Verification'),
              value: isTwoStepEnabled,
              onChanged: (bool value) {
                setState(() {
                  isTwoStepEnabled = value;
                });
              },
            ),
            if (isTwoStepEnabled) ...[
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Enter Verification Code',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  verificationCode = value;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (verificationCode.isNotEmpty) {
                    print('Two-step verification code saved: $verificationCode');
                  }
                },
                child: const Text('Save Verification Code'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Notifications Settings Page
class NotificationsSettingsPage extends StatefulWidget {
  @override
  _NotificationsSettingsPageState createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool isMessageNotificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Message notifications'),
            value: isMessageNotificationEnabled,
            onChanged: (bool value) {
              setState(() {
                isMessageNotificationEnabled = value;
              });
              if (isMessageNotificationEnabled) {
                print('Message notifications enabled');
              } else {
                print('Message notifications disabled');
              }
            },
            subtitle: const Text('Receive notifications and sound when someone messages you.'),
          ),
        ],
      ),
    );
  }
}

// Help & Support Page
class HelpSupportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        children: [
          SettingsItem(
            icon: Icons.help_outline,
            text: 'Help Center',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpCenterPage()),
              );
            },
          ),
          SettingsItem(
            icon: Icons.privacy_tip_outlined,
            text: 'Terms and Privacy Policy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermsPrivacyPolicyPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Security Notifications Page
class SecurityNotificationsPage extends StatefulWidget {
  @override
  _SecurityNotificationsPageState createState() =>
      _SecurityNotificationsPageState();
}

class _SecurityNotificationsPageState extends State<SecurityNotificationsPage> {
  bool areSecurityNotificationsEnabled = true;
  bool isLoginNotificationEnabled = true;
  bool isPasswordChangeNotificationEnabled = true;
  bool isNewDeviceLoginNotificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Manage your security notifications. Enable or disable notifications for important security changes.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Enable All Security Notifications'),
              value: areSecurityNotificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  areSecurityNotificationsEnabled = value;

                  // If all notifications are disabled, the rest of the switches will also turn off
                  if (!areSecurityNotificationsEnabled) {
                    isLoginNotificationEnabled = false;
                    isPasswordChangeNotificationEnabled = false;
                    isNewDeviceLoginNotificationEnabled = false;
                  }
                });
              },
            ),
            const Divider(),

            // Login Notification Toggle
            SwitchListTile(
              title: const Text('Login Notification'),
              subtitle: const Text('Notify when your account is logged into.'),
              value: isLoginNotificationEnabled,
              onChanged: areSecurityNotificationsEnabled
                  ? (bool value) {
                setState(() {
                  isLoginNotificationEnabled = value;
                });
                print('Login notifications: ${value ? 'Enabled' : 'Disabled'}');
              }
                  : null, // Disable if all notifications are off
            ),
            const Divider(),

            // Password Change Notification Toggle
            SwitchListTile(
              title: const Text('Password Change Notification'),
              subtitle:
              const Text('Notify when your account password is changed.'),
              value: isPasswordChangeNotificationEnabled,
              onChanged: areSecurityNotificationsEnabled
                  ? (bool value) {
                setState(() {
                  isPasswordChangeNotificationEnabled = value;
                });
                print('Password Change notifications: ${value ? 'Enabled' : 'Disabled'}');
              }
                  : null, // Disable if all notifications are off
            ),
            const Divider(),

            // New Device Login Notification Toggle
            SwitchListTile(
              title: const Text('New Device Login Notification'),
              subtitle: const Text('Notify when your account is accessed from a new device.'),
              value: isNewDeviceLoginNotificationEnabled,
              onChanged: areSecurityNotificationsEnabled
                  ? (bool value) {
                setState(() {
                  isNewDeviceLoginNotificationEnabled = value;
                });
                print('New Device Login notifications: ${value ? 'Enabled' : 'Disabled'}');
              }
                  : null, // Disable if all notifications are off
            ),
          ],
        ),
      ),
    );
  }
}

// Change Email Page
class ChangeEmailPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Enter new email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final newEmail = emailController.text;
                if (newEmail.isNotEmpty) {
                  print('Email changed to: $newEmail');
                  // Logic to change email goes here
                }
              },
              child: const Text('Change Email'),
            ),
          ],
        ),
      ),
    );
  }
}

// Delete Account Page
class DeleteAccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete My Account'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Are you sure you want to delete your account?'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Logic to delete account
                print('Account deleted');
              },
              child: const Text('Delete My Account'),
            ),
          ],
        ),
      ),
    );
  }
}

// Blocked Contacts Page
class BlockedContactsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Contacts'),
      ),
      body: const Center(
        child: Text('View and manage blocked contacts.'),
      ),
    );
  }
}

// Help Center Page
class HelpCenterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Here you can find help for common issues.'),
      ),
    );
  }
}

// Terms and Privacy Policy Page
class TermsPrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Privacy Policy'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Terms and Privacy Policy details go here.'),
      ),
    );
  }
}


class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String currentProfilePictureUrl;

  const EditProfilePage({Key? key, required this.currentName, required this.currentProfilePictureUrl}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // For Firestore

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Function to save profile changes (name and profile picture)
  Future<void> _saveProfileChanges() async {
    final newName = _nameController.text;
    if (newName.isEmpty) {
      // Handle empty name case
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    try {
      // Get the current user's UID
      User? user = _auth.currentUser;
      if (user == null) {
        throw 'User not logged in';
      }

      String uid = user.uid;

      // Assuming you're using Firebase Storage for profile pictures
      String? profileImageUrl;

      if (_profileImage != null) {
        // Upload the new profile picture to Firebase Storage
        final ref = FirebaseStorage.instance.ref().child('users/$uid/profile.jpg');
        await ref.putFile(_profileImage!);
        profileImageUrl = await ref.getDownloadURL();
      }

      // Update the Firestore document with the new name and profile picture
      await _firestore.collection('users').doc(uid).update({
        'name': newName,
        if (profileImageUrl != null) 'profilePicture': profileImageUrl, // Only update if a new picture was uploaded
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      // After saving, pop the current page to go back
      Navigator.pop(context, {'newName': newName, 'newProfilePicture': profileImageUrl});
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfileChanges, // Save changes
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage, // Open gallery to pick image
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : NetworkImage(widget.currentProfilePictureUrl) as ImageProvider,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfileChanges,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
