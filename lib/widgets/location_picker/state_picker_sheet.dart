import 'package:flutter/material.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart' as csc;

class StatePickerSheet extends StatelessWidget {
  final bool isDark;
  final String selectedCountry;
  final Function(String) onSelect;

  const StatePickerSheet({
    Key? key,
    required this.isDark,
    required this.selectedCountry,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get states from the package's data
    final states = csc.StateCustom.getStatesFromCountry(selectedCountry);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select State',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: states.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    states[index],
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () {
                    onSelect(states[index]);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 