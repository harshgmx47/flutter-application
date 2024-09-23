import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/main.dart';
import 'package:intl/intl.dart';

class EmployeeForm extends StatefulWidget {
  @override
  _EmployeeFormState createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _hireDateController = TextEditingController();

  // Method Channel to communicate with native Android
  static const platform = MethodChannel('flutter.native/sql');

  // Selected project
  Project? _selectedProject;
  List<Project> _projects = [
    Project(projectId: 1, projectName: 'Project Alpha'),
    Project(projectId: 2, projectName: 'Project Beta'),
  ];

  // Method to call the platform channel and add a new employee
  Future<void> _addEmployee() async {
    try {
      final String firstName = _firstNameController.text;
      final String lastName = _lastNameController.text;
      final double salary = double.parse(_salaryController.text);
      final String hireDate = _hireDateController.text;
      final int projectId = _selectedProject?.projectId ?? 0;

      if (_formKey.currentState!.validate()) {
        final String result = await platform.invokeMethod('addNewEmployee', {
          'firstName': firstName,
          'lastName': lastName,
          'salary': salary,
          'hireDate': hireDate,
          'projectId': projectId,
          'status': 'No Started',
        });

        if (result == "success") {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'New employee and project assignment created successfully.'),
          ));

          // Optionally refresh the employee list after update
          ;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to update employee details.'),
          ));
        }
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add employee: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Employee'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // First Name Field
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter first name';
                  }
                  return null;
                },
              ),
              // Last Name Field
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter last name';
                  }
                  return null;
                },
              ),
              // Salary Field
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(labelText: 'Salary'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter salary';
                  }
                  return null;
                },
              ),
              // Hire Date Field
              TextFormField(
                controller: _hireDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Hire Date (YYYY-MM-DD)',
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (pickedDate != null) {
                    String formattedDate =
                        DateFormat('yyyy-MM-dd').format(pickedDate);
                    _hireDateController.text = formattedDate;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a hire date';
                  }
                  return null;
                },
              ),
              // Project Dropdown
              DropdownButtonFormField<Project>(
                value: _selectedProject,
                hint: const Text('Select Project'),
                items: _projects.map((Project project) {
                  return DropdownMenuItem<Project>(
                    value: project,
                    child: Text(project.projectName),
                  );
                }).toList(),
                onChanged: (Project? newValue) {
                  setState(() {
                    _selectedProject = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a project';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addEmployee,
                child: const Text('Create Employee'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Project {
  final int projectId;
  final String projectName;

  Project({required this.projectId, required this.projectName});
}
