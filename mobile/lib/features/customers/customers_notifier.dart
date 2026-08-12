import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/customer.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/supabase_service.dart';

@immutable
class CustomersState {
  final List<Customer> customers;
  final bool isLoading;
  final String searchQuery;
  final String? errorMessage;

  const CustomersState({
    this.customers = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.errorMessage,
  });

  List<Customer> get filteredCustomers {
    if (searchQuery.trim().isEmpty) return customers;
    final query = searchQuery.trim().toLowerCase();
    return customers.where((c) {
      final nameMatch = c.name.toLowerCase().contains(query);
      final phoneMatch = (c.phone ?? '').contains(query);
      final instMatch = (c.institution ?? '').toLowerCase().contains(query);
      return nameMatch || phoneMatch || instMatch;
    }).toList();
  }

  double get totalBakiOutstanding {
    return customers.fold(0.0, (sum, c) => sum + (c.currentBalance > 0 ? c.currentBalance : 0.0));
  }

  CustomersState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    String? searchQuery,
    String? errorMessage,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

final customersNotifierProvider =
    StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
  final tenantId = ref.watch(authNotifierProvider).tenantId;
  final notifier = CustomersNotifier(tenantId: tenantId);
  if (tenantId != null && tenantId.isNotEmpty) {
    notifier.fetchCustomers();
  }
  return notifier;
});

class CustomersNotifier extends StateNotifier<CustomersState> {
  final String? tenantId;

  CustomersNotifier({this.tenantId}) : super(const CustomersState());

