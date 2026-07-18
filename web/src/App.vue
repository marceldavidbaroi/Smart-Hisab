<template>
  <div>
    <SplashScreen v-if="showSplash" @finished="showSplash = false" />
    <router-view v-show="!showSplash" />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import SplashScreen from './components/SplashScreen.vue';

const showSplash = ref(true);
</script>
