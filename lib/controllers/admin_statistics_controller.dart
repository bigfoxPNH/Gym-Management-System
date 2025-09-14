import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChartData {
  final String title;
  final double value;
  final Color color;

  ChartData(this.title, this.value, this.color);
}

class AdminStatisticsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Loading states
  final isLoading = false.obs;

  // Date filtering
  final selectedTimeFilter = 'month'.obs;
  final startDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  final endDate = DateTime.now().obs;
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();

  // Chart types
  final revenueChartType = 'pie'.obs;
  final userChartType = 'pie'.obs;
  final workoutChartType = 'pie'.obs;
  final membershipPlanChartType = 'pie'.obs;
  final activeMembershipChartType = 'pie'.obs;

  // Data
  final revenueData = <ChartData>[].obs;
  final userData = <ChartData>[].obs;
  final workoutData = <ChartData>[].obs;
  final membershipPlanData = <ChartData>[].obs;
  final activeMembershipData = <ChartData>[].obs;

  // Summary stats
  final totalRevenue = 0.0.obs;
  final totalTransactions = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeDateControllers();
    loadData();
  }

  void _initializeDateControllers() {
    startDateController.text = DateFormat('dd/MM/yyyy').format(startDate.value);
    endDateController.text = DateFormat('dd/MM/yyyy').format(endDate.value);
  }

  void updateTimeFilter(String filter) {
    selectedTimeFilter.value = filter;

    switch (filter) {
      case 'day':
        startDate.value = DateTime.now().subtract(const Duration(days: 1));
        endDate.value = DateTime.now();
        break;
      case 'month':
        startDate.value = DateTime.now().subtract(const Duration(days: 30));
        endDate.value = DateTime.now();
        break;
      case 'year':
        startDate.value = DateTime.now().subtract(const Duration(days: 365));
        endDate.value = DateTime.now();
        break;
    }

    if (filter != 'custom') {
      _initializeDateControllers();
      loadData();
    }
  }

  void updateStartDate(DateTime date) {
    startDate.value = date;
    loadData();
  }

  void updateEndDate(DateTime date) {
    endDate.value = date;
    loadData();
  }

  void updateRevenueChartType(String type) {
    revenueChartType.value = type;
  }

  void updateUserChartType(String type) {
    userChartType.value = type;
  }

  void updateWorkoutChartType(String type) {
    workoutChartType.value = type;
  }

  void updateMembershipPlanChartType(String type) {
    membershipPlanChartType.value = type;
  }

  void updateActiveMembershipChartType(String type) {
    activeMembershipChartType.value = type;
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadRevenueData(),
        _loadUserData(),
        _loadWorkoutData(),
        _loadMembershipPlanData(),
        _loadActiveMembershipData(),
      ]);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _debugCollections() async {
    try {
      print('=== DEBUG: Checking all collections ===');

      // Check available collections
      final collections = [
        'users',
        'user_memberships',
        'membership_cards',
        'payment_transactions',
      ];

      for (final collectionName in collections) {
        try {
          final snapshot = await _firestore
              .collection(collectionName)
              .limit(1)
              .get();
          if (snapshot.docs.isNotEmpty) {
            print('Collection $collectionName exists with sample data:');
            print(snapshot.docs.first.data());
          } else {
            print('Collection $collectionName exists but is empty');
          }
        } catch (e) {
          print('Collection $collectionName does not exist or error: $e');
        }
      }
      print('=== END DEBUG ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }

  Future<void> _loadRevenueData() async {
    try {
      print('Loading revenue data...');

      // First, let's check what collections actually exist and their structure
      await _debugCollections();

      // Try multiple approaches to find revenue data
      double total = 0;
      int transactionCount = 0;
      final Map<String, double> revenueByPlan = {};

      // Approach 1: Check user_memberships collection
      try {
        final userMemberships = await _firestore
            .collection('user_memberships')
            .get();
        print('Found ${userMemberships.docs.length} user memberships');

        for (final doc in userMemberships.docs) {
          final data = doc.data();
          print('User membership doc: $data');

          // Check for price/amount fields
          final amount = (data['price'] ?? data['amount'] ?? data['cost'] ?? 0)
              .toDouble();
          final planName =
              data['planName'] ?? data['membershipCardId'] ?? 'Không xác định';

          if (amount > 0) {
            revenueByPlan[planName] = (revenueByPlan[planName] ?? 0) + amount;
            total += amount;
            transactionCount++;
          }
        }
      } catch (e) {
        print('Error with user_memberships: $e');
      }

      // Approach 2: Check membership_cards for pricing info
      try {
        final membershipCards = await _firestore
            .collection('membership_cards')
            .get();
        print('Found ${membershipCards.docs.length} membership cards');

        for (final doc in membershipCards.docs) {
          final data = doc.data();
          print('Membership card doc: $data');

          final price = (data['price'] ?? data['amount'] ?? data['cost'] ?? 0)
              .toDouble();
          final planName =
              data['name'] ??
              data['planName'] ??
              data['id'] ??
              'Không xác định';

          if (price > 0) {
            // This is just plan pricing, not actual revenue
            // We'll use it if no actual transaction data exists
            print('Plan $planName has price: $price');
          }
        }
      } catch (e) {
        print('Error with membership_cards: $e');
      }

      // Approach 3: Check users collection for purchase history
      try {
        final users = await _firestore.collection('users').get();
        print('Checking ${users.docs.length} users for purchase history');

        for (final doc in users.docs) {
          final data = doc.data();

          // Check if user has membership info
          final membership = data['membership'];
          if (membership != null && membership is Map) {
            final amount = (membership['price'] ?? membership['amount'] ?? 0)
                .toDouble();
            final planName =
                membership['planName'] ??
                membership['type'] ??
                'Không xác định';

            if (amount > 0) {
              revenueByPlan[planName] = (revenueByPlan[planName] ?? 0) + amount;
              total += amount;
              transactionCount++;
            }
          }
        }
      } catch (e) {
        print('Error checking users: $e');
      }

      // If no revenue data found, set defaults
      if (revenueByPlan.isEmpty) {
        print('No revenue data found');
        totalRevenue.value = 0;
        totalTransactions.value = 0;
        revenueData.clear();
        return;
      }

      // Update totals
      totalRevenue.value = total;
      totalTransactions.value = transactionCount;

      print('Total revenue: $total, Total transactions: $transactionCount');

      final colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.red,
        Colors.teal,
        Colors.indigo,
        Colors.amber,
      ];

      revenueData.value = revenueByPlan.entries
          .map(
            (entry) => ChartData(
              entry.key,
              entry.value,
              colors[revenueByPlan.keys.toList().indexOf(entry.key) %
                  colors.length],
            ),
          )
          .toList();

      print('Revenue data loaded: ${revenueData.length} entries');
    } catch (e) {
      print('Error loading revenue data: $e');
      revenueData.clear();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final snapshot = await _firestore.collection('users').get();

      final Map<String, int> userByRole = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final role = data['role'] ?? 'user';
        final roleDisplayName = _getRoleDisplayName(role);
        userByRole[roleDisplayName] = (userByRole[roleDisplayName] ?? 0) + 1;
      }

      final colors = [
        Colors.red,
        Colors.orange,
        Colors.blue,
        Colors.green,
        Colors.purple,
        Colors.teal,
      ];

      userData.value = userByRole.entries
          .map(
            (entry) => ChartData(
              entry.key,
              entry.value.toDouble(),
              colors[userByRole.keys.toList().indexOf(entry.key) %
                  colors.length],
            ),
          )
          .toList();
    } catch (e) {
      print('Error loading user data: $e');
      userData.clear();
    }
  }

  Future<void> _loadWorkoutData() async {
    try {
      final snapshot = await _firestore.collection('exercises').get();

      final Map<String, int> exerciseByCategory = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] ?? 'Khác';
        exerciseByCategory[category] = (exerciseByCategory[category] ?? 0) + 1;
      }

      final colors = [
        Colors.orange,
        Colors.blue,
        Colors.green,
        Colors.purple,
        Colors.red,
        Colors.teal,
        Colors.indigo,
        Colors.amber,
      ];

      workoutData.value = exerciseByCategory.entries
          .map(
            (entry) => ChartData(
              entry.key,
              entry.value.toDouble(),
              colors[exerciseByCategory.keys.toList().indexOf(entry.key) %
                  colors.length],
            ),
          )
          .toList();
    } catch (e) {
      print('Error loading workout data: $e');
      workoutData.clear();
    }
  }

  Future<void> _loadMembershipPlanData() async {
    try {
      final snapshot = await _firestore.collection('membership_cards').get();

      final Map<String, int> planByType = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final planType = data['planType'] ?? 'Không xác định';
        planByType[planType] = (planByType[planType] ?? 0) + 1;
      }

      final colors = [
        Colors.deepPurple,
        Colors.indigo,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.red,
      ];

      membershipPlanData.value = planByType.entries
          .map(
            (entry) => ChartData(
              entry.key,
              entry.value.toDouble(),
              colors[planByType.keys.toList().indexOf(entry.key) %
                  colors.length],
            ),
          )
          .toList();
    } catch (e) {
      print('Error loading membership plan data: $e');
      membershipPlanData.clear();
    }
  }

  Future<void> _loadActiveMembershipData() async {
    try {
      print('Loading active membership data...');
      final now = DateTime.now();

      // Try multiple approaches to find active membership data
      final Map<String, int> activePlanByType = {};

      // Approach 1: Check user_memberships collection
      try {
        final snapshot = await _firestore.collection('user_memberships').get();
        print(
          'Found ${snapshot.docs.length} total memberships in user_memberships',
        );

        for (final doc in snapshot.docs) {
          final data = doc.data();
          print('Membership doc: $data');

          // Check if membership is active using multiple field patterns
          final status = data['status']?.toString().toLowerCase();
          final isActiveField =
              data['isActive']; // This is the actual field in Firebase
          final paymentStatus = data['paymentStatus']?.toString().toLowerCase();
          final endDateData = data['endDate'];

          // Parse end date
          DateTime? endDate;
          if (endDateData is Timestamp) {
            endDate = endDateData.toDate();
          } else if (endDateData is String) {
            try {
              endDate = DateTime.parse(endDateData);
            } catch (e) {
              print('Error parsing date string: $endDateData');
            }
          } else if (endDateData is int) {
            endDate = DateTime.fromMillisecondsSinceEpoch(endDateData);
          }

          // Check if membership is currently active
          bool isActive = false;

          // Check based on isActive field (this is what Firebase actually uses)
          if (isActiveField == true && paymentStatus == 'completed') {
            if (endDate != null && endDate.isAfter(now)) {
              isActive = true;
              print(
                'Membership is active: ${data['membershipCardName']} until $endDate',
              );
            } else if (endDate == null) {
              // Active status but no end date, consider it active
              isActive = true;
              print(
                'Membership is active (no end date): ${data['membershipCardName']}',
              );
            } else {
              print(
                'Membership expired: ${data['membershipCardName']} ended $endDate',
              );
            }
          } else if (status == 'active') {
            // Fallback to status field
            if (endDate != null && endDate.isAfter(now)) {
              isActive = true;
              print(
                'Membership is active (status): ${data['membershipCardName']} until $endDate',
              );
            } else if (endDate == null) {
              isActive = true;
              print(
                'Membership is active (status, no end date): ${data['membershipCardName']}',
              );
            }
          }

          if (isActive) {
            final planName =
                data['membershipCardName'] ??
                data['planName'] ??
                data['description'] ??
                data['membershipCardId'] ??
                'Không xác định';
            activePlanByType[planName] = (activePlanByType[planName] ?? 0) + 1;
            print('Added active membership: $planName');
          }
        }
      } catch (e) {
        print('Error with user_memberships: $e');
      }

      // Approach 2: Check users collection for active membership info
      try {
        final users = await _firestore.collection('users').get();
        print('Checking ${users.docs.length} users for active memberships');

        for (final doc in users.docs) {
          final data = doc.data();

          // Check if user has active membership info
          final membership = data['membership'];
          if (membership != null && membership is Map) {
            final status = membership['status']?.toString().toLowerCase();
            final endDateData = membership['endDate'];

            // Parse end date
            DateTime? endDate;
            if (endDateData is Timestamp) {
              endDate = endDateData.toDate();
            } else if (endDateData is String) {
              try {
                endDate = DateTime.parse(endDateData);
              } catch (e) {
                print('Error parsing user membership date: $endDateData');
              }
            } else if (endDateData is int) {
              endDate = DateTime.fromMillisecondsSinceEpoch(endDateData);
            }

            // Check if membership is active
            bool isActive = false;
            if (status == 'active') {
              if (endDate != null && endDate.isAfter(now)) {
                isActive = true;
              } else if (endDate == null) {
                isActive = true;
              }
            }

            if (isActive) {
              final planName =
                  membership['planName'] ??
                  membership['type'] ??
                  'Không xác định';
              activePlanByType[planName] =
                  (activePlanByType[planName] ?? 0) + 1;
            }
          }
        }
      } catch (e) {
        print('Error checking users for memberships: $e');
      }

      print('Active memberships by plan: $activePlanByType');

      final colors = [
        Colors.green,
        Colors.blue,
        Colors.orange,
        Colors.purple,
        Colors.red,
        Colors.teal,
        Colors.indigo,
      ];

      activeMembershipData.value = activePlanByType.entries
          .map(
            (entry) => ChartData(
              entry.key,
              entry.value.toDouble(),
              colors[activePlanByType.keys.toList().indexOf(entry.key) %
                  colors.length],
            ),
          )
          .toList();

      print(
        'Active membership data loaded: ${activeMembershipData.length} entries',
      );
    } catch (e) {
      print('Error loading active membership data: $e');
      activeMembershipData.clear();
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Quản trị viên';
      case 'manager':
        return 'Quản lý';
      case 'staff':
        return 'Nhân viên';
      case 'user':
        return 'Người dùng';
      case 'premium':
        return 'Premium';
      default:
        return 'Khác';
    }
  }

  void refreshData() {
    loadData();
  }

  @override
  void onClose() {
    startDateController.dispose();
    endDateController.dispose();
    super.onClose();
  }
}
