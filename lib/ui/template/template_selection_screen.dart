import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/logic/template/template_model.dart';
import 'package:pro_coding_studio/logic/template/template_provider.dart';
import 'package:pro_coding_studio/ui/template/template_details_screen.dart';

/// Screen for selecting a project template
class TemplateSelectionScreen extends ConsumerWidget {
  final String projectDirectory; // Directory where templates will be saved
  final String originalDirectory; // User's selected directory
  final bool isContentUri; // Whether the original directory is a content URI

  const TemplateSelectionScreen({
    Key? key,
    required this.projectDirectory,
    required this.originalDirectory,
    required this.isContentUri,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(templateCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        title: const Text('Select Template'),
        backgroundColor: const Color(0xFF22242A),
        elevation: 0,
      ),
      body: categoriesAsync.when(
        data: (categories) => _buildCategoriesView(context, ref, categories),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error loading templates: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesView(
      BuildContext context, WidgetRef ref, List<TemplateCategory> categories) {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'No templates available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Get the selected category or use the first one
    final selectedCategory =
        ref.watch(selectedCategoryProvider) ?? categories.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category tabs
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category.id == selectedCategory.id;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: InkWell(
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).state =
                        category;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF64FFDA)
                          : const Color(0xFF23262F),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      category.name,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Templates grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8, // Increased from 0.75 to give more height
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: selectedCategory.templates.length,
            itemBuilder: (context, index) {
              final template = selectedCategory.templates[index];
              return _buildTemplateCard(context, ref, template);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(
      BuildContext context, WidgetRef ref, Template template) {
    return InkWell(
      onTap: () {
        ref.read(selectedTemplateProvider.notifier).state = template;

        // Navigate to template details screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TemplateDetailsScreen(
              template: template,
              projectDirectory: projectDirectory,
              originalDirectory: originalDirectory,
              isContentUri: isContentUri,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF23262F),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Template preview image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  template.previewImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF2A2E3A),
                      child: const Center(
                        child: Icon(Icons.image_not_supported,
                            color: Colors.white54, size: 48),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Template info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        template.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        template.description,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
