class Employee {
  final int? id;
  final String? firstName;
  final String? Name;
  final String? lastName;
  final String? department;
  final String? project;
  final String? status;
  final double? Salary;
  DateTime? hireDate;
  int? departmentId;

  Employee(
      {this.id,
      this.firstName,
      this.Name,
      this.lastName,
      this.department,
      this.project,
      this.status,
      this.hireDate,
      this.departmentId,
      this.Salary});
}

class Project {
  int projectId;
  String projectName;

  Project({
    required this.projectId,
    required this.projectName,
  });
}
