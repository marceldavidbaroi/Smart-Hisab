<template>
  <q-card flat bordered class="q-pa-sm bg-grey-2 border-all row q-col-gutter-sm items-center">
    <div class="col-12 col-sm-6">
      <q-input
        v-model="filters.search"
        :label="$t('customers.list.searchPlaceholder')"
        dense
        outlined
        bg-color="white"
        clearable
        :disable="loading"
        @keyup.enter="applyFilters"
      >
        <template v-slot:prepend>
          <q-icon name="search" />
        </template>
      </q-input>
    </div>

    <div class="col-6 col-sm-3 flex items-center justify-center">
      <q-checkbox
        v-model="filters.activeOnly"
        :label="$t('customers.list.filterActive')"
        dense
        :disable="loading"
      />
    </div>

    <div class="col-12 col-sm-3 flex items-center justify-end q-gutter-x-xs">
      <q-btn
        flat
        dense
        color="grey-7"
        icon="clear"
        :label="$t('customers.list.clearBtn')"
        @click="clearFilters"
        :disable="loading"
        class="cursor-pointer font-semibold"
      />
      <q-btn
        unelevated
        dense
        color="primary"
        icon="filter_alt"
        :label="$t('customers.list.applyBtn')"
        @click="applyFilters"
        :loading="loading"
        class="cursor-pointer font-semibold q-px-sm"
      />
    </div>
  </q-card>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import type { CustomerCategory } from '../../stores/customers';

interface Filters {
  search: string;
  category: CustomerCategory | '';
  activeOnly: boolean;
}

defineProps<{
  loading?: boolean;
}>();

const emit = defineEmits<{
  (e: 'apply', filters: Filters): void;
  (e: 'clear'): void;
}>();

useI18n();

const filters = ref<Filters>({
  search: '',
  category: '',
  activeOnly: true,
});

function applyFilters() {
  emit('apply', { ...filters.value });
}

function clearFilters() {
  filters.value = {
    search: '',
    category: '',
    activeOnly: true,
  };
  emit('clear');
}
</script>
