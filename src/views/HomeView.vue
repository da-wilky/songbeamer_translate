<script setup lang="ts">
import { mdiThemeLightDark } from '@mdi/js'
import ISO6391 from 'iso-639-1'
import { Translate } from 'translate'
import { ref, watch } from 'vue'
import { useTheme } from 'vuetify'
const theme = useTheme()
const translate = Translate({ engine: 'google' })

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

async function triggerTranslate() {
  transErr.value = false
  transLoading.value = true
  inputText.value = inputText.value.trim()
  if (inputText.value === '') {
    outputText.value = ''
    transLoading.value = false
    return
  }
  const res = await translate(inputText.value, {
    from: srcLanguage.value,
    to: dstLanguage.value
  }).catch((err) => {
    console.error(err)
    outputText.value = ''
    transErr.value = true
  })
  if (res) outputText.value = res
  transLoading.value = false
}

function triggerPutTogether() {
  let res = ''
  const regex = /(Refrain|Chorus|Strophe|Vers|Bridge|Intro|Outro|Pre-Chorus|Pre-Refrain)\s?\d*/

  const linesOut = outputText.value.split('\n')
  inputText.value.split('\n').forEach((line, i) => {
    if (line === '' || line === '\n' || line === '---' || regex.test(line)) {
      res += `${line}\n`
      return
    }
    res += `${line}\n${linesOut[i]}\n`
  })
  sbOutputText.value = res
}

const toggleTheme = () => {
  theme.global.name.value = theme.global.current.value.dark ? 'light' : 'dark'
}

watch(
  () => [inputText.value, dstLanguage.value, srcLanguage.value],
  () => {
    if (ownTranslation.value) return
    triggerTranslate()
  }
)
watch(outputText, () => {
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
