import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/member_management_controller.dart';
import '../../models/user_account.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/loading_button.dart';

class MemberManagementView extends StatelessWidget {
  const MemberManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MemberManagementController(), permanent: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Thành Viên'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddMemberDialog(context, controller),
            icon: const Icon(Icons.person_add),
          ),
          IconButton(
            onPressed: () => controller.loadAllUsers(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(controller),
          _buildStatsBar(controller),
          Expanded(child: _buildUsersList(controller)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(MemberManagementController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => controller.updateSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm theo tên hoặc email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isNotEmpty) {
              return IconButton(
                onPressed: () => controller.updateSearchQuery(''),
                icon: const Icon(Icons.clear),
              );
            }
            return const SizedBox.shrink();
          }),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(MemberManagementController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      height: 130,
      child: Obx(() {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildStatCard(
                'Tất cả',
                controller.users.length.toString(),
                Colors.blue,
                () => controller.updateRoleFilter(null),
                controller.selectedRole.value == null,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Admin',
                controller.adminCount.toString(),
                Colors.red,
                () => controller.updateRoleFilter(Role.admin),
                controller.selectedRole.value == Role.admin,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Quản lý',
                controller.managerCount.toString(),
                Colors.orange,
                () => controller.updateRoleFilter(Role.manager),
                controller.selectedRole.value == Role.manager,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Lễ tân',
                controller.staffCount.toString(),
                Colors.green,
                () => controller.updateRoleFilter(Role.staff),
                controller.selectedRole.value == Role.staff,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Hội viên',
                controller.memberCount.toString(),
                Colors.purple,
                () => controller.updateRoleFilter(Role.member),
                controller.selectedRole.value == Role.member,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'PT',
                controller.trainerCount.toString(),
                const Color(0xFFFF9800),
                () => controller.updateRoleFilter(Role.trainer),
                controller.selectedRole.value == Role.trainer,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    Color color,
    VoidCallback onTap,
    bool isSelected,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 90,
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(MemberManagementController controller) {
    return Obx(() {
      // Show loading state
      if (controller.isLoading.value && controller.users.isEmpty) {
        return const CenterLoading(message: 'Đang tải danh sách thành viên...');
      }

      // Show users list
      final usersToShow =
          controller.filteredUsers.isNotEmpty ||
              controller.searchQuery.value.isNotEmpty ||
              controller.selectedRole.value != null
          ? controller.filteredUsers
          : controller.users;

      if (usersToShow.isEmpty &&
          (controller.searchQuery.value.isNotEmpty ||
              controller.selectedRole.value != null)) {
        return _buildNoResultsState();
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: usersToShow.length,
        itemBuilder: (context, index) {
          final user = usersToShow[index];
          return _buildUserCard(context, user, controller);
        },
      );
    });
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    UserAccount user,
    MemberManagementController controller,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                  backgroundImage:
                      (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                      ? Icon(
                          Icons.person,
                          color: _getRoleColor(user.role),
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.role),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRoleDisplayName(user.role.name),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.phone != null && user.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.phone!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleMenuAction(context, value, user, controller),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 20),
                          SizedBox(width: 8),
                          Text('Xem chi tiết'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if ((user.dob != null) ||
                (user.address != null && user.address!.isNotEmpty)) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (user.dob != null) ...[
                    Icon(Icons.cake, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _safeFormatDate(user.dob),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (user.address != null && user.address!.isNotEmpty) ...[
                    Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        user.address!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.admin:
        return Colors.red;
      case Role.manager:
        return Colors.orange;
      case Role.staff:
        return Colors.green;
      case Role.member:
        return Colors.blue;
      case Role.membershipCard:
        return Colors.teal;
      case Role.trainer:
        return const Color(0xFFFF9800);
    }
  }

  String _getRoleDisplayName(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'admin':
        return 'ADMIN';
      case 'manager':
        return 'QUẢN LÝ';
      case 'staff':
        return 'LỄ TÂN';
      case 'member':
      default:
        return 'HỘI VIÊN';
    }
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    UserAccount user,
    MemberManagementController controller,
  ) {
    switch (action) {
      case 'view':
        _showUserDetailDialog(context, user);
        break;
      case 'edit':
        _showEditMemberDialog(context, user, controller);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, user, controller);
        break;
    }
  }

  void _showUserDetailDialog(BuildContext context, UserAccount user) {
    Get.dialog(
      AlertDialog(
        title: Text('Chi tiết: ${user.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Họ tên', user.fullName),
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Số điện thoại', user.phone ?? ''),
              _buildDetailRow('Ngày sinh', _safeFormatDate(user.dob)),
              _buildDetailRow('Địa chỉ', user.address ?? ''),
              _buildDetailRow('Quyền', _getRoleDisplayName(user.role.name)),
              _buildDetailRow('ID', user.id),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showAddMemberDialog(
    BuildContext context,
    MemberManagementController controller,
  ) {
    _showMemberFormDialog(context, null, controller);
  }

  void _showEditMemberDialog(
    BuildContext context,
    UserAccount user,
    MemberManagementController controller,
  ) {
    _showMemberFormDialog(context, user, controller);
  }

  void _showMemberFormDialog(
    BuildContext context,
    UserAccount? user,
    MemberManagementController controller,
  ) {
    final isEdit = user != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: user?.fullName ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final addressController = TextEditingController(text: user?.address ?? '');
    final dobController = TextEditingController(
      text: _safeFormatDate(user?.dob),
    );
    final passwordController = TextEditingController();

    String selectedRole = user?.role.name ?? 'member';

    Get.dialog(
      AlertDialog(
        title: Text(isEdit ? 'Chỉnh sửa thành viên' : 'Thêm thành viên mới'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ tên *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập họ tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập email';
                      }
                      if (!GetUtils.isEmail(value!)) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (!isEdit) ...[
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu *',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value!.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: dobController,
                    decoration: const InputDecoration(
                      labelText: 'Ngày sinh',
                      border: OutlineInputBorder(),
                      hintText: 'dd/mm/yyyy',
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        dobController.text = _safeFormatDate(date);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Quyền *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'member',
                        child: Text('Hội viên'),
                      ),
                      DropdownMenuItem(value: 'staff', child: Text('Lễ tân')),
                      DropdownMenuItem(
                        value: 'manager',
                        child: Text('Quản lý'),
                      ),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                        value: 'trainer',
                        child: Text('Huấn luyện viên (PT)'),
                      ),
                    ],
                    onChanged: (value) => selectedRole = value ?? 'member',
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          Obx(
            () => LoadingButton(
              text: isEdit ? 'Cập nhật' : 'Tạo mới',
              isLoading: controller.isLoading.value,
              backgroundColor: const Color(0xFF00BCD4),
              height: 42,
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final userData = {
                    'fullName': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'phoneNumber': phoneController.text.trim(),
                    'address': addressController.text.trim(),
                    'dateOfBirth': dobController.text.trim(),
                    'role': selectedRole,
                    if (!isEdit) 'password': passwordController.text,
                  };

                  if (isEdit) {
                    await controller.updateUser(user.id, userData);
                  } else {
                    await controller.createUser(userData);
                  }
                  // Controller will close dialog and show notification
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    UserAccount user,
    MemberManagementController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa thành viên "${user.fullName}"?\n\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          Obx(
            () => LoadingButton(
              text: 'Xóa',
              isLoading: controller.isLoading.value,
              backgroundColor: Colors.red,
              height: 42,
              onPressed: () async {
                await controller.deleteUser(user.id);
                // Controller will close dialog and show notification
              },
            ),
          ),
        ],
      ),
    );
  }

  // Safe wrapper methods to prevent RangeError
  String _safeFormatDate(DateTime? date) {
    if (date == null) return '';
    try {
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
