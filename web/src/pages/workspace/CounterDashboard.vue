<template>
  <q-page class="flex flex-center bg-grey-9 q-pa-md fullscreen" style="min-height: 100vh">
    <q-card
      class="dashboard-card no-shadow bordered rounded-borders bg-white"
      style="width: 100%; max-width: 500px"
    >
      <!-- Header / Staff Avatar -->
      <q-card-section class="text-center q-pt-xl q-pb-md">
        <q-avatar
          size="80px"
          color="primary"
          text-color="white"
          class="q-mb-md shadow-2 font-bold text-h4"
        >
          {{ staffName ? staffName.charAt(0).toUpperCase() : 'S' }}
        </q-avatar>
        <div class="text-h5 text-weight-bold text-slate-800">{{ staffName || $t('workspace.counter.staffMemberFallback') }}</div>
        <q-badge
          color="secondary"
          class="q-mt-sm q-py-xs q-px-md text-weight-medium text-subtitle2"
        >
          {{ staffRole || $t('workspace.counter.staffRoleFallback') }}
        </q-badge>
      </q-card-section>

      <!-- Shift / Session Details -->
      <q-card-section class="q-px-lg">
        <div class="bg-grey-1 rounded-borders q-pa-md bordered">
          <div class="row justify-between items-center q-mb-sm text-sm text-slate-600">
            <span class="text-weight-medium">{{ $t('workspace.counter.terminalStatus') }}</span>
            <span class="text-positive text-weight-bold row items-center">
              <q-icon name="fiber_manual_record" class="q-mr-xs" /> {{ $t('workspace.counter.clockedIn') }}
            </span>
          </div>
          <div class="row justify-between items-center text-sm text-slate-600">
            <span class="text-weight-medium">{{ $t('workspace.counter.clockInTime') }}</span>
            <span class="text-slate-800 font-mono">{{ clockInTime }}</span>
          </div>
        </div>

        <!-- Phase 4 Placeholder Banner -->
        <q-banner
          class="bg-indigo-1 text-indigo-9 rounded-borders q-mt-lg q-pa-md no-shadow bordered"
        >
          <template #avatar>
            <q-icon name="rocket" color="primary" size="sm" />
          </template>
          <div class="text-weight-bold text-subtitle2">{{ $t('workspace.counter.kioskActiveTitle') }}</div>
          <div class="text-xs q-mt-xs">
            {{ $t('workspace.counter.kioskActiveMsg') }}
          </div>
        </q-banner>
      </q-card-section>

      <!-- Action Buttons -->
      <q-card-section class="q-px-lg q-pb-xl q-pt-md">
        <q-btn
          color="negative"
          unelevated
          class="full-width q-py-md rounded-btn text-weight-bold text-subtitle1 cursor-pointer"
          icon="logout"
          :label="$t('auth.counter.clockOut')"
          style="min-height: 48px"
          @click="handleClockOut"
        />
      </q-card-section>
    </q-card>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();

const staffName = ref('');
const staffRole = ref('');
const clockInTime = ref('');

onMounted(() => {
  // Ensure the device is paired and staff is logged in
  const deviceToken = localStorage.getItem('device_token');
  const staffSessionId = localStorage.getItem('staff_session_id');

  if (!deviceToken) {
    void router.replace('/auth/pair-device');
    return;
  }

  if (!staffSessionId) {
    void router.replace('/auth/counter-login');
    return;
  }

  staffName.value = localStorage.getItem('staff_session_name') || 'Staff';
  staffRole.value = localStorage.getItem('staff_session_role') || 'Staff';

  // Format current local date/time as fallback if not set
  const formatTime = () => {
    const d = new Date();
    return (
      d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }) +
      ' (' +
      d.toLocaleDateString([], { month: 'short', day: 'numeric' }) +
      ')'
    );
  };
  clockInTime.value = formatTime();
});

const handleClockOut = () => {
  // Clear staff session credentials from local storage
  localStorage.removeItem('staff_session_id');
  localStorage.removeItem('staff_session_name');
  localStorage.removeItem('staff_session_role');

  // Return to terminal login
  void router.push('/auth/counter-login');
};
</script>

<style scoped lang="scss">
.dashboard-card {
  border-radius: 24px;
}

.rounded-btn {
  border-radius: 12px;
}

.bordered {
  border: 1px solid #cbd5e1;
}

.cursor-pointer {
  cursor: pointer;
}
</style>
