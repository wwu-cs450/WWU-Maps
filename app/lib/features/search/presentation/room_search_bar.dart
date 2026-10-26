import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wwu_maps_app/features/search/presentation/cubit/search_cubit.dart';

/// The search bar where the user types the room they want to go to.
class RoomSearchBar extends StatefulWidget {
  const RoomSearchBar({super.key});

  @override
  State<RoomSearchBar> createState() => _RoomSearchBarState();
}

class _RoomSearchBarState extends State<RoomSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<SearchCubit>().submit(_controller.text);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _controller,
      hintText: 'Search room number',
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _submit(),
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      trailing: [
        IconButton(
          tooltip: 'Search',
          icon: const Icon(Icons.search),
          onPressed: _submit,
        ),
      ],
    );
  }
}
