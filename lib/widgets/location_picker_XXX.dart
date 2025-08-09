import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../config/theme/colors.dart';
import 'package:animate_do/animate_do.dart';
import 'location_picker/state_picker_sheet.dart';
import 'location_picker/city_picker_sheet.dart';

class CustomLocationPicker extends StatelessWidget {
  final bool isDark;
  final Function(String) onCountryChanged;
  final Function(String) onStateChanged;
  final Function(String) onCityChanged;
  final String? selectedCountry;
  final String? selectedState;
  final String? selectedCity;
  final bool isLoading;
  final String? errorMessage;

  const CustomLocationPicker({
    Key? key,
    required this.isDark,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onCityChanged,
    this.selectedCountry,
    this.selectedState,
    this.selectedCity,
    this.isLoading = false,
    this.errorMessage,
  }) : super(key: key);

  Widget _buildDropdownField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
    bool enabled = true,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 24,
                  ),
                if (icon != null)
                  const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value.isEmpty ? 'Select $label' : value,
                        style: TextStyle(
                          fontSize: 16,
                          color: value.isEmpty
                              ? (isDark ? Colors.white38 : Colors.black38)
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          duration: const Duration(milliseconds: 300),
          child: Column(
            children: [
              _buildDropdownField(
                label: 'Country',
                value: selectedCountry ?? '',
                isDark: isDark,
                icon: Icons.public,
                onTap: () {
                  showCountryPicker(
                    context: context,
                    showPhoneCode: false,
                    countryListTheme: CountryListThemeData(
                      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      textStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      searchTextStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      bottomSheetHeight: 500,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    onSelect: (Country country) {
                      onCountryChanged(country.name);
                    },
                  );
                },
              ),
              _buildDropdownField(
                label: 'State/Province',
                value: selectedState ?? '',
                isDark: isDark,
                icon: Icons.location_city,
                enabled: selectedCountry != null && selectedCountry!.isNotEmpty,
                onTap: () {
                  // Show state picker bottom sheet
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => StatePickerSheet(
                      isDark: isDark,
                      selectedCountry: selectedCountry ?? '',
                      onSelect: onStateChanged,
                    ),
                  );
                },
              ),
              _buildDropdownField(
                label: 'City',
                value: selectedCity ?? '',
                isDark: isDark,
                icon: Icons.location_on,
                enabled: selectedState != null && selectedState!.isNotEmpty,
                onTap: () {
                  // Show city picker bottom sheet
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => CityPickerSheet(
                      isDark: isDark,
                      selectedState: selectedState ?? '',
                      onSelect: onCityChanged,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (errorMessage != null)
          FadeIn(
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: Text(
                errorMessage!,
                style: TextStyle(
                  color: SafeJetColors.error,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
} 