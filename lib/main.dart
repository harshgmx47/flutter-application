import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/addnewEmployee.dart';
import 'package:flutter_application_1/test.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('flutter.native/sql');
  String _connectionStatus = 'Unknown';
  List<Employee> employees = [];
  String _employeeData = "";

  // Input controllers for the update form

  Future<void> _updateEmployeeDetails(
      int employeeId, double salary, String projectStatus) async {
    try {
      // Invoke native method to update the employee details
      final String result = await platform.invokeMethod('updateEmployee', {
        'employeeId': employeeId,
        'salary': salary,
        'status': projectStatus,
      });

      // Handle success or failure
      if (result == "Employee updated successfully.") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Employee details updated successfully!'),
        ));

        // Optionally refresh the employee list after update
        _fetchEmployees();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to update employee details.'),
        ));
      }
    } on PlatformException catch (e) {
      print(e.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating employee: ${e.message}'),
      ));
    }
  }

  Future<void> testSQLConnection() async {
    try {
      final String result = await platform.invokeMethod('testConnection');
      setState(() {
        _connectionStatus = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        _connectionStatus = "Failed to connect: '${e.message}'.";
      });
    }
  }

  Future<void> _fetchEmployees() async {
    try {
      final String result = await platform.invokeMethod('getEmployees');
      // setState(() {
      //   // _employeeData = result;
      // });
      parseEmployeeData(result);
    } on PlatformException catch (e) {
      setState(() {
        _employeeData = "Failed to get employees: '${e.message}'.";
      });
    }
  }

// Parse the returned employee data from the native side
  void parseEmployeeData(String data) {
    List<Employee> tempEmployees = [];
    //  data is returned in a string format where each row is separated by a newline
    List<String> rows = data.split('\n');

    for (String row in rows) {
      if (row.isNotEmpty) {
        List<String> fields =
            row.split(','); // Assuming fields are comma-separated
        if (fields.isNotEmpty) {
          tempEmployees.add(Employee(
            id: int.tryParse(fields[0]) ?? 0,
            Name: fields[1],
            department: fields[2],
            project: fields[3],
          ));
        }
      }
    }
    setState(() {
      employees = tempEmployees;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(CupertinoPageRoute(builder: (_) => EmployeeForm()));
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.greenAccent,
      ),
      body: RefreshIndicator(
        onRefresh: () async => await _fetchEmployees(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(
                          label: Text(
                        "EmployeeID",
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                            color: Colors.black),
                      )),
                      DataColumn(
                          label: Text(
                        "Name",
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                            color: Colors.black),
                      )),
                      DataColumn(
                          label: Text(
                        "Department",
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                            color: Colors.black),
                      )),
                      DataColumn(
                          label: Text(
                        "Project",
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                            color: Colors.black),
                      )),
                      DataColumn(
                          label: Text(
                        "Update",
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                            color: Colors.black),
                      ))
                    ],
                    border: TableBorder.all(),
                    headingRowColor:
                        MaterialStateProperty.resolveWith((Set states) {
                      if (states.contains(MaterialState.hovered)) {
                        return Colors.amber;
                      }
                      return Colors.deepOrange; // Use the default value.
                    }),
                    rows: employees.asMap().entries.map((entry) {
                      int index = entry.key;
                      final data = entry.value;

                      return DataRow(
                          key: ValueKey<int>(index),
                          color: MaterialStateColor.resolveWith(
                              (states) => Colors.white),
                          cells: [
                            DataCell(Text(data.id.toString())),
                            DataCell(
                                Text(data.Name!.isEmpty ? "" : data.Name!)),
                            DataCell(Text(data.department!.isEmpty
                                ? ""
                                : data.department!)),
                            DataCell(Text(
                                data.project!.isEmpty ? "" : data.project!)),
                            DataCell(IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                fetchEmployeeDetails(data.id!);
                              },
                            )),
                          ]);
                    }).toList(),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> fetchEmployeeDetails(int employeeId) async {
    try {
      final String result = await platform
          .invokeMethod('getEmployeeDetails', {'employeeId': employeeId});
      // Parse the result (assuming it's in the format "id,salary,projectStatus")
      List<String> details = result.split(',');
      if (details.length == 3) {
        int id = int.parse(details[0]);
        double salary = double.parse(details[1]);
        String projectStatus = details[2];

        // Show the update dialog with fetched salary and project status
        _showUpdateDialog(Employee(
          id: id,
          Name: '',
          department: '', // The department info can be omitted if not needed
          project: '', // Similarly, project can be omitted if not needed
          Salary: salary,
          status: projectStatus,
        ));
      }
    } on PlatformException catch (e) {
      print("Failed to get employee details: '${e.message}'.");
    }
  }

  void _showUpdateDialog(Employee employee) {
    TextEditingController salaryController =
        TextEditingController(text: employee.Salary.toString());
    TextEditingController statusController =
        TextEditingController(text: employee.status);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Employee Details'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                // Display Employee ID (Read-Only)
                // TextFormField(
                //   decoration: const InputDecoration(
                //     labelText: 'Employee ID',
                //   ),
                //   initialValue: employee.id.toString(),
                //   readOnly: true,
                // ),
                const SizedBox(height: 10),
                // Input for Employee Salary
                TextField(
                  controller: salaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Salary',
                  ),
                ),
                const SizedBox(height: 10),
                // Input for Employee Project Status
                TextField(
                  controller: statusController,
                  decoration: const InputDecoration(
                    labelText: 'Project Status',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            // Cancel Button
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // Update Button
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                // Get updated values from text fields
                String updatedSalary = salaryController.text;
                String updatedProjectStatus = statusController.text;

                if (updatedSalary.isEmpty || updatedProjectStatus.isEmpty) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("All fields must be filled!"),
                  ));
                } else {
                  // Call the update method with the new values
                  _updateEmployeeDetails(
                    employee.id!,
                    double.parse(updatedSalary),
                    updatedProjectStatus,
                  );

                  Navigator.of(context)
                      .pop(); // Close the dialog after updating
                }
              },
            ),
          ],
        );
      },
    );
  }
}
