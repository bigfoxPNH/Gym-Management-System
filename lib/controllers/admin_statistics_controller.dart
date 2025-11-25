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

  // Product Revenue stats
  final totalProductRevenue = 0.0.obs;
  final totalProductOrders = 0.obs;
  final productRevenueData = <ChartData>[].obs;
  final productRevenueTimeSeriesData = <ChartData>[].obs;
  final productRevenueChartType = 'line'.obs;
  final productRevenueSearchQuery = ''.obs;
  final filteredProductRevenueData = <ChartData>[].obs;
  final filteredProductRevenueTimeSeriesData = <ChartData>[].obs;

  // PT Revenue stats
  final totalPTRevenue = 0.0.obs;
  final totalPTSessions = 0.obs;
  final ptRevenueData = <ChartData>[].obs;
  final ptRevenueTimeSeriesData = <ChartData>[].obs;
  final ptRevenueChartType = 'line'.obs;
  final ptRevenueSearchQuery = ''.obs;
  final filteredPTRevenueData = <ChartData>[].obs;
  final filteredPTRevenueTimeSeriesData = <ChartData>[].obs;

  // Store all PT transactions for filtering
  final List<Map<String, dynamic>> _allPTTransactions = [];
  
  // Store all Product transactions for filtering
  final List<Map<String, dynamic>> _allProductTransactions = [];

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

  void updatePTRevenueChartType(String type) {
    ptRevenueChartType.value = type;
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

  void updatePTRevenueSearch(String query) {
    ptRevenueSearchQuery.value = query.toLowerCase();
    _filterPTRevenueData();
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

  void _filterPTRevenueData() {
    if (ptRevenueSearchQuery.value.isEmpty) {
      filteredPTRevenueData.value = ptRevenueData;
      filteredPTRevenueTimeSeriesData.value = ptRevenueTimeSeriesData;
    } else {
      // Filter by trainer data
      filteredPTRevenueData.value = ptRevenueData
          .where(
            (data) =>
                data.title.toLowerCase().contains(ptRevenueSearchQuery.value),
          )
          .toList();

      // Filter time series data by trainer name
      final filteredTransactions = _allPTTransactions
          .where(
            (trans) => (trans['trainer'] as String).toLowerCase().contains(
              ptRevenueSearchQuery.value,
            ),
          )
          .toList();

      // Rebuild time series from filtered transactions
      if (filteredTransactions.isNotEmpty) {
        final Map<String, double> revenueByDate = {};

        for (final trans in filteredTransactions) {
          final dateKey = trans['dateKey'] as String;
          final amount = trans['amount'] as double;
          revenueByDate[dateKey] = (revenueByDate[dateKey] ?? 0) + amount;
        }

        // Group by appropriate time unit based on date range
        final daysDiff = endDate.value.difference(startDate.value).inDays;

        if (daysDiff <= 31) {
          // Show daily data
          filteredPTRevenueTimeSeriesData.value =
              revenueByDate.entries
                  .map(
                    (entry) => ChartData(
                      entry.key,
                      entry.value,
                      Colors.orange,
                      date: DateFormat('dd/MM/yyyy').parse(entry.key),
                    ),
                  )
                  .toList()
                ..sort((a, b) => a.date!.compareTo(b.date!));
        } else if (daysDiff <= 365) {
          // Group by month
          final Map<String, double> monthlyRevenue = {};
          for (final trans in filteredTransactions) {
            final date = trans['date'] as DateTime;
            final monthKey = DateFormat('MM/yyyy').format(date);
            monthlyRevenue[monthKey] =
                (monthlyRevenue[monthKey] ?? 0) + (trans['amount'] as double);
          }
          filteredPTRevenueTimeSeriesData.value =
              monthlyRevenue.entries
                  .map(
                    (entry) => ChartData(
                      entry.key,
                      entry.value,
                      Colors.orange,
                      date: DateFormat('MM/yyyy').parse(entry.key),
                    ),
                  )
                  .toList()
                ..sort((a, b) => a.date!.compareTo(b.date!));
        } else {
          // Group by year
          final Map<String, double> yearlyRevenue = {};
          for (final trans in filteredTransactions) {
            final date = trans['date'] as DateTime;
            final yearKey = date.year.toString();
            yearlyRevenue[yearKey] =
                (yearlyRevenue[yearKey] ?? 0) + (trans['amount'] as double);
          }
          filteredPTRevenueTimeSeriesData.value =
              yearlyRevenue.entries
                  .map(
                    (entry) => ChartData(
                      entry.key,
                      entry.value,
                      Colors.orange,
                      date: DateTime(int.parse(entry.key)),
                    ),
                  )
                  .toList()
                ..sort((a, b) => a.date!.compareTo(b.date!));
        }
      } else {
        filteredPTRevenueTimeSeriesData.value = [];
      }
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
        _loadPTRevenueData(),
        _loadProductRevenueData(),
      ]);
      
      // After all data is loaded, calculate total combined revenue
      _calculateTotalRevenue();
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

      // Update totals (membership cards only)
      totalTransactions.value = transactionCount;
      averageTransactionValue.value = transactionCount > 0
          ? total / transactionCount
          : 0;

      print('=== MEMBERSHIP REVENUE SUMMARY ===');
      print('Membership Revenue: $total VNĐ');
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

  Future<void> _loadPTRevenueData() async {
    try {
      print('=== LOADING PT REVENUE DATA ===');
      print('Date range: ${startDate.value} to ${endDate.value}');

      double total = 0;
      int sessionCount = 0;
      final Map<String, double> revenueByTrainer = {};
      final Map<String, double> revenueByDate = {}; // For time series
      _allPTTransactions.clear();

      // Pre-load all trainers for efficient lookup
      print('Loading trainers for name lookup...');
      final trainersSnapshot = await _firestore.collection('trainers').get();
      final Map<String, String> trainerNames = {};
      for (final doc in trainersSnapshot.docs) {
        final hoTen = doc.data()['hoTen'];
        if (hoTen != null) {
          trainerNames[doc.id] = hoTen.toString();
        }
      }
      print('Loaded ${trainerNames.length} trainer names');

      // Load from trainer_rentals collection - completed rentals
      final snapshot = await _firestore
          .collection('trainer_rentals')
          .where('trangThai', isEqualTo: 'completed')
          .get();

      print('Found ${snapshot.docs.length} completed PT rentals');

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Get completion date (updatedAt when marked completed)
        DateTime? completedDate;
        final updatedAtData = data['updatedAt'];

        if (updatedAtData is Timestamp) {
          completedDate = updatedAtData.toDate();
        } else if (updatedAtData is String) {
          try {
            completedDate = DateTime.parse(updatedAtData);
          } catch (e) {
            print('Error parsing updatedAt date: $updatedAtData');
          }
        }

        // Skip if no completion date or outside date range
        if (completedDate == null) {
          print('Skipping rental without updatedAt: ${doc.id}');
          continue;
        }

        // Check if within date range
        if (completedDate.isBefore(startDate.value) ||
            completedDate.isAfter(endDate.value.add(const Duration(days: 1)))) {
          continue; // Outside selected date range
        }

        // Get amount
        final amount = (data['tongTien'] ?? 0).toDouble();
        if (amount <= 0) {
          print('Skipping rental with zero amount');
          continue;
        }

        // Get trainer name from trainerId using pre-loaded cache
        String trainerName = 'Không xác định';
        final trainerId = data['trainerId'];

        // Lookup trainer name from cache
        if (trainerId != null && trainerId.toString().isNotEmpty) {
          final cachedName = trainerNames[trainerId.toString()];
          if (cachedName != null && cachedName.isNotEmpty) {
            trainerName = cachedName;
          }
        }

        // Fallback: try tenPT field if lookup failed
        if (trainerName == 'Không xác định') {
          final fallbackName = data['tenPT'] ?? data['trainerName'];
          if (fallbackName != null &&
              fallbackName.toString().isNotEmpty &&
              fallbackName.toString() != 'Không xác định') {
            trainerName = fallbackName.toString();
          }
        }

        final sessions = (data['soBuoi'] ?? 1) as int;

        // Add to totals
        total += amount;
        sessionCount += sessions;
        revenueByTrainer[trainerName] =
            (revenueByTrainer[trainerName] ?? 0) + amount;

        // Group by date for time series
        final dateKey = DateFormat('dd/MM/yyyy').format(completedDate);
        revenueByDate[dateKey] = (revenueByDate[dateKey] ?? 0) + amount;

        _allPTTransactions.add({
          'date': completedDate,
          'amount': amount,
          'trainer': trainerName,
          'dateKey': dateKey,
          'sessions': sessions,
        });

        print('✓ Added PT transaction: $trainerName - $amount VNĐ on $dateKey');
      }

      // Update totals
      totalPTRevenue.value = total;
      totalPTSessions.value = sessionCount;

      print('=== PT REVENUE SUMMARY ===');
      print('Total PT Revenue: ${totalPTRevenue.value} VNĐ');
      print('Total PT Sessions: ${totalPTSessions.value}');
      print('Revenue by Trainer: $revenueByTrainer');

      // Generate colors
      final colors = [
        Colors.orange,
        Colors.blue,
        Colors.green,
        Colors.purple,
        Colors.red,
        Colors.teal,
        Colors.indigo,
        Colors.amber,
        Colors.cyan,
        Colors.pink,
      ];

      // Revenue by trainer (for pie/bar chart)
      ptRevenueData.value = revenueByTrainer.entries
          .map(
            (entry) => ChartData(
              entry.key,
              entry.value,
              colors[revenueByTrainer.keys.toList().indexOf(entry.key) %
                  colors.length],
            ),
          )
          .toList();

      // Revenue over time (for line chart)
      // Sort transactions by date
      _allPTTransactions.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
      );

      // Group by appropriate time unit based on date range
      final daysDiff = endDate.value.difference(startDate.value).inDays;

      if (daysDiff <= 7) {
        // Show daily data
        ptRevenueTimeSeriesData.value =
            revenueByDate.entries
                .map(
                  (entry) => ChartData(
                    entry.key,
                    entry.value,
                    Colors.orange,
                    date: DateFormat('dd/MM/yyyy').parse(entry.key),
                  ),
                )
                .toList()
              ..sort((a, b) => a.date!.compareTo(b.date!));
      } else if (daysDiff <= 31) {
        // Show daily data
        ptRevenueTimeSeriesData.value =
            revenueByDate.entries
                .map(
                  (entry) => ChartData(
                    entry.key,
                    entry.value,
                    Colors.orange,
                    date: DateFormat('dd/MM/yyyy').parse(entry.key),
                  ),
                )
                .toList()
              ..sort((a, b) => a.date!.compareTo(b.date!));
      } else if (daysDiff <= 365) {
        // Group by month
        final Map<String, double> monthlyRevenue = {};
        for (final trans in _allPTTransactions) {
          final date = trans['date'] as DateTime;
          final monthKey = DateFormat('MM/yyyy').format(date);
          monthlyRevenue[monthKey] =
              (monthlyRevenue[monthKey] ?? 0) + (trans['amount'] as double);
        }
        ptRevenueTimeSeriesData.value =
            monthlyRevenue.entries
                .map(
                  (entry) => ChartData(
                    entry.key,
                    entry.value,
                    Colors.orange,
                    date: DateFormat('MM/yyyy').parse(entry.key),
                  ),
                )
                .toList()
              ..sort((a, b) => a.date!.compareTo(b.date!));
      } else {
        // Group by year
        final Map<String, double> yearlyRevenue = {};
        for (final trans in _allPTTransactions) {
          final date = trans['date'] as DateTime;
          final yearKey = date.year.toString();
          yearlyRevenue[yearKey] =
              (yearlyRevenue[yearKey] ?? 0) + (trans['amount'] as double);
        }
        ptRevenueTimeSeriesData.value =
            yearlyRevenue.entries
                .map(
                  (entry) => ChartData(
                    entry.key,
                    entry.value,
                    Colors.orange,
                    date: DateTime(int.parse(entry.key)),
                  ),
                )
                .toList()
              ..sort((a, b) => a.date!.compareTo(b.date!));
      }

      // Initialize filtered data
      filteredPTRevenueData.value = ptRevenueData;
      filteredPTRevenueTimeSeriesData.value = ptRevenueTimeSeriesData;

      print('PT Revenue data loaded successfully');
      print('=== END PT REVENUE LOAD ===');
    } catch (e, stackTrace) {
      print('Error loading PT revenue data: $e');
      print('Stack trace: $stackTrace');
      ptRevenueData.clear();
      ptRevenueTimeSeriesData.clear();
      filteredPTRevenueData.clear();
      totalPTRevenue.value = 0;
      totalPTSessions.value = 0;
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

  Future<void> _loadProductRevenueData() async {
    try {
      print('=== LOADING PRODUCT REVENUE DATA ===');
      
      double total = 0;
      int orderCount = 0;
      final Map<String, double> revenueByDate = {};
      final Map<String, double> revenueByProduct = {};
      _allProductTransactions.clear();

      // Get all orders with status 'delivered'
      final snapshot = await _firestore.collection('orders').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString() ?? '';
        
        // Only count delivered orders
        if (status != 'delivered') {
          continue;
        }

        // Parse created date
        DateTime? createdDate;
        final createdAtData = data['createdAt'];
        if (createdAtData is Timestamp) {
          createdDate = createdAtData.toDate();
        }

        // Skip if no creation date or outside date range
        if (createdDate == null) {
          continue;
        }

        // Check if within date range
        if (createdDate.isBefore(startDate.value) ||
            createdDate.isAfter(endDate.value.add(const Duration(days: 1)))) {
          continue;
        }

        // Get total amount
        final amount = (data['total'] ?? 0).toDouble();
        if (amount <= 0) {
          continue;
        }

        total += amount;
        orderCount++;

        // Group by date for time series
        final dateKey = DateFormat('dd/MM/yyyy').format(createdDate);
        revenueByDate[dateKey] = (revenueByDate[dateKey] ?? 0) + amount;

        // Group by product
        final items = data['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          final productName = item['productName'] ?? 'Không xác định';
          final itemTotal = (item['total'] ?? 0).toDouble();
          revenueByProduct[productName] = (revenueByProduct[productName] ?? 0) + itemTotal;
        }

        _allProductTransactions.add({
          'date': createdDate,
          'amount': amount,
          'dateKey': dateKey,
          'items': items,
        });

        print('✓ Added product order: $amount VNĐ on $dateKey');
      }

      // Update totals
      totalProductRevenue.value = total;
      totalProductOrders.value = orderCount;

      print('=== PRODUCT REVENUE SUMMARY ===');
      print('Total Product Revenue: ${totalProductRevenue.value} VNĐ');
      print('Total Product Orders: ${totalProductOrders.value}');

      // Generate colors for product revenue
      final colors = [
        Colors.pink,
        Colors.purple,
        Colors.deepPurple,
        Colors.indigo,
        Colors.blue,
        Colors.lightBlue,
        Colors.cyan,
        Colors.teal,
      ];

      // Create chart data for products
      int colorIndex = 0;
      productRevenueData.value = revenueByProduct.entries.map((entry) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        return ChartData(entry.key, entry.value, color);
      }).toList();

      // Sort by revenue descending
      productRevenueData.sort((a, b) => b.value.compareTo(a.value));

      // Create time series data
      final sortedDates = revenueByDate.keys.toList()
        ..sort((a, b) {
          final dateA = DateFormat('dd/MM/yyyy').parse(a);
          final dateB = DateFormat('dd/MM/yyyy').parse(b);
          return dateA.compareTo(dateB);
        });

      productRevenueTimeSeriesData.value = sortedDates.map((dateKey) {
        final date = DateFormat('dd/MM/yyyy').parse(dateKey);
        return ChartData(dateKey, revenueByDate[dateKey]!, Colors.pink, date: date);
      }).toList();

      _filterProductRevenueData();

    } catch (e) {
      print('Error loading product revenue data: $e');
      totalProductRevenue.value = 0;
      totalProductOrders.value = 0;
      productRevenueData.clear();
      productRevenueTimeSeriesData.clear();
    }
  }

  void _filterProductRevenueData() {
    final query = productRevenueSearchQuery.value.toLowerCase();
    
    if (query.isEmpty) {
      filteredProductRevenueData.value = productRevenueData;
      filteredProductRevenueTimeSeriesData.value = productRevenueTimeSeriesData;
    } else {
      filteredProductRevenueData.value = productRevenueData
          .where((data) => data.title.toLowerCase().contains(query))
          .toList();
      filteredProductRevenueTimeSeriesData.value = productRevenueTimeSeriesData
          .where((data) => data.title.toLowerCase().contains(query))
          .toList();
    }
  }

  void updateProductRevenueSearch(String query) {
    productRevenueSearchQuery.value = query.toLowerCase();
    _filterProductRevenueData();
  }

  void updateProductRevenueChartType(String type) {
    productRevenueChartType.value = type;
  }

  void _calculateTotalRevenue() {
    // Get membership revenue from revenueDataByPlan
    double membershipRevenue = 0;
    for (var data in revenueDataByPlan) {
      membershipRevenue += data.value;
    }

    // Calculate total combined revenue from all sources
    totalRevenue.value = membershipRevenue + totalPTRevenue.value + totalProductRevenue.value;

    print('=== TOTAL COMBINED REVENUE ===');
    print('Membership Revenue: $membershipRevenue VNĐ');
    print('PT Revenue: ${totalPTRevenue.value} VNĐ');
    print('Product Revenue: ${totalProductRevenue.value} VNĐ');
    print('Total Combined Revenue: ${totalRevenue.value} VNĐ');
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
