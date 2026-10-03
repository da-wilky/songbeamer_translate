import pluginVue from 'eslint-plugin-vue'
import { defineConfigWithVueTs, vueTsConfigs } from '@vue/eslint-config-typescript'
import pluginPlaywright from 'eslint-plugin-playwright'
import skipFormatting from '@vue/eslint-config-prettier/skip-formatting'

export default defineConfigWithVueTs(
  { ignores: ['dist/', 'playwright-report/', 'test-results/'] },
  pluginVue.configs['flat/essential'],
  vueTsConfigs.recommended,
  { ...pluginPlaywright.configs['flat/recommended'], files: ['e2e/**/*.{test,spec}.{js,ts}'] },
  skipFormatting
)
