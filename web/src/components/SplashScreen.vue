<template>
  <transition name="fade-out">
    <div v-if="visible" class="splash-container flex flex-center">
      <!-- Background glowing mesh similar to AuthLayout -->
      <div class="glow-sphere sphere-1"></div>
      <div class="glow-sphere sphere-2"></div>

      <div class="splash-content text-center">
        <!-- Pulse animated logo -->
        <div class="logo-wrapper q-mb-md">
          <img
            src="../assets/brand-logo.png"
            alt="Smart Hisab"
            class="logo-img animate-pulse"
            style="max-height: 100px; max-width: 220px; object-fit: contain"
          />
        </div>

        <!-- App Name -->
        <h1 class="text-h3 text-bold text-slate-800 title-gradient q-my-none">Smart Hisab</h1>

        <!-- Optional Tenant Name -->
        <transition name="fade-in">
          <div v-if="resolvedTenantName" class="tenant-info q-mt-xl">
            <span
              class="text-caption text-slate-400 text-uppercase tracking-widest text-weight-medium"
            >
              Connecting to
            </span>
            <div class="text-h6 text-weight-bold text-primary q-mt-xs">
              {{ resolvedTenantName }}
            </div>
          </div>
        </transition>

        <!-- Subtle loading indicator -->
        <div class="loader-bar q-mt-xl mx-auto">
          <div class="loader-progress"></div>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useTenantStore } from '../stores/tenant';
import { useKioskStore } from '../stores/kiosk';
import { supabase } from '../boot/supabase';

const props = defineProps({
  minimumDuration: {
    type: Number,
    default: 1800, // 1.8 seconds minimum for premium transition feel
  },
});

const emit = defineEmits(['finished']);

const visible = ref(true);
const tenantStore = useTenantStore();
const kioskStore = useKioskStore();
const urlTenantName = ref<string | null>(null);

// Get tenant name from active stores or check URL path
const resolvedTenantName = computed(() => {
  if (tenantStore.activeTenant?.name) {
    return tenantStore.activeTenant.name;
  }
  if (kioskStore.tenantName) {
    return kioskStore.tenantName;
  }
  return urlTenantName.value;
});

// Try to resolve tenant from URL slug if store hasn't initialized it yet
const resolveTenantFromUrl = async () => {
  const pathParts = window.location.pathname.split('/');
  const potentialSlug = pathParts[1];

  // Ignore system paths
  const systemPaths = ['auth', 'admin', 'kiosk', 'forbidden', 'error'];
  if (potentialSlug && !systemPaths.includes(potentialSlug)) {
    try {
      const { data } = await supabase
        .from('tenants')
        .select('name')
        .eq('slug', potentialSlug)
        .maybeSingle();
      if (data) {
        urlTenantName.value = data.name;
      }
    } catch {
      // Ignore
    }
  }
};

onMounted(async () => {
  const startTime = Date.now();
  await resolveTenantFromUrl();

  // Initialize store if not done
  if (!tenantStore.initialized) {
    await tenantStore.initializeStore();
  }

  // Ensure minimum display duration for smooth premium UX
  const elapsed = Date.now() - startTime;
  const remaining = Math.max(0, props.minimumDuration - elapsed);

  setTimeout(() => {
    visible.value = false;
    // Emit event when fade out is complete
    setTimeout(() => {
      emit('finished');
    }, 400);
  }, remaining);
});
</script>

<style scoped lang="scss">
.splash-container {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: #f8fafc;
  z-index: 9999;
  overflow: hidden;
  font-family: 'Outfit', 'Inter', sans-serif;
}

.splash-content {
  position: relative;
  z-index: 3;
}

/* Background Glowing Mesh */
.glow-sphere {
  position: absolute;
  border-radius: 50%;
  filter: blur(120px);
  opacity: 0.3;
  z-index: 1;
  pointer-events: none;
}

.sphere-1 {
  width: 500px;
  height: 500px;
  background: radial-gradient(circle, #6366f1 0%, rgba(99, 102, 241, 0) 70%);
  top: -150px;
  left: -150px;
  animation: float-slow 15s infinite alternate;
}

.sphere-2 {
  width: 600px;
  height: 600px;
  background: radial-gradient(circle, #06b6d4 0%, rgba(6, 182, 212, 0) 70%);
  bottom: -200px;
  right: -150px;
  animation: float-slow 20s infinite alternate-reverse;
}

@keyframes float-slow {
  0% {
    transform: translate(0, 0) scale(1);
  }
  100% {
    transform: translate(60px, 60px) scale(1.1);
  }
}

.logo-icon {
  color: #6366f1;
  background: linear-gradient(135deg, #6366f1 0%, #06b6d4 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  filter: drop-shadow(0 0 20px rgba(99, 102, 241, 0.25));
}

.title-gradient {
  background: linear-gradient(to right, #0f172a, #334155);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.animate-pulse {
  animation: logo-pulse 2s infinite ease-in-out;
}

@keyframes logo-pulse {
  0%,
  100% {
    transform: scale(1);
    opacity: 1;
  }
  50% {
    transform: scale(1.08);
    opacity: 0.85;
  }
}

.loader-bar {
  width: 140px;
  height: 4px;
  background: #e2e8f0;
  border-radius: 10px;
  overflow: hidden;
  margin: 24px auto 0 auto;
}

.loader-progress {
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, #6366f1, #06b6d4);
  animation: loading-slide 1.8s infinite ease-in-out;
  transform-origin: left;
}

@keyframes loading-slide {
  0% {
    transform: scaleX(0) translateX(0);
  }
  50% {
    transform: scaleX(0.6) translateX(50%);
  }
  100% {
    transform: scaleX(0) translateX(200%);
  }
}

/* Transitions */
.fade-out-leave-active {
  transition: opacity 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.fade-out-leave-to {
  opacity: 0;
}

.fade-in-enter-active {
  transition: all 0.5s ease-out 0.2s;
}

.fade-in-enter-from {
  opacity: 0;
  transform: translateY(10px);
}
</style>
