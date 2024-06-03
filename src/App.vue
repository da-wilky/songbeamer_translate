<script setup lang="ts">
import { RouterView } from 'vue-router';
import { useTheme } from 'vuetify';

const theme = useTheme()
if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
  theme.global.name.value = 'dark'
} else theme.global.name.value = 'light'
</script>

<template>
  <v-locale-provider locale="de">
    <v-app>
      <v-main>
        <v-container class="py-8">
          <v-row>
            <v-col cols="12" lg="10" offset-lg="1" xl="8" offset-xl="2">
              <RouterView />
            </v-col>
          </v-row>
        </v-container>
      </v-main>
    </v-app>
  </v-locale-provider>
</template>
