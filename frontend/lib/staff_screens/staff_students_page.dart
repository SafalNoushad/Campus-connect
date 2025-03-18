import 'package:flutter/material.dart';
import '../../shared/department_users_page.dart';

class StaffStudentsPage extends StatelessWidget {
  const StaffStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DepartmentUsersPage(isStaffView: true);
  }
}
