import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/canteen_account.dart';
import '../../core/models/cashbook_entry.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/supabase_service.dart';

@immutable
class CashbookState {
  final List<CashbookEntry> entries;
  final List<CanteenAccount> accounts;
  final String? selectedAccountId; // null = All Wallets / Combined
  final bool isLoading;
  final String? errorMessage;

  const CashbookState({
    this.entries = const [],
    this.accounts = const [],
    this.selectedAccountId,
    this.isLoading = false,
    this.errorMessage,
  });

  List<CashbookEntry> get filteredEntries {
    if (selectedAccountId == null || selectedAccountId!.isEmpty) {
      return entries;
    }
    return entries.where((e) => e.accountId == selectedAccountId).toList();
  }

  double get totalInflow {
    return filteredEntries
        .where((e) => e.type == 'income')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalOutflow {
    return filteredEntries
        .where((e) => e.type == 'expense')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get netBalance => totalInflow - totalOutflow;

  double get totalWalletsBalance {
    return accounts.fold(0.0, (sum, acc) => sum + acc.currentBalance);
  }

  CashbookState copyWith({
    List<CashbookEntry>? entries,
    List<CanteenAccount>? accounts,
    String? selectedAccountId,
    bool clearSelectedAccount = false,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CashbookState(
      entries: entries ?? this.entries,
      accounts: accounts ?? this.accounts,
      selectedAccountId: clearSelectedAccount
          ? null
          : (selectedAccountId ?? this.selectedAccountId),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final cashbookNotifierProvider =
    StateNotifierProvider<CashbookNotifier, CashbookState>((ref) {
  final tenantId = ref.watch(authNotifierProvider).tenantId;
  final notifier = CashbookNotifier(tenantId: tenantId);
  notifier.fetchAccountsAndEntries();
  return notifier;
});

class CashbookNotifier extends StateNotifier<CashbookState> {
  final String? tenantId;

  CashbookNotifier({this.tenantId}) : super(const CashbookState());

  void selectAccountFilter(String? accountId) {
    state = state.copyWith(
      selectedAccountId: accountId,
      clearSelectedAccount: accountId == null,
    );
  }

  /// Initial load: fetch accounts and cashbook entries
  Future<void> fetchAccountsAndEntries() async {
    await fetchCanteenAccounts();
    await fetchCashbookEntries();
  }

  /// Fetch Canteen Accounts / Wallets (Cash Drawer, bKash, Bank, Safe)
  Future<void> fetchCanteenAccounts() async {
    final tId = tenantId;
    if (tId == null || tId.isEmpty) return;

    // Cache fallback
    final cached = HiveService.getCache('canteen_accounts_$tId');
    if (cached != null && cached['list'] is List) {
      final raw = cached['list'] as List;
      final cachedAccs = raw
          .map((json) => CanteenAccount.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
      if (cachedAccs.isNotEmpty) {
        state = state.copyWith(accounts: cachedAccs);
      }
    }

    if (SupabaseService.isInitialized) {
      try {
        final res = await SupabaseService.client
            .from('canteen_accounts')
            .select()
            .eq('tenant_id', tId)
            .eq('is_active', true)
            .order('is_default', ascending: false)
            .order('created_at', ascending: true);

        final accounts = (res as List)
            .map((json) => CanteenAccount.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();

        if (accounts.isNotEmpty) {
          state = state.copyWith(accounts: accounts);
          await HiveService.setCache('canteen_accounts_$tId', {
            'list': accounts.map((a) => a.toJson()).toList(),
          });
        }
      } catch (e) {
        debugPrint('fetchCanteenAccounts error: $e');
      }
    }
  }

  /// Fetch cashbook entries for active tenant from Supabase day_entries with local Hive fallback
  Future<void> fetchCashbookEntries() async {
    final tId = tenantId;
    state = state.copyWith(isLoading: true, errorMessage: null);

    if (tId != null && tId.isNotEmpty) {
      // Offline / Local Cache Fallback
      final cached = HiveService.getCache('cashbook_$tId');
      if (cached != null && cached['list'] is List) {
        final rawList = cached['list'] as List;
        final cachedEntries = rawList
            .map((json) => CashbookEntry.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
        if (cachedEntries.isNotEmpty) {
          state = state.copyWith(entries: cachedEntries, isLoading: false);
        }
      }

      if (SupabaseService.isInitialized) {
        try {
          final res = await SupabaseService.client
              .from('day_entries')
              .select('*, canteen_accounts(name)')
              .eq('tenant_id', tId)
              .order('created_at', ascending: false)
              .limit(100);

          final entries = (res as List)
              .map((json) => CashbookEntry.fromJson(Map<String, dynamic>.from(json as Map)))
              .toList();

          state = state.copyWith(entries: entries, isLoading: false);
          await HiveService.setCache('cashbook_$tId', {
            'list': entries.map((e) => e.toJson()).toList(),
          });
          return;
        } catch (e) {
          debugPrint('fetchCashbookEntries Supabase error: $e');
        }
      }
    }

    state = state.copyWith(isLoading: false);
  }

  /// Add new expense entry with Canteen Wallet routing & RPC `record_expense_v2`
  Future<bool> addExpense({
    required String title,
    required String category,
    required double amount,
    String? accountId,
    String? vendorId,
    String? notes,
  }) async {
    final tId = tenantId ?? 'tenant-demo';
    final tempId = 'entry-${DateTime.now().millisecondsSinceEpoch}';

    String? accName;
    if (accountId != null) {
      accName = state.accounts
          .where((a) => a.id == accountId)
          .map((a) => a.name)
          .firstOrNull;
    }

    final newEntry = CashbookEntry(
      id: tempId,
      tenantId: tId,
      accountId: accountId,
      accountName: accName,
      type: 'expense',
      title: title,
      category: category,
      amount: amount,
      notes: notes,
      createdAt: DateTime.now(),
    );

    // Targeted Cache Mutation
    final updatedList = [newEntry, ...state.entries];
    
    // Update local wallet balance optimistically
    List<CanteenAccount> updatedAccounts = state.accounts;
    if (accountId != null) {
      updatedAccounts = state.accounts.map((acc) {
        if (acc.id == accountId) {
          return acc.copyWith(currentBalance: acc.currentBalance - amount);
        }
        return acc;
      }).toList();
    }

    state = state.copyWith(entries: updatedList, accounts: updatedAccounts);

    try {
      if (tenantId != null && SupabaseService.isInitialized) {
        await SupabaseService.client.rpc('record_expense_v2', params: {
          'p_tenant_id': tId,
          'p_category': category,
          'p_amount': amount,
          'p_account_id': accountId,
          'p_vendor_id': vendorId,
          'p_notes': notes ?? title,
        });

        // Silently revalidate accounts & entries in background
        fetchAccountsAndEntries();
        return true;
      }
    } catch (e) {
      debugPrint('addExpense RPC error: $e');
    }

    await HiveService.setCache('cashbook_$tId', {
      'list': updatedList.map((e) => e.toJson()).toList(),
    });
    return true;
  }

  /// Add Day Note / Market List with Targeted Cache Mutation
  Future<bool> addDayNote({
    required String title,
    required String content,
  }) async {
    final tId = tenantId ?? 'tenant-demo';
    final tempId = 'note-${DateTime.now().millisecondsSinceEpoch}';

    final newNoteEntry = CashbookEntry(
      id: tempId,
      tenantId: tId,
      type: 'note',
      title: title.isEmpty ? 'Day Note' : title,
      category: 'Day Note',
      amount: 0.0,
      notes: content,
      createdAt: DateTime.now(),
    );

    // Targeted Cache Mutation
    final updatedList = [newNoteEntry, ...state.entries];
    state = state.copyWith(entries: updatedList);

    try {
      if (tenantId != null && SupabaseService.isInitialized) {
        await SupabaseService.client.from('day_entries').insert({
          'tenant_id': tId,
          'entry_type': 'outflow',
          'category': 'canteen_expense',
          'amount': 0.01, // fallback dummy amount for strict constraints if needed
          'notes': '[$title] $content',
        });
      }
    } catch (e) {
      debugPrint('addDayNote error: $e');
    }

    await HiveService.setCache('cashbook_$tId', {
      'list': updatedList.map((e) => e.toJson()).toList(),
    });
    return true;
  }

  /// Add Miscellaneous Income entry with Canteen Wallet routing & Targeted Cache Mutation
  Future<bool> recordMiscIncome({
    required String title,
    required double amount,
    String? accountId,
    String? notes,
  }) async {
    final tId = tenantId ?? 'tenant-demo';
    final tempId = 'entry-${DateTime.now().millisecondsSinceEpoch}';

    String? accName;
    if (accountId != null) {
      accName = state.accounts
          .where((a) => a.id == accountId)
          .map((a) => a.name)
          .firstOrNull;
    }

    final newEntry = CashbookEntry(
      id: tempId,
      tenantId: tId,
      accountId: accountId,
      accountName: accName,
      type: 'income',
      title: title.isEmpty ? 'Misc Income' : title,
      category: 'misc_earn',
      amount: amount,
      notes: notes,
      createdAt: DateTime.now(),
    );

    // Targeted Cache Mutation
    final updatedList = [newEntry, ...state.entries];
    
    // Update local wallet balance optimistically
    List<CanteenAccount> updatedAccounts = state.accounts;
    if (accountId != null) {
      updatedAccounts = state.accounts.map((acc) {
        if (acc.id == accountId) {
          return acc.copyWith(currentBalance: acc.currentBalance + amount);
        }
        return acc;
      }).toList();
    }

    state = state.copyWith(entries: updatedList, accounts: updatedAccounts);

    try {
      if (tenantId != null && SupabaseService.isInitialized) {
        final inserted = await SupabaseService.client.from('day_entries').insert({
          'tenant_id': tId,
          'canteen_account_id': accountId,
          'entry_type': 'inflow',
          'category': 'misc_earn',
          'amount': amount,
          'reference_type': 'direct_income',
          'notes': title.isNotEmpty ? (notes != null ? '$title - $notes' : title) : notes,
        }).select('id').maybeSingle();

        // Also record in canteen_account_entries if account chosen
        if (accountId != null && inserted != null && inserted['id'] != null) {
          await SupabaseService.client.from('canteen_account_entries').insert({
            'tenant_id': tId,
            'account_id': accountId,
            'entry_type': 'inflow',
            'amount': amount,
            'category': 'misc_income',
            'reference_type': 'day_entry',
            'reference_id': inserted['id'],
            'notes': title.isNotEmpty ? (notes != null ? '$title - $notes' : title) : notes,
          });
        }

        fetchAccountsAndEntries();
        return true;
      }
    } catch (e) {
      debugPrint('recordMiscIncome error: $e');
    }

    await HiveService.setCache('cashbook_$tId', {
      'list': updatedList.map((e) => e.toJson()).toList(),
    });
    return true;
  }

  /// Remove entry with Targeted Cache Mutation
  Future<void> deleteEntry(String entryId) async {
    final tId = tenantId ?? 'tenant-demo';
    final updatedList = state.entries.where((e) => e.id != entryId).toList();
    state = state.copyWith(entries: updatedList);

    try {
      if (tenantId != null && SupabaseService.isInitialized) {
        await SupabaseService.client.from('day_entries').delete().eq('id', entryId);
        fetchAccountsAndEntries();
      }
    } catch (e) {
      debugPrint('deleteEntry error: $e');
    }

    await HiveService.setCache('cashbook_$tId', {
      'list': updatedList.map((e) => e.toJson()).toList(),
    });
  }
}
