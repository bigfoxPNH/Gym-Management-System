import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChartData {
  final String title;
  final double value;
  final Color color;
  final DateTime? date; // For time-series data

  ChartData(this.title, this.value, this.color, {this.date});
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
  final revenueChartType = 'line'.obs; // Changed default to line for revenue
  final userChartType = 'pie'.obs;
  final workoutChartType = 'pie'.obs;
  final membershipPlanChartType = 'pie'.obs;
  final activeMembershipChartType = 'pie'.obs;

  // Search filters for each chart
  final revenueSearchQuery = ''.obs;
  final membershipPlanSearchQuery = ''.obs;
  final activeMembershipSearchQuery = ''.obs;

  // Data
  final revenueData = <ChartData>[].obs;
  final revenueDataByPlan = <ChartData>[].obs; // Revenue breakdown by plan
  final revenueTimeSeriesData = <ChartData>[].obs; // Revenue over time
  final userData = <ChartData>[].obs;
  final workoutData = <ChartData>[].obs;
  final membershipPlanData = <ChartData>[].obs;
  final activeMembershipData = <ChartData>[].obs;

  // Filtered data
  final filteredRevenueData = <ChartData>[].obs;
  final filteredMembershipPlanData = <ChartData>[].obs;
  final filteredActiveMembershipData = <ChartData>[].obs;

  // Summary stats
  final totalRevenue = 0.0.obs;
  final totalTransactions = 0.obs;
  final averageTransactionValue = 0.0.obs;
  final totalActiveMemberships = 0.obs;

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

  // Search methods
  void updateRevenueSearch(String query) {
    revenueSearchQuery.value = query.toLowerCase();
    _filterRevenueData();
  }

  void updateMembershipPlanSearch(String query) {
    membershipPlanSearchQuery.value = query.toLowerCase();
    _filterMembershipPlanData();
  }

  void updateActiveMembershipSearch(String query) {
    activeMembershipSearchQuery.value = query.toLowerCase();
    _filterActiveMembershipData();
  }

  void _filterRevenueData() {
    if (revenueSearchQuery.value.isEmpty) {
      filteredRevenueData.value = revenueDataByPlan;
    } else {
      filteredRevenueData.value = revenueDataByPlan
          .where(
            (data) =>
                data.title.toLowerCase().contains(revenueSearchQuery.value),
          )
          .toList();
    }
  }

  void _filterMembershipPlanData() {
    if (membershipPlanSearchQuery.value.isEmpty) {
      filteredMembershipPlanData.value = membershipPlanData;
    } else {
      filteredMembershipPlanData.value = membershipPlanData
          .where(
            (data) => data.title.toLowerCase().contains(
              membershipPlanSearchQuery.value,
            ),
          )
          .toList();
    }
  }

  void _filterActiveMembershipData() {
    if (activeMembershipSearchQuery.value.isEmpty) {
      filteredActiveMembershipData.value = activeMembershipData;
    } else {
      filteredActiveMembershipData.value = activeMembershipData
          .where(
            (data) => data.title.toLowerCase().contains(
              activeMembershipSearchQuery.value,
            ),
          )
          .toList();
    }
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

  Future<void> _loadRevenueData() async {
    try {
      print('=== LOADING REVENUE DATA ===');
      print('Date range: ${startDate.value} to ${endDate.value}');

      double total = 0;
      int transactionCount = 0;
      final Map<String, double> revenueByPlan = {};
      final Map<String, double> revenueByDate = {}; // For time series
      final List<Map<String, dynamic>> allTransactions = [];

      // Load from user_memberships collection - THIS IS THE SOURCE OF TRUTH
      final snapshot = await _firestore.collection('user_memberships').get();

      print('Found ${snapshot.docs.length} user memberships');

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Get creation date (when membership was purchased)
        DateTime? createdDate;
        final createdAtData = data['createdAt'];

        if (createdAtData is Timestamp) {
          createdDate = createdAtData.toDate();
        } else if (createdAtData is String) {
          try {
            createdDate = DateTime.parse(createdAtData);
          } catch (e) {
            print('Error parsing createdAt date: $createdAtData');
          }
        }

        // Skip if no creation date or outside date range
        if (createdDate == null) {
          print('Skipping membership without createdAt: ${doc.id}');
          continue;
        }

        // Check if within date range
        if (createdDate.isBefore(startDate.value) ||
            createdDate.isAfter(endDate.value.add(const Duration(days: 1)))) {
          continue; // Outside selected date range
        }

        // Get payment status - only count completed payments
        final paymentStatus = data['paymentStatus']?.toString().toLowerCase();
        if (paymentStatus != 'completed') {
          print('Skipping non-completed payment: $paymentStatus');
          continue;
        }

        // Get amount
        final amount = (data['price'] ?? data['amount'] ?? 0).toDouble();
        if (amount <= 0) {
          print('Skipping membership with zero amount');
          continue;
        }

        // Get plan name
        final planName =
            data['membershipCardName'] ??
            data['membershipType'] ??
            data['planName'] ??
            'Không xác định';

        // Add to totals
        total += amount;
        transactionCount++;
        revenueByPlan[planName] = (revenueByPlan[planName] ?? 0) + amount;

        // Group by date for time series
        final dateKey = DateFormat('dd/MM/yyyy').format(createdDate);
        revenueByDate[dateKey] = (revenueByDate[dateKey] ?? 0) + amount;

        allTransactions.add({
          'date': createdDate,
          'amount': amount,
          'plan': planName,
          'dateKey': dateKey,
        });

        print('✓ Added transaction: $planName - $amount VNĐ on $dateKey');
      }

      // Update totals
      totalRevenue.value = total;
      totalTransactions.value = transactionCount;
      averageTransactionValue.value = transactionCount > 0
          ? total / transactionCount
          : 0;

      print('=== REVENUE SUMMARY ===');
      print('Total Revenue: ${totalRevenue.value} VNĐ');
      print('Total Transactions: ${totalTransactions.value}');
      print('Average Transaction: ${averageTransactionValue.value} VNĐ');
      print('Revenue by Plan: $revenueByPlan');

      // Generate colors
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

      // Revenue by plan (for pie/bar chart)
      revenueDataByPlan.value = revenueByPlan.entries
          .map(
            (entry) => ChartData(
              entry.key,
              entry.value,
              colors[revenueByPlan.keys.toList().indexOf(entry.key) %
                  colors.length],
            ),
          )
          .toList();

      // Revenue over time (for line chart)
      // Sort transactions by date
      allTransactions.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
      );

      // Group by appropriate time unit based on date range
      final daysDiff = endDate.value.difference(startDate.value).inDays;

      if (daysDiff <= 7) {
        // Show daily data
        revenueTimeSeriesData.value =
            revenueByDate.entries
                .map(
                  (entry) => ChartData(
                    entry.key,
                    entry.value,
                    Colors.blue,
                    date: DateFormat('dd/MM/yyyy').parse(entry.key),
                  ),
                )
                .toList()
              ..sort((a, b) => a.date!.compareTo(b.date!));
      } else if (daysDiff <= 31) {
        // Show daily data
        revenueTimeSeriesData.value =
            revenueByDate.entries
                .map(
                  (entry) => ChartData(
                    entry.key,
                    entry.value,
                    Colors.blue,
                    date: DateFormat('dd/MM/yyyy').parse(entry.key),
                  ),
                )
                .toList()
              ..sort((a, b) => a.date!.compareTo(b.date!));
      } else if (daysDiff <= 365) {
        // Group by month
        final Map<String, double> monthlyRevenue = {};
        for (final trans in allTransactions) {
          final date = trans['date'] as DateTime;
          final monthKey = DateFormat('MM/yyyy').format(date);
          monthlyRevenue[monthKey] =
              (monthlyRevenue[monthKey] ?? 0) + (trans['amount'] as double);
        }
        revenueTimeSeriesData.value =
            monthlyRevenue.entries
                .map(
                  (entry) => ChartData(
                    entry.key,
                    entry.value,
                    Colors.blue,
                    date: DateFormat('MM/yyyy').parse(entry.key),
                  ),
                )
                .toList()
              ..sort((a, b) => a.date!.compareTo(b.date!));
      } else {
        // Group by year
        final Map<String, double> yearlyRevenue = {};
        for (final trans in allTransactions) {
          final date = trans['date'] as DateTime;
          final yearKey = date.year.toString();
          yearlyRevenue[yearKey] =
              (yearlyRevenue[yearKey] ?? 0) + (trans['amount'] as double);
        }
        revenueTimeSeriesData.value =
            yearlyRevenue.entries
                .map(
                  (entry) => ChartData(
                    entry.key,
                    entry.value,
                    Colors.blue,
                    date: DateTime(int.parse(entry.key)),
                  ),
                )
                .toList()
              ..sort((a, b) => a.date!.compareTo(b.date!));
      }

      // Initialize filtered data
      filteredRevenueData.value = revenueDataByPlan;

      print('Revenue data loaded successfully');
      print('=== END REVENUE LOAD ===');
    } catch (e, stackTrace) {
      print('Error loading revenue data: $e');
      print('Stack trace: $stackTrace');
      revenueDataByPlan.clear();
      revenueTimeSeriesData.clear();
      filteredRevenueData.clear();
      totalRevenue.value = 0;
      totalTransactions.value = 0;
      averageTransactionValue.value = 0;
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
        final planName = data['name'] ?? data['planName'] ?? 'Không xác định';
        planByType[planName] = (planByType[planName] ?? 0) + 1;
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

      // Initialize filtered data
      filteredMembershipPlanData.value = membershipPlanData;
    } catch (e) {
      print('Error loading membership plan data: $e');
      membershipPlanData.clear();
      filteredMembershipPlanData.clear();
    }
  }

  Future<void> _loadActiveMembershipData() async {
    try {
      print('=== LOADING ACTIVE MEMBERSHIPS ===');
      final now = DateTime.now();

      int totalActive = 0;
      final Map<String, int> activePlanByType = {};

      // Load from user_memberships collection
      final snapshot = await _firestore.collection('user_memberships').get();
      print('Checking ${snapshot.docs.length} memberships for active status');

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Check if payment is completed
        final paymentStatus = data['paymentStatus']?.toString().toLowerCase();
        if (paymentStatus != 'completed') {
          continue; // Skip non-completed payments
        }

        // Check isActive field
        final isActiveField = data['isActive'];
        if (isActiveField != true) {
          continue; // Skip inactive memberships
        }

        // Check end date
        final endDateData = data['endDate'];
        DateTime? endDate;

        if (endDateData is Timestamp) {
          endDate = endDateData.toDate();
        } else if (endDateData is String) {
          try {
            endDate = DateTime.parse(endDateData);
          } catch (e) {
            print('Error parsing end date: $endDateData');
          }
        }

        // Check if not expired
        if (endDate != null && endDate.isBefore(now)) {
          print('Skipping expired membership ending $endDate');
          continue;
        }

        // This membership is active!
        final planName =
            data['membershipCardName'] ??
            data['membershipType'] ??
            data['planName'] ??
            'Không xác định';

        activePlanByType[planName] = (activePlanByType[planName] ?? 0) + 1;
        totalActive++;

        print(
          '✓ Active membership: $planName (expires: ${endDate != null ? DateFormat('dd/MM/yyyy').format(endDate) : 'không giới hạn'})',
        );
      }

      totalActiveMemberships.value = totalActive;

      print('=== ACTIVE MEMBERSHIP SUMMARY ===');
      print('Total Active: $totalActive');
      print('By Plan: $activePlanByType');

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

      // Initialize filtered data
      filteredActiveMembershipData.value = activeMembershipData;

      print(
        'Active membership data loaded: ${activeMembershipData.length} plans',
      );
      print('=== END ACTIVE MEMBERSHIP LOAD ===');
    } catch (e, stackTrace) {
      print('Error loading active membership data: $e');
      print('Stack trace: $stackTrace');
      activeMembershipData.clear();
      filteredActiveMembershipData.clear();
      totalActiveMemberships.value = 0;
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