  /// Fetch customer list for current tenant with cache fallback
  Future<void> fetchCustomers() async {
    final tId = tenantId ?? 'tenant-demo';

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client
            .from('customers')
            .select('*, customer_wallets(current_balance)')
            .eq('tenant_id', tId)
            .eq('is_active', true)
            .order('name', ascending: true) as List<dynamic>;

        final fetched = res
            .map((json) => Customer.fromJson(json as Map<String, dynamic>))
            .toList();

        // Cache fetched list locally wrapped in a map
        await HiveService.setCache('customers_$tId', {
          'list': fetched.map((c) => c.toJson()).toList(),
        });

        state = state.copyWith(
          customers: fetched,
          isLoading: false,
        );
        return;
      }
    } catch (e) {
      debugPrint('CustomersNotifier fetch error: $e');
    }

    // Offline / Demo Fallback
    final cached = HiveService.getCache('customers_$tId');
    if (cached != null && cached['list'] is List) {
      final rawList = cached['list'] as List;
      final cachedList = rawList
          .map((json) => Customer.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
      if (cachedList.isNotEmpty) {
        state = state.copyWith(customers: cachedList, isLoading: false);
        return;
      }
    }

    // Default seed sample data for demo mode
    final demoCustomers = [
      Customer(
        id: 'cust-1',
        tenantId: tId,
        name: 'Rahim Ahmed',
        phone: '01711000001',
        institution: 'Dhaka University',
        currentBalance: 450.0,
      ),
      Customer(
        id: 'cust-2',
        tenantId: tId,
        name: 'Karim Chowdhury',
        phone: '01819000002',
        institution: 'Hostel A',
        currentBalance: 1200.0,
      ),
      Customer(
        id: 'cust-3',
        tenantId: tId,
        name: 'Tanvir Hasan',
        phone: '01912000003',
        institution: 'BRAC Bank Staff',
        currentBalance: 0.0,
      ),
    ];

    state = state.copyWith(customers: demoCustomers, isLoading: false);
  }

  /// Add new customer with Targeted Cache Mutation
  Future<bool> addCustomer({
    required String name,
    required String phone,
    String? address,
    String? institution,
  }) async {
    final tId = tenantId ?? 'tenant-demo';
    final tempId = 'cust-${DateTime.now().millisecondsSinceEpoch}';

    final newCustomer = Customer(
      id: tempId,
      tenantId: tId,
      name: name,
      phone: phone,
      address: address,
      institution: institution,
      currentBalance: 0.0,
      createdAt: DateTime.now(),
    );

    // Targeted Cache Mutation: prepend to state immediately
    final updatedList = [newCustomer, ...state.customers];
    state = state.copyWith(customers: updatedList);

    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.from('customers').insert({
          'tenant_id': tId,
          'name': name,
          'phone': phone,
          'address': address,
          'institution': institution,
        }).select('*, customer_wallets(current_balance)').single();

        final created = Customer.fromJson(res);
        // Replace temp customer with database persisted customer
        final finalizedList = state.customers
            .map((c) => c.id == tempId ? created : c)
            .toList();
        state = state.copyWith(customers: finalizedList);
        await HiveService.setCache('customers_$tId', {
          'list': finalizedList.map((c) => c.toJson()).toList(),
        });
        return true;
      }
    } catch (e) {
      debugPrint('addCustomer network error: $e');
    }

    await HiveService.setCache('customers_$tId', {
      'list': updatedList.map((c) => c.toJson()).toList(),
    });
    return true;
  }

  /// Collect Baki payment with Optimistic Update & Targeted Cache Mutation
  Future<bool> collectBaki({
    required String customerId,
    required double amount,
    String? notes,
  }) async {
    final tId = tenantId ?? 'tenant-demo';

    // 1. Optimistic local targeted cache mutation
    final updatedList = state.customers.map((c) {
      if (c.id == customerId) {
        final newBal = (c.currentBalance - amount).clamp(0.0, double.infinity);
        return c.copyWith(currentBalance: newBal);
      }
      return c;
    }).toList();

    state = state.copyWith(customers: updatedList);
    await HiveService.setCache('customers_$tId', {
      'list': updatedList.map((c) => c.toJson()).toList(),
    });

    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.rpc('record_baki_payment', params: {
          'p_tenant_id': tId,
          'p_customer_id': customerId,
          'p_amount': amount,
          'p_notes': notes ?? 'Collected Baki',
        }) as Map<String, dynamic>?;

        if (res != null && res['success'] == true && res['data'] != null) {
          final data = res['data'] as Map<String, dynamic>;
          final newBalance = (data['new_balance'] as num?)?.toDouble();
          if (newBalance != null) {
            // Update with exact backend balance
            final syncedList = state.customers.map((c) {
              return c.id == customerId ? c.copyWith(currentBalance: newBalance) : c;
            }).toList();
            state = state.copyWith(customers: syncedList);
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('collectBaki backend error: $e');
      return true; // Keep local optimistic state intact for high speed POS UX
    }
  }

  /// Soft delete or remove customer with Targeted Cache Mutation
  Future<void> deleteCustomer(String customerId) async {
    final tId = tenantId ?? 'tenant-demo';
    final updatedList = state.customers.where((c) => c.id != customerId).toList();
    state = state.copyWith(customers: updatedList);

    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client
            .from('customers')
            .update({'is_active': false})
            .eq('id', customerId);
      }
    } catch (e) {
      debugPrint('deleteCustomer error: $e');
    }

    await HiveService.setCache('customers_$tId', {
      'list': updatedList.map((c) => c.toJson()).toList(),
    });
  }

  /// Update customer details with targeted optimistic cache mutation
  Future<bool> updateCustomer({
    required String customerId,
    required String name,
    required String phone,
    String? address,
    String? institution,
  }) async {
    final tId = tenantId ?? 'tenant-demo';

    final updatedList = state.customers.map((c) {
      if (c.id == customerId) {
        return c.copyWith(
          name: name,
          phone: phone,
          address: address,
          institution: institution,
        );
      }
      return c;
    }).toList();

    state = state.copyWith(customers: updatedList);
    await HiveService.setCache('customers_$tId', {
      'list': updatedList.map((c) => c.toJson()).toList(),
    });

    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.from('customers').update({
          'name': name,
          'phone': phone,
          'address': address,
          'institution': institution,
        }).eq('id', customerId);
      }
      return true;
    } catch (e) {
      debugPrint('updateCustomer error: $e');
      return true;
    }
  }

  /// Update search filter string
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

