import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/service_locator.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final serviceLocator = ServiceLocator();
    final isAdmin = serviceLocator.currentUser?.isAdmin ?? false;

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userProvider.users.isEmpty) {
          return Center(
            child: Text(
              isAdmin
                  ? 'No users yet. Add your first user!'
                  : 'No users available.',
            ),
          );
        }

        return ListView.builder(
          itemCount: userProvider.users.length,
          itemBuilder: (context, index) {
            final user = userProvider.users[index];

            // Only allow admin to use slidable actions
            if (isAdmin) {
              return Slidable(
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        if (user.id != null) {
                          userProvider.deleteUser(user.id!);
                        }
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: _buildUserListTile(user),
              );
            } else {
              // Regular users just see the list without slidable actions
              return _buildUserListTile(user);
            }
          },
        );
      },
    );
  }

  // Helper method to build user list tile
  Widget _buildUserListTile(User user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: Text(user.name.substring(0, 1).toUpperCase()),
        ),
        title: Text(
          user.name + (user.isAdmin ? ' (Admin)' : ''),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(user.email ?? 'No email'),
        trailing:
            user.phoneNumber != null
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.teal),
                    const SizedBox(width: 4),
                    Text(user.phoneNumber!),
                  ],
                )
                : null,
      ),
    );
  }
}
