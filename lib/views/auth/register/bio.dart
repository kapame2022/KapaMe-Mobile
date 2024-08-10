import 'package:flutter/material.dart';
import 'package:kapame/services/new_user.dart';
import 'package:provider/provider.dart';

class Bio extends StatefulWidget {
  const Bio({super.key});

  @override
  State<Bio> createState() => _BioState();
}

class _BioState extends State<Bio> {
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      // DateTime userDateOfBirth =
      //     Provider.of<UserState>(context, listen: false).dateOfBirth;
      Provider.of<UserState>(context, listen: false).updateDateOfBirth(picked);

      setState(() {
        selectedDate = picked;
      });

      //print(userDateOfBirth);
    }
  }

  @override
  Widget build(BuildContext context) {
    String selectedGender = Provider.of<UserState>(context).gender;
    DateTime userDateOfBirth = Provider.of<UserState>(context).dateOfBirth;
    return Column(
      children: [
        const SizedBox(height: 30),
        FilledButton(
          onPressed: () => _selectDate(context),
          style: ButtonStyle(
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
            ),
            minimumSize: const WidgetStatePropertyAll(
              Size(double.infinity, 60),
            ),
            backgroundColor: WidgetStatePropertyAll(Colors.grey.shade200),
          ),
          child: Text(
            '${userDateOfBirth.day}/${userDateOfBirth.month}/${userDateOfBirth.year}',
            style: const TextStyle(color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: DropdownButtonFormField<String>(
            hint: const Text('Select gender'),
            value: selectedGender,
            onChanged: (String? newValue) {
              String gender =
                  Provider.of<UserState>(context, listen: false).gender;
              Provider.of<UserState>(context, listen: false)
                  .updateGender(newValue ?? '');

              print(gender);
            },
            icon: const Icon(Icons.arrow_drop_down),
            alignment: Alignment.center,
            isExpanded: true,
            items: <String>['Select gender', 'Male', 'Female', 'Other']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 30)
      ],
    );
  }
}
