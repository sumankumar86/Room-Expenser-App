import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';
import '../services/service_locator.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _serviceLocator = ServiceLocator();

  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final currentUser = _serviceLocator.currentUser;
    if (currentUser != null) {
      _nameController.text = currentUser.name;
      _emailController.text = currentUser.email ?? '';
      _phoneController.text = currentUser.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final currentUser = _serviceLocator.currentUser;

        if (currentUser == null) {
          setState(() {
            _errorMessage = 'No user data found';
            _isLoading = false;
          });
          return;
        }

        final updatedUser = User(
          id: currentUser.id,
          name: _nameController.text.trim(),
          email:
              _emailController.text.trim().isNotEmpty
                  ? _emailController.text.trim()
                  : null,
          phoneNumber:
              _phoneController.text.trim().isNotEmpty
                  ? _phoneController.text.trim()
                  : null,
          isAdmin: currentUser.isAdmin,
          role: currentUser.role,
        );

        final success = await userProvider.updateUser(updatedUser);

        if (success && mounted) {
          // Update the current user in the service locator
          _serviceLocator.setCurrentUser(updatedUser);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          setState(() {
            _isEditing = false;
          });
        } else if (mounted) {
          setState(() {
            _errorMessage = userProvider.error ?? 'Failed to update profile';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _serviceLocator.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('No user data found. Please log in again.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile icon
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.teal.shade100,
                    child: Text(
                      currentUser.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),

            // User role badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      currentUser.isAdmin
                          ? Colors.amber.shade100
                          : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currentUser.isAdmin ? 'Admin User' : 'Regular User',
                  style: TextStyle(
                    color:
                        currentUser.isAdmin
                            ? Colors.amber.shade900
                            : Colors.blue.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email field
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Phone field
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Edit/Save button
            ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        if (_isEditing) {
                          _updateProfile();
                        } else {
                          setState(() {
                            _isEditing = true;
                          });
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEditing ? Colors.green : Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isEditing ? 'Save Profile' : 'Edit Profile'),
            ),

            // Cancel button (only when editing)
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _loadUserData(); // Reset to original values
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),

            // Change password button
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/change_password');
                },
                icon: const Icon(Icons.password),
                label: const Text('Change Password'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
