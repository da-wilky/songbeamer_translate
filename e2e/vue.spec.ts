import { test, expect } from '@playwright/test'

test('translates input and merges it into SongBeamer text', async ({ page }) => {
  await page.route('https://translate.googleapis.com/**', (route) => {
    const q = new URL(route.request().url()).searchParams.get('q') ?? ''
    return route.fulfill({ json: [[[q.toUpperCase(), q]]] })
  })
  await page.goto('/')
  await expect(page.locator('h1')).toHaveText('Songbeamer Translator')

  await page.locator('#input').fill('Strophe 1\nYou & me #1\n\n---\nVersprechen')

  await expect(page.locator('#output')).toHaveValue('STROPHE 1\nYOU & ME #1\n\n---\nVERSPRECHEN')
  await expect(page.locator('#sb-output')).toHaveValue(
    'Strophe 1\nYou & me #1\nYOU & ME #1\n\n---\nVersprechen\nVERSPRECHEN\n'
  )
})

test('typing a trailing space or newline is kept', async ({ page }) => {
  await page.route('https://translate.googleapis.com/**', (route) => route.fulfill({ json: [[]] }))
  await page.goto('/')
  await page.locator('#input').pressSequentially('Hello world\n')
  await expect(page.locator('#input')).toHaveValue('Hello world\n')
})
