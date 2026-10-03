<script setup lang="ts">
import { mdiThemeLightDark } from '@mdi/js'
import ISO6391 from 'iso-639-1'
import { ref, watch } from 'vue'
import { useTheme } from 'vuetify'
const theme = useTheme()

const languages: Array<{ name: string; code: string }> = []
for (let i = 0; i < ISO6391.getAllNames().length; i++) {
  const tmp = {
    name: ISO6391.getAllNames()[i],
    code: ISO6391.getAllCodes()[i]
  }
  languages.push(tmp)
}

const ownTranslation = ref(false)

const srcLanguage = ref('en')
const dstLanguage = ref('de')

const inputText = ref('')
const outputText = ref('')
const sbOutputText = ref('')

const transErr = ref(false)
const transLoading = ref(false)

let pendingTranslation: AbortController | undefined
let debounceTimer: ReturnType<typeof setTimeout> | undefined

async function fetchTranslation(text: string, from: string, to: string, signal: AbortSignal) {
  const params = new URLSearchParams({ client: 'gtx', sl: from, tl: to, dt: 't', q: text })
  const res = await fetch(`https://translate.googleapis.com/translate_a/single?${params}`, {
    signal
  })
  if (!res.ok) throw new Error(`Translation request failed: ${res.status}`)
  const data = await res.json()
  if (!Array.isArray(data?.[0])) throw new Error('Unexpected translation response')
  return data[0].map((segment: [string]) => segment[0]).join('')
}

async function triggerTranslate() {
  pendingTranslation?.abort()
  const controller = new AbortController()
  pendingTranslation = controller

  transErr.value = false
  const text = inputText.value.trim()
  if (text === '') {
    outputText.value = ''
    transLoading.value = false
    return
  }
  transLoading.value = true
  try {
    outputText.value = await fetchTranslation(
      text,
      srcLanguage.value,
      dstLanguage.value,
      controller.signal
    )
  } catch (err) {
    if (controller.signal.aborted) return
    console.error(err)
    outputText.value = ''
    transErr.value = true
  }
  transLoading.value = false
}

function triggerPutTogether() {
  let res = ''
  const sectionHeading =
    /^(Refrain|Chorus|Strophe|Verse?|Bridge|Intro|Outro|Pre-Chorus|Pre-Refrain)(\s*\d+[a-z]?)?$/i

  const linesOut = outputText.value.trim().split(/\r?\n/)
  inputText.value
    .trim()
    .split(/\r?\n/)
    .forEach((line, i) => {
      const trimmed = line.trim()
      if (trimmed === '' || trimmed === '---' || sectionHeading.test(trimmed)) {
        res += `${line}\n`
        return
      }
      res += `${line}\n${linesOut[i] ?? ''}\n`
    })
  sbOutputText.value = res
}

const toggleTheme = () => {
  theme.global.name.value = theme.global.current.value.dark ? 'light' : 'dark'
}

watch(
  () => [inputText.value, dstLanguage.value, srcLanguage.value, ownTranslation.value],
  () => {
    clearTimeout(debounceTimer)
    if (ownTranslation.value) {
      pendingTranslation?.abort()
      transLoading.value = false
      return
    }
    debounceTimer = setTimeout(triggerTranslate, 500)
  }
)
watch([inputText, outputText], () => {
  triggerPutTogether()
})
</script>

<template>
  <v-card>
    <v-card-item>
      <h1>Songbeamer Translator</h1>
      <h3 class="text-medium-emphasis mt-4">
        Willkommen auf der Seite des SongBeamer-Übersetzers!
      </h3>
      <div class="text-medium-emphasis">
        <p>
          Hier kannst du den Text eines Liedes einfügen und in eine andere Sprache übersetzt
          bekommen. Alternativ kannst du auch deine eigene Übersetzung einfügen.
        </p>
        <p>
          Anschließend setzt das Programm die beiden Übersetzungen zusammen in einen
          SongBeamer-Text.
        </p>
      </div>
      <template #append>
        <v-tooltip>
          <template #activator="{ props: tooltipProps }">
            <v-btn
              @click="toggleTheme"
              :icon="mdiThemeLightDark"
              v-bind="tooltipProps"
              variant="flat"
            ></v-btn>
          </template>
          <span>Hell/Dunkel</span>
        </v-tooltip>
      </template>
    </v-card-item>
    <v-divider></v-divider>
    <v-container>
      <v-row>
        <v-col>
          <h3>Konfiguration</h3>
        </v-col>
      </v-row>
      <v-row>
        <v-col>
          <v-switch
            v-model="ownTranslation"
            label="Eigene Übersetzung einfügen"
            color="primary"
          ></v-switch>
          <v-alert type="info" v-if="ownTranslation"
            >Die Zeilen der beiden Versionen werden zusammengeführt. Bitte achte darauf, dass jede
            Zeile im Original eine Zeile in der Übersetzung hat.</v-alert
          >
        </v-col>
      </v-row>
      <v-row v-if="!ownTranslation">
        <v-col cols="6">
          <v-select
            label="Input-Sprache"
            :items="languages"
            item-title="name"
            item-value="code"
            v-model="srcLanguage"
          ></v-select>
        </v-col>
        <v-col cols="6">
          <v-select
            label="Output-Sprache"
            :items="languages"
            item-title="name"
            item-value="code"
            v-model="dstLanguage"
          ></v-select>
        </v-col>
      </v-row>
    </v-container>
    <v-divider></v-divider>
    <v-container>
      <v-progress-linear indeterminate :active="transLoading"></v-progress-linear>
      <v-row>
        <v-col cols="12">
          <v-alert
            v-if="transErr"
            text="Leider ist bei der Übersetzung ein Fehler aufgetreten. Eventuell ist diese Sprache nicht verfügbar."
            type="error"
          ></v-alert>
        </v-col>
      </v-row>
      <v-row>
        <v-col>
          <p class="mb-2">Dein Input:</p>
          <v-textarea v-model="inputText" name="input" id="input" cols="30" rows="10"></v-textarea>
        </v-col>
        <v-col>
          <p class="mb-2">Übersetzung:</p>
          <v-textarea
            v-model="outputText"
            :readonly="!ownTranslation"
            name="output"
            id="output"
            cols="30"
            rows="10"
          ></v-textarea>
        </v-col>
      </v-row>
      <v-row>
        <v-col cols="6" offset="3">
          <p class="mb-2">Zusammengefügter SongBeamer-Text:</p>
          <v-textarea
            :model-value="sbOutputText"
            readonly
            name="sb-output"
            id="sb-output"
            cols="30"
            rows="10"
          ></v-textarea>
          <v-btn @click="triggerPutTogether" color="primary" variant="tonal" class="d-block mx-auto"
            >Zusammenfügen</v-btn
          >
        </v-col>
      </v-row>
    </v-container>
  </v-card>
</template>
