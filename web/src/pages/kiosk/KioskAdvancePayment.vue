<template>
  <q-page class="q-pa-md bg-grey-2 text-dark">
    <div class="row items-center q-gutter-x-sm q-mb-lg">
      <q-btn
        flat
        round
        dense
        icon="arrow_back"
        color="primary"
        class="cursor-pointer"
        style="min-width: 48px; min-height: 48px"
        @click="goBack"
      />
      <div>
        <h1 class="text-h5 text-weight-bold q-ma-none">
          {{ $t('kioskUI.workspace.actions.advancePayment.title') }}
        </h1>
        <p class="text-caption text-grey-7 q-ma-none q-mt-xs">
          {{ $t('kioskUI.workspace.actions.advancePayment.desc') }}
        </p>
      </div>
    </div>

    <q-card flat bordered class="bg-white q-pa-lg text-center">
      <q-icon name="account_balance_wallet" size="56px" color="primary" class="q-mb-md" />
      <div class="text-subtitle1 text-weight-bold q-mb-xs">
        {{ $t('kioskUI.workspace.actions.advancePayment.comingSoonTitle') }}
      </div>
      <p class="text-body2 text-grey-7 q-mb-none">
        {{ $t('kioskUI.workspace.actions.advancePayment.comingSoonBody') }}
      </p>
    </q-card>
  </q-page>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router';

const router = useRouter();

function goBack() {
  void router.push({ name: 'kiosk-workspace' });
}
</script>
