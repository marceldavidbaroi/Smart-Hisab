<template>
  <q-layout view="hHh Lpr fFf" class="auth-layout-container">
    <q-page-container>
      <q-page class="flex flex-center auth-page">
        <div class="glow-orb orb-1" aria-hidden="true" />
        <div class="glow-orb orb-2" aria-hidden="true" />

        <div class="auth-card-wrapper">
          <div class="brand-hero text-center q-mb-lg">
            <div class="logo-container q-mb-md">
              <img src="../assets/brand-logo.png" alt="Smart Hisab" class="brand-logo-hero" />
            </div>
            <h1 class="brand-wordmark text-h5 text-weight-bold q-my-none">Smart Hisab</h1>
            <p class="brand-bengali text-subtitle1 text-weight-medium q-mt-xs q-mb-none">
              স্মার্ট হিসাব
            </p>
          </div>

          <div class="auth-card">
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
// AuthLayout — branded shell for login / auth routes
</script>

<style scoped lang="scss">
.auth-layout-container {
  background: linear-gradient(160deg, var(--brand-soft) 0%, var(--brand-surface) 48%, #d8ebe8 100%);
  min-height: 100vh;
  position: relative;
  overflow: hidden;
  font-family: 'Outfit', 'Inter', sans-serif;

  &::before {
    content: '';
    position: absolute;
    inset: 0;
    background-image: radial-gradient(rgba(14, 74, 71, 0.1) 1.25px, transparent 1.25px);
    background-size: 22px 22px;
    pointer-events: none;
    z-index: 1;
  }
}

.auth-page {
  position: relative;
  z-index: 2;
  padding: 24px;
  overflow-x: hidden;

  @media (max-width: 599px) {
    padding: 16px 12px;
  }
}

.glow-orb {
  position: absolute;
  border-radius: 50%;
  filter: blur(100px);
  opacity: 0.35;
  pointer-events: none;
  z-index: 0;
}

.orb-1 {
  width: min(420px, 90vw);
  height: min(420px, 90vw);
  background: radial-gradient(circle, var(--brand-accent) 0%, transparent 70%);
  top: -12%;
  left: -18%;
  animation: auth-float 16s ease-in-out infinite alternate;
}

.orb-2 {
  width: min(480px, 95vw);
  height: min(480px, 95vw);
  background: radial-gradient(circle, var(--brand-primary) 0%, transparent 70%);
  bottom: -18%;
  right: -22%;
  opacity: 0.22;
  animation: auth-float 20s ease-in-out infinite alternate-reverse;
}

@keyframes auth-float {
  0% {
    transform: translate(0, 0) scale(1);
  }
  100% {
    transform: translate(36px, 28px) scale(1.08);
  }
}

.auth-card-wrapper {
  width: 100%;
  max-width: 420px;
  z-index: 3;
  animation: auth-enter 0.35s ease-out;
}

@keyframes auth-enter {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.brand-hero {
  animation: auth-enter 0.4s ease-out;
}

.logo-container {
  display: flex;
  justify-content: center;
  align-items: center;
}

.brand-logo-hero {
  height: 112px;
  width: 112px;
  object-fit: contain;
  filter: drop-shadow(0 8px 20px rgba(14, 74, 71, 0.18));
  transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);

  @media (max-width: 599px) {
    height: 96px;
    width: 96px;
  }

  &:hover {
    transform: scale(1.05);
  }
}

.brand-wordmark {
  font-family: 'Outfit', 'Inter', sans-serif;
  letter-spacing: 0.4px;
  color: var(--brand-primary);
}

.brand-bengali {
  font-family: 'Outfit', 'Inter', sans-serif;
  color: var(--brand-primary);
  opacity: 0.78;
}

.auth-card {
  position: relative;
  background: #ffffff;
  border-radius: var(--radius-2xl);
  padding: 32px 28px 28px;
  box-shadow:
    0 12px 32px rgba(14, 74, 71, 0.1),
    0 2px 8px rgba(14, 74, 71, 0.04);
  border: 1px solid rgba(14, 74, 71, 0.1);
  overflow: hidden;
  z-index: 2;

  &::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--brand-primary) 0%, var(--brand-accent) 100%);
    z-index: 3;
  }

  @media (max-width: 599px) {
    padding: 24px 18px 22px;
    border-radius: var(--radius-xl);
  }
}

.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.25s ease;
}

.fade-slide-enter-from {
  opacity: 0;
  transform: translateY(8px);
}

.fade-slide-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
</style>
