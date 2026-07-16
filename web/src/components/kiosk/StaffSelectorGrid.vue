<template>
  <div class="row q-col-gutter-md">
    <div v-for="staff in staffList" :key="staff.id" class="col-12 col-sm-6 col-md-4">
      <q-card
        flat
        bordered
        class="staff-card cursor-pointer transition-all overflow-hidden relative-position"
        :class="{
          'selected-card bg-primary-dark border-primary': selectedStaffId === staff.id,
          'bg-grey-9 border-grey-8 hover-card': selectedStaffId !== staff.id,
        }"
        role="button"
        tabindex="0"
        :aria-selected="selectedStaffId === staff.id ? 'true' : 'false'"
        :aria-label="`Staff profile: ${staff.fullName}, Role: ${staff.role}`"
        v-ripple
        @click="emit('select', staff)"
        @keydown.enter="emit('select', staff)"
        @keydown.space.prevent="emit('select', staff)"
      >
        <q-card-section class="row items-center q-pa-md no-wrap">
          <q-avatar
            size="40px"
            :color="selectedStaffId === staff.id ? 'white' : 'primary'"
            :text-color="selectedStaffId === staff.id ? 'primary' : 'white'"
            class="text-weight-bold shadow-1"
          >
            {{ getInitials(staff.fullName) }}
          </q-avatar>

          <div class="column q-ml-md overflow-hidden">
            <span
              class="text-subtitle2 text-weight-bold ellipsis"
              :class="selectedStaffId === staff.id ? 'text-white' : 'text-grey-2'"
            >
              {{ staff.fullName }}
            </span>
            <span
              class="text-caption text-weight-medium capitalize ellipsis"
              :class="selectedStaffId === staff.id ? 'text-grey-3' : 'text-grey-5'"
            >
              {{ staff.role }}
            </span>
          </div>
        </q-card-section>
      </q-card>
    </div>

    <!-- Empty State -->
    <div v-if="staffList.length === 0" class="col-12 text-center q-py-xl">
      <q-icon name="group_off" size="56px" color="grey-7" class="q-mb-md" />
      <div class="text-subtitle1 text-weight-medium text-grey-5">
        No staff members configured for counter access.
      </div>
      <div class="text-caption text-grey-6 q-mt-xs">
        Please check dashboard settings and ensure terminal access is allowed.
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
export interface KioskStaff {
  id: string;
  fullName: string;
  role: string;
}

defineProps<{
  staffList: KioskStaff[];
  selectedStaffId: string | null;
}>();

const emit = defineEmits<{
  (e: 'select', staff: KioskStaff): void;
}>();

const getInitials = (name: string) => {
  if (!name) return '';
  const parts = name.trim().split(/\s+/);
  if (parts.length >= 2) {
    return (parts[0]!.charAt(0) + parts[1]!.charAt(0)).toUpperCase();
  }
  return name.charAt(0).toUpperCase();
};
</script>

<style scoped lang="scss">
.staff-card {
  border-radius: 16px;
  border-width: 1.5px;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);

  &:focus-visible {
    outline: 2px solid var(--q-primary);
    outline-offset: 2px;
  }
}

.hover-card:hover {
  border-color: rgba(255, 255, 255, 0.25);
  background: rgba(255, 255, 255, 0.05);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.bg-primary-dark {
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.9) 0%, rgba(79, 70, 229, 0.9) 100%);
}

.border-primary {
  border-color: var(--q-primary) !important;
  box-shadow: 0 0 12px rgba(99, 102, 241, 0.3);
}

.border-grey-8 {
  border-color: rgba(255, 255, 255, 0.08) !important;
}

.capitalize {
  text-transform: capitalize;
}

.transition-all {
  transition: all 0.25s ease;
}
</style>
