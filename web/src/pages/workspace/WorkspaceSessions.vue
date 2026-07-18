<template>
  <q-page class="q-pa-md bg-grey-1 text-dark">
    <div class="row items-center justify-between q-mb-md">
      <div>
        <h1 class="text-h5 text-weight-bold text-slate-800 q-ma-none">
          {{ $t('workspace.sessions.title') }}
        </h1>
        <p class="text-caption text-grey-6 q-ma-none q-mt-xs">
          {{ $t('workspace.sessions.subtitle') }}
        </p>
      </div>
    </div>

    <!-- Sessions Audit Table / List -->
    <q-card flat bordered class="q-pa-md bg-white border-all">
      <div class="row items-center justify-between q-mb-md">
        <div class="text-subtitle1 text-weight-bold text-slate-800">
          {{ $t('workspace.sessions.cardTitle') }}
        </div>
        <q-btn
          flat
          dense
          color="primary"
          icon="refresh"
          :label="$t('common.reload')"
          class="text-weight-bold"
          @click="loadSessions"
          :loading="loading"
        />
      </div>

      <SessionHistoryTable
        :rows="sessions"
        :loading="loading"
        :can-reopen="canReopen"
        @reopen="handleReopen"
      />
    </q-card>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { supabase } from '../../boot/supabase';
import { useTenantStore } from '../../stores/tenant';
import { useSessionStore } from '../../stores/session';
import { useQuasar } from 'quasar';
import type { OperationalSession } from '../../stores/session';
import SessionHistoryTable from '../../components/sessions/SessionHistoryTable.vue';
import { showSuccess, showError, showApiError } from '../../composables/useFeedback';
import { useI18n } from 'vue-i18n';

const $q = useQuasar();
const tenantStore = useTenantStore();
const sessionStore = useSessionStore();
const { t } = useI18n();

type SessionWithStaff = OperationalSession & {
  opened_by_staff?: { full_name: string } | null;
};

const sessions = ref<SessionWithStaff[]>([]);
const loading = ref(false);

const canReopen = computed(() =>
  tenantStore.hasModulePermission('operational_shifts', 'sessions_reopen'),
);

async function loadSessions() {
  const tenantId = tenantStore.activeTenant?.id;
  if (!tenantId) return;

  const scope = tenantStore.getSessionReadScope();
  if (scope === 'none') {
    sessions.value = [];
    await showError(t('workspace.sessions.deniedView'));
    return;
  }

  loading.value = true;
  try {
    let query = supabase
      .from('sessions')
      .select(
        '*, shifts(name, start_time, end_time), opened_by_staff:staff_members!opened_by_staff_id(full_name)',
      )
      .eq('tenant_id', tenantId);

    if (scope === 'self') {
      const userId = tenantStore.user?.id;
      if (userId) {
        query = query.or(`opened_by_user_id.eq.${userId},closed_by_user_id.eq.${userId}`);
      }
    }

    query = query
      .order('business_date', { ascending: false })
      .order('opened_at', { ascending: false });

    const { data, error } = await query;
    if (error) throw error;
    sessions.value = (data || []) as SessionWithStaff[];
  } catch (err: unknown) {
    await showApiError(err, t('workspace.sessions.failedLoad'));
  } finally {
    loading.value = false;
  }
}

function handleReopen(sessionId: string) {
  $q.dialog({
    title: t('workspace.sessions.reopenDialogTitle'),
    message: t('workspace.sessions.reopenDialogMsg'),
    cancel: true,
    persistent: true,
    ok: {
      label: t('workspace.sessions.reopenBtn'),
      color: 'warning',
      flat: true,
    },
  }).onOk(() => {
    void (async () => {
      try {
        await sessionStore.reopenSession(sessionId);
        showSuccess(t('workspace.sessions.reopenSuccess'));
        await loadSessions();
      } catch (err: unknown) {
        await showApiError(err, t('workspace.sessions.failedReopen'));
      }
    })();
  });
}

onMounted(() => {
  void loadSessions();
});
</script>

<style scoped>
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
</style>
