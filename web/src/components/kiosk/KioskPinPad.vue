<template>
  <div class="pin-pad-container column items-center q-gutter-y-md full-width">
    <!-- Visual Dots Display -->
    <div class="row justify-center q-gutter-x-sm q-py-md" role="status" aria-live="polite">
      <div
        v-for="i in maxDigits"
        :key="i"
        class="pin-dot transition-all"
        :class="{
          'filled bg-primary': i <= pin.length,
          'empty border-grey-4': i > pin.length,
          pulse: i === pin.length + 1 && !disabled,
        }"
      />
    </div>

    <!-- Numeric Keypad Grid -->
    <div class="keypad-grid full-width">
      <div v-for="key in keys" :key="key.value" class="keypad-col">
        <q-btn
          :flat="key.type === 'action'"
          :outline="key.type === 'number'"
          :color="key.color || 'white'"
          :disabled="disabled || (key.value === 'submit' && pin.length < maxDigits)"
          class="keypad-btn full-width cursor-pointer q-btn--dense text-weight-bold"
          :aria-label="key.label"
          :aria-keyshortcuts="key.keyshortcut"
          :aria-disabled="
            disabled || (key.value === 'submit' && pin.length < maxDigits) ? 'true' : 'false'
          "
          v-ripple
          @click="handleKeyPress(key.value)"
        >
          <q-icon v-if="key.icon" :name="key.icon" size="24px" />
          <span v-else class="text-h6">{{ key.display }}</span>
        </q-btn>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted } from 'vue';

interface Props {
  maxDigits?: number;
  disabled?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  maxDigits: 4,
  disabled: false,
});

const emit = defineEmits<{
  (e: 'submit', pin: string): void;
  (e: 'change', length: number): void;
}>();

const pin = ref('');

interface KeyConfig {
  value: string;
  display: string;
  label: string;
  type: 'number' | 'action';
  icon?: string;
  color?: string;
  keyshortcut?: string;
}

const keys: KeyConfig[] = [
  { value: '1', display: '1', label: 'Number 1', type: 'number', keyshortcut: '1' },
  { value: '2', display: '2', label: 'Number 2', type: 'number', keyshortcut: '2' },
  { value: '3', display: '3', label: 'Number 3', type: 'number', keyshortcut: '3' },
  { value: '4', display: '4', label: 'Number 4', type: 'number', keyshortcut: '4' },
  { value: '5', display: '5', label: 'Number 5', type: 'number', keyshortcut: '5' },
  { value: '6', display: '6', label: 'Number 6', type: 'number', keyshortcut: '6' },
  { value: '7', display: '7', label: 'Number 7', type: 'number', keyshortcut: '7' },
  { value: '8', display: '8', label: 'Number 8', type: 'number', keyshortcut: '8' },
  { value: '9', display: '9', label: 'Number 9', type: 'number', keyshortcut: '9' },
  {
    value: 'clear',
    display: 'C',
    label: 'Clear',
    type: 'action',
    icon: 'backspace',
    color: 'red-4',
    keyshortcut: 'Backspace',
  },
  { value: '0', display: '0', label: 'Number 0', type: 'number', keyshortcut: '0' },
  {
    value: 'submit',
    display: 'OK',
    label: 'Submit',
    type: 'action',
    icon: 'check',
    color: 'primary',
    keyshortcut: 'Enter',
  },
];

const handleKeyPress = (val: string) => {
  if (props.disabled) return;

  if (val === 'clear') {
    if (pin.value.length > 0) {
      pin.value = pin.value.slice(0, -1);
    }
  } else if (val === 'submit') {
    if (pin.value.length === props.maxDigits) {
      emit('submit', pin.value);
    }
  } else {
    if (pin.value.length < props.maxDigits) {
      pin.value += val;
    }
  }
};

watch(pin, (newPin) => {
  emit('change', newPin.length);
  // Auto-submit when maximum digits is reached
  if (newPin.length === props.maxDigits) {
    emit('submit', newPin);
  }
});

// Hardware keyboard input support
const handleKeyboard = (event: KeyboardEvent) => {
  if (props.disabled) return;

  // Ignore keyboard inputs if user is currently typing in input elements
  const activeEl = document.activeElement as HTMLElement | null;
  if (
    activeEl &&
    (activeEl.tagName === 'INPUT' || activeEl.tagName === 'TEXTAREA' || activeEl.isContentEditable)
  ) {
    return;
  }

  if (event.key >= '0' && event.key <= '9') {
    event.preventDefault();
    handleKeyPress(event.key);
  } else if (event.key === 'Backspace') {
    event.preventDefault();
    handleKeyPress('clear');
  } else if (event.key === 'Enter') {
    event.preventDefault();
    handleKeyPress('submit');
  } else if (event.key === 'Escape') {
    event.preventDefault();
    pin.value = '';
  }
};

onMounted(() => {
  window.addEventListener('keydown', handleKeyboard);
});

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyboard);
});

defineExpose({
  clear: () => {
    pin.value = '';
  },
});
</script>

<style scoped lang="scss">
.pin-pad-container {
  max-width: 320px;
}

.pin-dot {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  border: 2px solid rgba(255, 255, 255, 0.3);
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);

  &.filled {
    background-color: var(--q-primary) !important;
    border-color: var(--q-primary) !important;
    box-shadow: 0 0 10px rgba(99, 102, 241, 0.5);
    transform: scale(1.15);
  }

  &.pulse {
    animation: border-pulse 1.5s infinite;
  }
}

.keypad-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.keypad-col {
  display: flex;
  justify-content: center;
  align-items: center;
}

.keypad-btn {
  height: 56px; /* Custom touch target size > 48px */
  border-radius: 16px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(255, 255, 255, 0.03);
  color: white !important;
  transition: all 0.2s ease;

  &:hover:not([disabled]) {
    background: rgba(255, 255, 255, 0.08);
    border-color: rgba(255, 255, 255, 0.2);
  }

  &[disabled] {
    opacity: 0.4;
  }
}

@keyframes border-pulse {
  0% {
    border-color: rgba(255, 255, 255, 0.3);
  }
  50% {
    border-color: var(--q-primary);
  }
  100% {
    border-color: rgba(255, 255, 255, 0.3);
  }
}

.transition-all {
  transition: all 0.2s ease;
}
</style>
