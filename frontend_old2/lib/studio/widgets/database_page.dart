import 'package:flutter/material.dart';
import '../../globals.dart';

class DatabasePage extends StatefulWidget {
  const DatabasePage({super.key});

  @override
  State<DatabasePage> createState() => _DatabasePageState();
}

class _DatabasePageState extends State<DatabasePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Pallet.inside2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Pallet.divider),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Pallet.inside3,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.storage,
                  color: Pallet.font1,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Database Management',
                  style: TextStyle(
                    color: Pallet.font1,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Add database connection functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Database connection feature coming soon!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Connect Database'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7363E0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.storage_outlined,
                    size: 80,
                    color: Pallet.font2,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Database Connected',
                    style: TextStyle(
                      color: Pallet.font1,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Connect to a database to start managing your data.\nSupported databases: PostgreSQL, MySQL, SQLite, MongoDB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Pallet.font2,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Database Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDatabaseOption(
                        icon: Icons.storage,
                        title: 'SQLite',
                        description: 'Local database',
                        onTap: () => _showDatabaseDialog('SQLite'),
                      ),
                      const SizedBox(width: 16),
                      _buildDatabaseOption(
                        icon: Icons.cloud,
                        title: 'PostgreSQL',
                        description: 'Cloud database',
                        onTap: () => _showDatabaseDialog('PostgreSQL'),
                      ),
                      const SizedBox(width: 16),
                      _buildDatabaseOption(
                        icon: Icons.dns,
                        title: 'MySQL',
                        description: 'Web database',
                        onTap: () => _showDatabaseDialog('MySQL'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Pallet.inside3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Pallet.divider),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF7363E0),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Pallet.font1,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Pallet.font2,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDatabaseDialog(String databaseType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Pallet.inside2,
        title: Text(
          'Connect to $databaseType',
          style: TextStyle(color: Pallet.font1),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Database connection configuration will be implemented here.',
              style: TextStyle(color: Pallet.font2),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Connection String',
                labelStyle: TextStyle(color: Pallet.font2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Pallet.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF7363E0)),
                ),
              ),
              style: TextStyle(color: Pallet.font1),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Pallet.font2),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$databaseType connection feature coming soon!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7363E0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
