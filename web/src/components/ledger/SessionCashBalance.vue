<template>
  <q-chip
    flat
    bordered
    color="primary"
    text-color="white"
    icon="payments"
    class="text-weight-bold font-mono q-py-md q-px-md"
    style="font-size: 13px"
  >
    <div class="row items-center no-wrap">
      <span class="text-caption text-teal-1 q-mr-xs text-weight-normal">{{
        $t('ledger.cash.expectedDrawerCash')
      }}</span>
      <span v-if="loading">
        <q-spinner size="14px" color="white" class="q-ml-xs" />
      </span>
      <span v-else-if="balance !== null">
        {{ formatMoney(balance) }}
      </span>
      <span v-else class="text-teal-2"> — </span>
    </div>
  </q-chip>
</template>

<script setup lang="ts">
import { formatMoney } from '../../utils/format';

defineProps<{
  balance: number | null;
  loading?: boolean;
}>();
</script>
