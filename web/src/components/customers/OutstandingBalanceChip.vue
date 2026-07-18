<template>
  <q-chip :class="chipClass" icon="account_balance_wallet" outline>
    <span class="text-weight-bold">
      {{ label }}: <span class="font-mono">{{ formattedAmount }}</span>
    </span>
  </q-chip>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { formatMoney } from '../../utils/format';

const props = defineProps<{
  balance: number;
}>();

const { t, locale } = useI18n();

const isPrepaid = computed(() => props.balance < 0);

const label = computed(() => {
  return isPrepaid.value ? t('customers.detail.prepaid') : t('customers.detail.outstanding');
});

const formattedAmount = computed(() => {
  return formatMoney(Math.abs(props.balance), locale.value === 'bn' ? 'bn' : 'en');
});

const chipClass = computed(() => {
  if (props.balance === 0) {
    return 'text-grey-7 bg-grey-2 border-all';
  }
  return isPrepaid.value
    ? 'text-positive bg-green-1 border-all'
    : 'text-negative bg-red-1 border-all';
});
</script>
