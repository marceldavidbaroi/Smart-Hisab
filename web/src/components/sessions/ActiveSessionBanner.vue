<template>
  <div
    v-if="sessionStore.hasActiveSession && sessionStore.activeSession"
    class="bg-teal-1 border-teal-2 border-b q-px-md q-py-xs text-slate-800 row items-center justify-between"
  >
    <div class="row items-center q-gutter-x-sm">
      <q-chip
        color="primary"
        text-color="white"
        dense
        square
        class="text-weight-bold uppercase text-xs q-px-xs q-ma-none"
        >{{ $t('sessions.banner.activeSession') }}</q-chip
      >
      <span class="text-subtitle2 text-weight-medium text-slate-800">
        {{
          $t('sessions.banner.shiftName', {
            name: sessionStore.activeSession.shifts?.name || $t('sessions.banner.loadingShift'),
          })
        }}
        — {{ $t('sessions.banner.businessDate') }}:
        {{ sessionStore.activeSession.business_date }}
      </span>
      <span class="text-caption text-grey-6 gt-xs">
        ({{ $t('sessions.banner.drawer') }}: {{ sessionStore.activeSession.opening_cash }} BDT)
      </span>
    </div>
    <q-btn
      flat
      dense
      color="primary"
      :label="$t('sessions.banner.viewAudit')"
      :to="`/${tenantStore.activeTenant?.slug}/sessions`"
      class="text-weight-bold text-xs"
    />
  </div>
</template>

<script setup lang="ts">
import { useSessionStore } from '../../stores/session';
import { useTenantStore } from '../../stores/tenant';

const sessionStore = useSessionStore();
const tenantStore = useTenantStore();
</script>

<style scoped>
.border-b {
  border-bottom: 1px solid rgba(0, 0, 0, 0.05);
}
</style>
