import 'package:flutter/material.dart';
import 'merge_pdf_screen.dart';
import 'split_pdf_screen.dart';
import 'add_remove_pages_screen.dart';
import 'reorder_pages_screen.dart';
import 'add_watermark_screen.dart';
import 'add_password_screen.dart';

class EditPdfScreen extends StatelessWidget {
  const EditPdfScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit PDF'),
        backgroundColor: Colors.blue.shade700,
        actions: [],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Text('Powerful PDF Editing',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                const SizedBox(height: 4),
                Text('Choose a tool below to edit your PDFs',
                  style: TextStyle(fontSize: 15, color: Colors.blueGrey)),
              ],
            ),
          ),
          _buildGradientCard(
            context,
            title: 'Merge PDFs',
            subtitle: 'Combine multiple PDFs into one',
            icon: Icons.merge_type,
            gradient: LinearGradient(colors: [Colors.blue, Colors.purpleAccent]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MergePDFScreen()),
              );
            },
          ),
          const SizedBox(height: 6),
          _buildGradientCard(
            context,
            title: 'Add Password',
            subtitle: 'Protect your PDF with a password',
            icon: Icons.lock,
            gradient: LinearGradient(colors: [Colors.indigo, Colors.blue]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPasswordScreen()),
              );
            },
          ),
          const SizedBox(height: 6),
          _buildGradientCard(
            context,
            title: 'Split PDF',
            subtitle: 'Extract specific pages from a PDF',
            icon: Icons.call_split,
            gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrangeAccent]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SplitPDFScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildGradientCard(
            context,
            title: 'Add/Remove Pages',
            subtitle: 'Insert, delete, or import pages',
            icon: Icons.add_circle_outline,
            gradient: LinearGradient(colors: [Colors.green, Colors.teal]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddRemovePagesScreen()),
              );
            },
          ),
          const SizedBox(height: 6),
          _buildGradientCard(
            context,
            title: 'Reorder Pages',
            subtitle: 'Change the order of PDF pages',
            icon: Icons.swap_vert,
            gradient: LinearGradient(colors: [Colors.purple, Colors.deepPurpleAccent]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReorderPagesScreen()),
              );
            },
          ),
          const SizedBox(height: 6),
          _buildGradientCard(
            context,
            title: 'Add Watermark',
            subtitle: 'Insert watermark text or image',
            icon: Icons.opacity,
            gradient: LinearGradient(colors: [Colors.blueGrey, Colors.blue]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddWatermarkScreen()),
              );
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'More editing features coming soon!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Implement navigation to feature
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Feature "$title" coming soon!')),
          );
        },
      ),
    );
  }

  Widget _buildGradientCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Gradient gradient, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
