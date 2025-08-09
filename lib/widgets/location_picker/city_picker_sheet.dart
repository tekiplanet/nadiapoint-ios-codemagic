import 'package:flutter/material.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart' as csc;

class CityPickerSheet extends StatelessWidget {
  final bool isDark;
  final String selectedState;
  final Function(String) onSelect;

  const CityPickerSheet({
    Key? key,
    required this.isDark,
    required this.selectedState,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get cities from the package's data
    final cities = csc.CityCustom.getCitiesFromState(selectedState);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select City',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: cities.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    cities[index],
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () {
                    onSelect(cities[index]);
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