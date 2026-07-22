<template>
  <q-btn-dropdown
    flat
    no-caps
    dense
    dropdown-icon="expand_more"
    content-class="locale-switcher-menu"
    class="locale-switcher cursor-pointer"
    :class="{
      'locale-switcher--compact': compact,
      'locale-switcher--no-chevron': !showChevron,
    }"
    menu-anchor="bottom right"
    menu-self="top right"
  >
    <template #label>
      <div class="row items-center no-wrap locale-switcher__label">
        <q-icon name="translate" :size="compact ? '18px' : '20px'" class="text-primary" />
        <span class="locale-switcher__code text-weight-bold text-primary">{{ activeShort }}</span>
      </div>
    </template>

    <q-list class="locale-menu-list bg-white text-dark">
      <q-item-label header class="text-caption text-grey-6 text-weight-bold q-pb-none">
        {{ $t('common.language') }}
      </q-item-label>

      <q-item
        v-for="opt in localeOptions"
        :key="opt.value"
        v-close-popup
        clickable
        class="locale-menu-item cursor-pointer"
        :active="locale === opt.value"
        active-class="locale-menu-item--active"
        @click="locale = opt.value"
      >
        <q-item-section avatar>
          <span class="locale-menu-short text-weight-bold">{{ opt.short }}</span>
        </q-item-section>
        <q-item-section>
          <q-item-label class="text-weight-medium">{{ $t(opt.labelKey) }}</q-item-label>
        </q-item-section>
        <q-item-section side>
          <q-icon v-if="locale === opt.value" name="check" color="primary" size="18px" />
        </q-item-section>
      </q-item>
    </q-list>
  </q-btn-dropdown>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useLocale } from '../composables/useLocale';

withDefaults(
  defineProps<{
    compact?: boolean;
    showChevron?: boolean;
  }>(),
  {
    compact: true,
    showChevron: false,
  },
);

const { locale, localeOptions } = useLocale();

const activeShort = computed(
  () => localeOptions.find((o) => o.value === locale.value)?.short ?? 'EN',
);
</script>

<style scoped lang="scss">
.locale-switcher {
  min-height: 44px;
  min-width: 44px;
  border-radius: var(--radius-lg);
  border: 1.5px solid rgba(14, 74, 71, 0.22);
  background: var(--brand-soft);
  padding: 0 10px;
  transition:
    border-color 0.15s ease,
    background-color 0.15s ease;

  &:hover {
    border-color: var(--brand-primary);
    background: #ffffff;
  }
}

.locale-switcher--compact {
  min-height: 36px;
  padding: 0 8px;
}

.locale-switcher--no-chevron :deep(.q-btn-dropdown__arrow) {
  display: none;
}

.locale-switcher__label {
  gap: 6px;
}

.locale-switcher__code {
  font-size: 12px;
  letter-spacing: 0.04em;
  line-height: 1;
}

.locale-menu-list {
  min-width: 180px;
}

.locale-menu-item {
  min-height: 48px;
  border-radius: var(--radius-md);
  margin: 2px 6px;
}

.locale-menu-item--active {
  background: rgba(14, 74, 71, 0.08) !important;
  color: var(--brand-primary) !important;
}

.locale-menu-short {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: var(--radius-sm);
  background: var(--brand-soft);
  color: var(--brand-primary);
  font-size: 11px;
}
</style>

<style lang="scss">
.locale-switcher-menu {
  border-radius: var(--radius-lg) !important;
  border: 1px solid rgba(14, 74, 71, 0.1);
  box-shadow: 0 8px 24px rgba(14, 74, 71, 0.12);
  overflow: hidden;
}
</style>
