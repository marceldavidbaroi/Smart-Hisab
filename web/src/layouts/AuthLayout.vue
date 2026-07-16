<template>
  <q-layout view="hHh Lpr fFf" class="auth-layout-container">
    <q-page-container>
      <q-page class="flex flex-center auth-page">
        <!-- Glowing background decoration -->
        <div class="glow-sphere sphere-1"></div>
        <div class="glow-sphere sphere-2"></div>

        <div class="auth-card-wrapper">
          <div class="text-center q-mb-lg">
            <div class="app-logo q-mb-xs">
              <q-icon name="receipt_long" size="48px" class="logo-icon" />
            </div>
            <h1 class="text-h4 text-bold text-slate-800 title-gradient">Smart Hisab</h1>
            <p class="text-subtitle2 text-slate-500">Smart Accounting & Management Portal</p>
          </div>

          <div class="glass-panel">
            <router-view v-slot="{ Component }">
              <transition name="fade-slide" mode="out-in">
                <component :is="Component" />
              </transition>
            </router-view>
          </div>
        </div>
      </q-page>
    </q-page-container>
  </q-layout>
</template>

<script setup lang="ts">
// AuthLayout setup
</script>

<style scoped lang="scss">
.auth-layout-container {
  background: #f8fafc;
  min-height: 100vh;
  position: relative;
  overflow: hidden;
  font-family: 'Outfit', 'Inter', sans-serif;
}

.auth-page {
  position: relative;
  z-index: 2;
  padding: 24px;
}

/* Background Glowing Mesh */
.glow-sphere {
  position: absolute;
  border-radius: 50%;
  filter: blur(120px);
  opacity: 0.35;
  z-index: 1;
  pointer-events: none;
}

.sphere-1 {
  width: 400px;
  height: 400px;
  background: radial-gradient(circle, #6366f1 0%, rgba(99, 102, 241, 0) 70%);
  top: -100px;
  left: -100px;
  animation: float-slow 15s infinite alternate;
}

.sphere-2 {
  width: 500px;
  height: 500px;
  background: radial-gradient(circle, #06b6d4 0%, rgba(6, 182, 212, 0) 70%);
  bottom: -150px;
  right: -100px;
  animation: float-slow 20s infinite alternate-reverse;
}

@keyframes float-slow {
  0% {
    transform: translate(0, 0) scale(1);
  }
  100% {
    transform: translate(50px, 50px) scale(1.1);
  }
}

.auth-card-wrapper {
  width: 100%;
  max-width: 450px;
  z-index: 3;
}

.logo-icon {
  color: #6366f1;
  background: linear-gradient(135deg, #6366f1 0%, #06b6d4 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  filter: drop-shadow(0 0 12px rgba(99, 102, 241, 0.2));
}

.title-gradient {
  background: linear-gradient(to right, #0f172a, #334155);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

/* Glassmorphic Panel */
.glass-panel {
  background: rgba(255, 255, 255, 0.85);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border: 1px solid rgba(0, 0, 0, 0.06);
  border-radius: 24px;
  padding: 32px;
  box-shadow:
    0 20px 40px -15px rgba(0, 0, 0, 0.05),
    inset 0 1px 1px rgba(255, 255, 255, 0.8);
}

/* Transitions */
.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.3s ease;
}

.fade-slide-enter-from {
  opacity: 0;
  transform: translateY(12px);
}

.fade-slide-leave-to {
  opacity: 0;
  transform: translateY(-12px);
}
</style>
