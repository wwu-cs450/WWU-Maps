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
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Rebuild so the building prefix appears and disappears with focus and text.
    _focusNode.addListener(() => setState(() {}));
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<SearchCubit>().submit(_controller.text);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Shown while typing, and kept afterwards so the room reads as "KRH 101".
  bool get _showPrefix => _focusNode.hasFocus || _controller.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _controller,
      focusNode: _focusNode,
      leading: _showPrefix
          ? Padding(
              padding: const EdgeInsetsDirectional.only(start: 16),
              child: Text(
                'KRH',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
      hintText: _focusNode.hasFocus ? null : 'Search room number',
      keyboardType: TextInputType.number,
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
