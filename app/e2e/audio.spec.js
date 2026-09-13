import { test, expect } from '@playwright/test'

test('the sound invite enables audio and reveals the mute toggle', async ({ page }) => {
  test.setTimeout(60000)
  const errors = []
  page.on('pageerror', (e) => errors.push(e.message))
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()) })

  await page.goto('/')
  await page.waitForFunction(() => document.body.dataset.mode === 'webgl')

  const invite = page.locator('#sound-invite')
  await expect(invite).toBeVisible()
  await expect(page.locator('#sound-toggle')).toBeHidden()

  await invite.click() // trusted gesture → AudioContext.resume()
  await page.waitForFunction(() => window.__audio && window.__audio.enabled === true, { timeout: 5000 })
  await expect(page.locator('#sound-toggle')).toBeVisible()
  await expect(invite).toBeHidden()

  const muted = await page.evaluate(() => window.__audio.toggleMute())
  expect(muted).toBe(true)

  // Exercise the enabled SFX path (sfx.tick/cut/riser via update()) by scrolling
  // through the whole timeline now that audio is live, not just the disabled no-op.
  // ~5fps headless WebGL + onScroll sync:0.15 smoothing converges per-frame; poll
  // for the reveal (like smoke.spec.js) rather than a fixed sleep.
  await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight))
  await page.waitForFunction(() => window.__scene.whale.containers.scale.x > 0.9, { timeout: 50000 })

  expect(errors, errors.join('\n')).toEqual([])
})

test('the reduced-motion fallback shows no audio UI', async ({ browser }) => {
  const page = await browser.newPage({ reducedMotion: 'reduce' })
  await page.goto('/')
  await page.waitForFunction(() => document.body.dataset.mode === 'fallback')
  await expect(page.locator('#sound-invite')).toBeHidden()
  await expect(page.locator('#sound-toggle')).toBeHidden()
  await page.close()
})
