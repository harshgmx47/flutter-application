package com.example.flutter_application_1;

import android.os.Build;
import android.os.StrictMode;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import java.sql.Connection;
import java.sql.Date;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "flutter.native/sql";

    @RequiresApi(api = Build.VERSION_CODES.O)
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "testConnection":
                            new Thread(() -> {
                                String connectionResult = testSQLServerConnection();
                                runOnUiThread(() -> result.success(connectionResult));
                            }).start();
                            break;
                        case "getEmployees":
                            new Thread(() -> {
                                String employees = getEmployees();
                                runOnUiThread(() -> result.success(employees));
                            }).start();
                            break;
                        case "getEmployeeDetails":
                            int employeeId = call.argument("employeeId");
                            new Thread(() -> {
                                String employeesdata = getEmployeeDetails(employeeId);
                                runOnUiThread(() -> result.success(employeesdata));
                            }).start();
                            break;
                        case "addNewEmployee":
                            String firstName = call.argument("firstName");
                            String lastName = call.argument("lastName");
                            double newsalary = call.argument("salary");
                            String hireDate = call.argument("hireDate");
                            int projectId = call.argument("projectId");
                            String newstatus = call.argument("status");
                            LocalDate hireDateObj = LocalDate.parse(hireDate);

                            new Thread(() -> {
                                String response = addNewEmployee(firstName, lastName, newsalary, 1, hireDateObj, projectId, newstatus);
                                runOnUiThread(() -> result.success(response));
                            }).start();
                            break;
                        case "updateEmployee":
                            int id = call.argument("employeeId");
                            double salary = call.argument("salary");
                            String status = call.argument("status");
                            new Thread(() -> {
                                String response = updateEmployee(id, salary, status);
                                runOnUiThread(() -> result.success(response));
                            }).start();
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }


    private Connection getConnection() {
        String url = "jdbc:jtds:sqlserver://65.1.22.155:1433;databaseName=dev-db;";
        String user = "test";
        String password = "Test@12345678";
        StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
        StrictMode.setThreadPolicy(policy);

        Connection connection = null;
        try {
            // Load SQL Server JDBC Driver
            Class.forName("net.sourceforge.jtds.jdbc.Driver");
            // Establish connection
            connection = DriverManager.getConnection(url, user, password);
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
            // Log or handle ClassNotFoundException
        } catch (SQLException e) {
            e.printStackTrace();
            // Log or handle SQLException
        } catch (Exception e) {
            e.printStackTrace();
            // Log or handle general exceptions
        }
        return connection;
    }

    private String testSQLServerConnection() {
        try (Connection connection = getConnection()) {
            if (connection != null) {
                return "Connection Established Successfully!";
            } else {
                return "Failed to establish connection!";
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return "SQL Connection Error: " + e.getMessage();
        } catch (Exception e) {
            e.printStackTrace();
            return "Unexpected Error: " + e.getMessage();
        }
    }


    private String getEmployees() {
        StringBuilder result = new StringBuilder();
        String sql = "SELECT e.EmployeeID, e.FirstName, e.LastName, d.DepartmentName, p.ProjectName " +
                "FROM Employees e " +
                "JOIN Departments d ON e.DepartmentID = d.DepartmentID " +
                "JOIN Assignments pa ON e.EmployeeID = pa.EmployeeID " +
                "JOIN Projects p ON pa.ProjectID = p.ProjectID";

        try (Connection connection = getConnection();
             Statement statement = connection.createStatement();
             ResultSet resultSet = statement.executeQuery(sql)) {

            while (resultSet.next()) {
                int employeeId = resultSet.getInt("EmployeeID");
                String firstName = resultSet.getString("FirstName");
                String lastName = resultSet.getString("LastName");
                String departmentName = resultSet.getString("DepartmentName");
                String projectName = resultSet.getString("ProjectName");

                result.append(" ").append(employeeId)
                        .append(", ").append(firstName).append(" ").append(lastName)
                        .append(", ").append(departmentName)
                        .append(", ").append(projectName).append("\n");
                // result.append(employeeId)
                // .append(firstName).append(" ").append(lastName)
                // .append(departmentName)
                // .append(projectName).append("\n");
            }

        } catch (SQLException e) {
            e.printStackTrace();
            return "Error fetching employees: " + e.getMessage();
        }

        return result.toString();
    }

    public String getEmployeeDetails(int employeeId) {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        StringBuilder result = new StringBuilder();

        try {
            // Get the connection
            conn = getConnection();

            // SQL query to fetch employee details
            String query = "SELECT e.EmployeeID, e.Salary, a.Status " +
                    "FROM Employees e " +
                    "JOIN Assignments a ON e.EmployeeID = a.EmployeeID " +
                    "JOIN Projects p ON a.ProjectID = p.ProjectID " +
                    "WHERE e.EmployeeID = ?";

            // Prepare the statement with the query
            stmt = conn.prepareStatement(query);
            stmt.setInt(1, employeeId);  // Set the employee ID in the query

            // Execute the query and process the result set
            rs = stmt.executeQuery();
            if (rs.next()) {
                int id = rs.getInt("EmployeeID");
                double salary = rs.getDouble("Salary");
                String projectStatus = rs.getString("Status");

                // Append the result to the StringBuilder as a comma-separated string
                result.append(id).append(",").append(salary).append(",").append(projectStatus);
            }
        } catch (SQLException e) {
            // Handle any SQL-related exceptions
            e.printStackTrace();
            return "Error fetching employee details: " + e.getMessage();
        } finally {
            // Close the resources to prevent memory leaks
            try {
                if (rs != null) rs.close();
                if (stmt != null) stmt.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();  // Handle any errors during the cleanup process
            }
        }

        return result.toString();
    }


    public String updateEmployee(int employeeId, double newSalary, String newStatus) {
        Connection conn = null;
        PreparedStatement stmt1 = null;
        PreparedStatement stmt2 = null;

        try {
            conn = getConnection();

            // Begin transaction
            conn.setAutoCommit(false);

            // Update the Salary in the Employees table
            String updateSalaryQuery = "UPDATE Employees SET Salary = ? WHERE EmployeeID = ?";
            stmt1 = conn.prepareStatement(updateSalaryQuery);
            stmt1.setDouble(1, newSalary);
            stmt1.setInt(2, employeeId);
            int affectedRows1 = stmt1.executeUpdate();

            // Update the Status in the Assignments table
            String updateStatusQuery = "UPDATE Assignments SET Status = ? WHERE EmployeeID = ?";
            stmt2 = conn.prepareStatement(updateStatusQuery);
            stmt2.setString(1, newStatus);
            stmt2.setInt(2, employeeId);
            int affectedRows2 = stmt2.executeUpdate();

            // Commit transaction if both updates are successful
            if (affectedRows1 > 0 && affectedRows2 > 0) {
                conn.commit();
                return "Employee updated successfully.";
            } else {
                // Rollback if any update fails
                conn.rollback();
                return "Failed to update employee.";
            }
        } catch (SQLException e) {
            // Handle SQL exceptions
            e.printStackTrace();
            try {
                if (conn != null) {
                    conn.rollback();  // Rollback on error
                }
            } catch (SQLException rollbackEx) {
                rollbackEx.printStackTrace();
            }
            return "SQL Error: " + e.getMessage();
        } finally {
            // Close resources
            try {
                if (stmt1 != null) stmt1.close();
                if (stmt2 != null) stmt2.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }



    public String addNewEmployee(String firstName, String lastName, double salary, int departmentId, LocalDate hireDate, int projectId, String status) {
        Connection conn = null;
        PreparedStatement employeeStmt = null;
        PreparedStatement assignmentStmt = null;
        ResultSet maxIdResult = null;
        ResultSet maxAssignmentIdResult = null;

        try {
            // Get a connection to the database
            conn = getConnection();
            conn.setAutoCommit(false); // Start a transaction

            // Get the current maximum EmployeeID
            String maxIdQuery = "SELECT COALESCE(MAX(EmployeeID), 0) + 1 AS NewEmployeeID FROM Employees;";
            employeeStmt = conn.prepareStatement(maxIdQuery);
            maxIdResult = employeeStmt.executeQuery();
            int newEmployeeId = 1; // Default if no employees exist
            if (maxIdResult.next()) {
                newEmployeeId = maxIdResult.getInt("NewEmployeeID");
            }

            // Insert the new employee
            String insertEmployeeQuery = "INSERT INTO Employees (EmployeeID, FirstName, LastName, Salary, DepartmentID, HireDate) VALUES (?, ?, ?, ?, ?, ?);";
            employeeStmt = conn.prepareStatement(insertEmployeeQuery);
            employeeStmt.setInt(1, newEmployeeId); // Set new employee ID
            employeeStmt.setString(2, firstName);
            employeeStmt.setString(3, lastName);
            employeeStmt.setDouble(4, salary);
            employeeStmt.setInt(5, departmentId);
            employeeStmt.setDate(6, Date.valueOf(hireDate.toString())); // Set hire date

            // Execute the employee insert
            int affectedRows = employeeStmt.executeUpdate();
            if (affectedRows == 0) {
                throw new SQLException("Inserting employee failed, no rows affected.");
            }

            // Get the current maximum AssignmentID
            String maxAssignmentIdQuery = "SELECT COALESCE(MAX(AssignmentID), 0) + 1 AS NewAssignmentID FROM Assignments;";
            assignmentStmt = conn.prepareStatement(maxAssignmentIdQuery);
            maxAssignmentIdResult = assignmentStmt.executeQuery();
            int newAssignmentId = 1; // Default if no assignments exist
            if (maxAssignmentIdResult.next()) {
                newAssignmentId = maxAssignmentIdResult.getInt("NewAssignmentID");
            }

            // Insert into Assignments
            String insertAssignmentQuery = "INSERT INTO Assignments (AssignmentID, EmployeeID, ProjectID, AssignedDate, Status) VALUES (?, ?, ?, ?, ?);";
            assignmentStmt = conn.prepareStatement(insertAssignmentQuery);
            assignmentStmt.setInt(1, newAssignmentId); // Set new assignment ID
            assignmentStmt.setInt(2, newEmployeeId);
            assignmentStmt.setInt(3, projectId);
            assignmentStmt.setDate(4, Date.valueOf(hireDate.toString())); // Set hire date
            assignmentStmt.setString(5, status);
            assignmentStmt.executeUpdate();

            // Commit the transaction
            conn.commit();
            return "success";

        } catch (SQLException e) {
            if (conn != null) {
                try {
                    // Rollback in case of any error
                    conn.rollback();
                    System.out.println("Transaction rolled back due to an error.");
                } catch (SQLException rollbackEx) {
                    rollbackEx.printStackTrace();
                }
            }
            e.printStackTrace();
            return "Error adding new employee: " + e.getMessage();
        } finally {
            // Clean up resources
            try {
                if (maxIdResult != null) maxIdResult.close();
                if (maxAssignmentIdResult != null) maxAssignmentIdResult.close();
                if (employeeStmt != null) employeeStmt.close();
                if (assignmentStmt != null) assignmentStmt.close();
                if (conn != null) conn.close();
            } catch (SQLException closeEx) {
                closeEx.printStackTrace();
            }
        }
    }



}

