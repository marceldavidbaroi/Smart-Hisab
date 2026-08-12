import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/cashbook_entry.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/supabase_service.dart';

@immutable
class CashbookState {
  final List<CashbookEntry> entries;
  final bool isLoading;
  final String? errorMessage;

  const CashbookState({
    this.entries = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  double get totalInflow {
    return entries
        .where((e) => e.type == 'income')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalOutflow {
    return entries
        .where((e) => e.type == 'expense')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get netBalance => totalInflow - totalOutflow;

  CashbookState copyWith({
    List<CashbookEntry>? entries,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CashbookState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final cashbookNotifierProvider =
    StateNotifierProvider<CashbookNotifier, CashbookState>((ref) {
  final tenantId = ref.watch(authNotifierProvider).tenantId;
  final notifier = CashbookNotifier(tenantId: tenantId);
  notifier.fetchCashbookEntries();
  return notifier;
});

class CashbookNotifier extends StateNotifier<CashbookState> {
  final String? tenantId;

  CashbookNotifier({this.tenantId}) : super(const CashbookState());

  /// Fetch cashbook entries for active tenant with local Hive fallback
  Future<void> fetchCashbookEntries() async {
    final tId = tenantId ?? 'tenant-demo';
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Offline / Local Cache Fallback
    final cached = HiveService.getCache('cashbook_$tId');
    if (cached != null && cached['list'] is List) {
      final rawList = cached['list'] as List;
      final cachedEntries = rawList
          .map((json) => CashbookEntry.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
      if (cachedEntries.isNotEmpty) {
        state = state.copyWith(entries: cachedEntries, isLoading: false);
        return;
      }
    }

    // Seed Demo Cashbook entries
    final demoEntries = [
      CashbookEntry(
        id: 'entry-1',
        tenantId: tId,
        type: 'expense',
        title: 'Bazar Purchase (Vegetables & Meat)',
        category: 'Market Expense',
        amount: 2500.0,
        notes: 'Bought from Kawran Bazar',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      CashbookEntry(
        id: 'entry-2',
        tenantId: tId,
        type: 'income',
        title: 'Baki Collected (Rahim Ahmed)',
        category: 'Collection',
        amount: 450.0,
        notes: 'Paid via bKash',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      CashbookEntry(
        id: 'entry-3',
        tenantId: tId,
        type: 'note',
        title: 'Market Shopping List',
        category: 'Day Note',
        amount: 0.0,
        notes: 'Need 10kg Rice, 5L Oil, 2kg Sugar for tomorrow breakfast shift.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];

    state = state.copyWith(entries: demoEntries, isLoading: false);
  }

  /// Add new expense entry with Targeted Cache Mutation & RPC `record_expense`
  Future<bool> addExpense({
    required String title,
    required String category,
    required double amount,
    String? notes,
  }) async {
    final tId = tenantId ?? 'tenant-demo';
    final tempId = 'entry-${DateTime.now().millisecondsSinceEpoch}';

    final newEntry = CashbookEntry(
      id: tempId,
      tenantId: tId,
      type: 'expense',
      title: title,
      category: category,
      amount: amount,
      notes: notes,
      createdAt: DateTime.now(),
    );

    // Targeted Cache Mutation
    final updatedList = [newEntry, ...state.entries];
    state = state.copyWith(entries: updatedList);

    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.rpc('record_expense', params: {
          'p_tenant_id': tId,
          'p_category': category,
          'p_amount': amount,
          'p_notes': notes ?? title,
        }) as Map<String, dynamic>?;

        if (res != null && res['success'] == true) {
          fetchCashbookEntries();
          return true;
        }
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
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.from('day_entries').insert({
          'tenant_id': tId,
          'type': 'note',
          'title': title.isEmpty ? 'Day Note' : title,
          'category': 'Day Note',
          'amount': 0.0,
          'notes': content,
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

  /// Add Miscellaneous Income entry with Targeted Cache Mutation
  Future<bool> recordMiscIncome({
    required String title,
    required double amount,
    String? notes,
  }) async {
    final tId = tenantId ?? 'tenant-demo';
    final tempId = 'entry-${DateTime.now().millisecondsSinceEpoch}';

    final newEntry = CashbookEntry(
      id: tempId,
      tenantId: tId,
      type: 'income',
      title: title.isEmpty ? 'Misc Income' : title,
      category: 'Misc Income',
      amount: amount,
      notes: notes,
      createdAt: DateTime.now(),
    );

    // Targeted Cache Mutation
    final updatedList = [newEntry, ...state.entries];
    state = state.copyWith(entries: updatedList);

    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.from('day_entries').insert({
          'tenant_id': tId,
          'type': 'income',
          'title': title.isEmpty ? 'Misc Income' : title,
          'category': 'Misc Income',
          'amount': amount,
          'notes': notes,
        });
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
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.from('day_entries').delete().eq('id', entryId);
      }
    } catch (e) {
      debugPrint('deleteEntry error: $e');
    }

    await HiveService.setCache('cashbook_$tId', {
      'list': updatedList.map((e) => e.toJson()).toList(),
    });
  }
}

