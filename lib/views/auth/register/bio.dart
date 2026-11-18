import 'package:flutter/material.dart';
import 'package:kapame/services/new_user.dart';
import 'package:provider/provider.dart';

class Bio extends StatelessWidget {
  const Bio({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserState>();
    final selectedGender =
        ['Male', 'Female', 'Other'].contains(user.gender) ? user.gender : null;
    final date = user.hasSelectedDateOfBirth
        ? MaterialLocalizations.of(context).formatMediumDate(user.dateOfBirth)
        : '';
    return Column(children: [
      TextFormField(
        key: ValueKey(date),
        initialValue: date,
        readOnly: true,
        decoration: const InputDecoration(
          constraints: BoxConstraints(minHeight: 72),
          labelText: 'Date of birth',
          hintText: 'Select date of birth',
          floatingLabelStyle: TextStyle(fontSize: 16),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        validator: (_) =>
            user.hasSelectedDateOfBirth ? null : 'Select your date of birth',
        onTap: () async {
          final today = DateUtils.dateOnly(DateTime.now());
          final saved = user.dateOfBirth;
          final picked = await showDatePicker(
            context: context,
            helpText: 'Date of birth',
            initialDate: user.hasSelectedDateOfBirth && !saved.isAfter(today)
                ? saved
                : today,
            firstDate: DateTime(1900),
            lastDate: today,
          );
          if (picked != null && context.mounted) user.updateDateOfBirth(picked);
        },
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: selectedGender,
        isExpanded: true,
        decoration: const InputDecoration(
            constraints: BoxConstraints(minHeight: 72),
            labelText: 'Gender',
            floatingLabelStyle: TextStyle(fontSize: 16),
            floatingLabelBehavior: FloatingLabelBehavior.always),
        hint: const Text('Select gender'),
        items: const ['Male', 'Female', 'Other']
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) {
          if (value != null) user.updateGender(value);
        },
        validator: (value) => value == null ? 'Select your gender' : null,
      ),
    ]);
  }
}
