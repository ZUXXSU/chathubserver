import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/features/auth/widgets/auth_text_field.dart';
import 'package:flutter_app/features/profile/controllers/search_controller.dart';
import 'package:flutter_app/features/profile/widgets/search_result_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A screen that allows the user to search for other users.
///
/// Uses [GetX] to manage state with [SearchController].
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the SearchController
    final CustomSearchController controller = Get.put(CustomSearchController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Input Field
            AuthTextField(
              controller: TextEditingController(), // Controller is handled by onChanged
              // hintText: 'Search by name...',
              icon: Icons.search,
              // onChanged: (query) {
              //   controller.searchUser(query);
              // }, 
              labelText: 'Search',
            ),
            const SizedBox(height: 20),
            
            // Search Results
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: ChatHubTheme.primary),
                  );
                }

                if (!controller.hasSearched.value) {
                  return const Center(
                    child: Text(
                      'Type a name to find users.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                if (controller.searchResults.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = controller.searchResults[index];
                    return SearchResultTile(user: user, controller: controller);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
