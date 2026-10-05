import { readFileSync } from 'node:fs';
import { expect, test, type Page } from '@playwright/test';
import { copy } from '../src/marketing/copy';

// The original's names, domains and colours are read from brand.json, never
// written here, because the brand sweep scans this folder too.
const brand = JSON.parse(
  readFileSync(new URL('../../../replica/brand.json', import.meta.url), 'utf8'),
) as { avoid: string[]; domains: string[]; colors: string[] };

const DESKTOP = { width: 1280, height: 800 };
const PHONE = { width: 320, height: 800 };

type Box = { x: number; y: number; width: number; height: number };

async function box(page: Page, selector: string): Promise<Box> {
  const result = await page.locator(selector).first().boundingBox();
  if (!result) throw new Error(`${selector} has no bounding box`);
  return result;
}

async function computed(page: Page, selector: string, properties: string[]) {
  return page
    .locator(selector)
    .first()
    .evaluate((element, names) => {
      const style = getComputedStyle(element);
      return Object.fromEntries(names.map((name) => [name, style.getPropertyValue(name)]));
    }, properties);
}

async function expectNoHorizontalScroll(page: Page) {
  const { scrollWidth, clientWidth } = await page.evaluate(() => ({
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth,
  }));
  expect(scrollWidth).toBeLessThanOrEqual(clientWidth);
}

/** The background a reader sees behind an element: its own, or its nearest painted ancestor's. */
async function effectiveBackground(page: Page, selector: string) {
  return page.locator(selector).evaluate((element) => {
    for (let node: Element | null = element; node; node = node.parentElement) {
      const color = getComputedStyle(node).backgroundColor;
      if (color !== 'rgba(0, 0, 0, 0)' && color !== 'transparent') return color;
    }
    return 'none';
  });
}

test.describe('content and structure (AC7)', () => {
  test.use({ viewport: DESKTOP });

  test('renders the landing copy in its landmarks and headings', async ({ page }) => {
    await page.goto('/');

    await expect(page).toHaveTitle(copy.meta.title);
    await expect(page.locator('html')).toHaveAttribute('lang', 'en');

    await expect(page.locator('header')).toHaveCount(1);
    await expect(page.locator('main')).toHaveCount(1);
    await expect(page.locator('footer')).toHaveCount(1);

    await expect(page.locator('h1')).toHaveCount(1);
    await expect(page.locator('h1')).toHaveText(copy.hero.headline);
    await expect(page.locator('h2')).toHaveText([
      copy.problem.heading,
      copy.howItWorks.heading,
      copy.features.heading,
      copy.faq.heading,
      copy.finalCta.heading,
    ]);

    await expect(page.locator('#problem ul > li')).toHaveCount(3);
    await expect(page.locator('#how-it-works ol > li')).toHaveCount(3);

    const cards = page.locator('#features li:has(h3)');
    await expect(page.locator('#features h3')).toHaveText(copy.features.cards.map((c) => c.title));
    await expect(cards).toHaveCount(8);
    for (const card of await cards.all()) {
      await expect(card).toContainText(copy.status.inProgress);
    }
    for (const item of copy.features.also) {
      await expect(page.locator('#features').getByText(item, { exact: true })).toBeVisible();
    }

    await expect(page.locator('#faq h3')).toHaveText(copy.faq.items.map((qa) => qa.question));
    for (const qa of copy.faq.items) {
      await expect(page.locator('#faq').getByText(qa.answer, { exact: true })).toBeVisible();
    }

    await expect(
      page.locator('#start').getByText(copy.finalCta.lineWithoutLogin, { exact: true }),
    ).toBeVisible();
    await expect(page.getByRole('link', { name: copy.header.logIn })).toHaveCount(0);
    await expect(page.getByRole('button', { name: copy.header.logIn })).toHaveCount(0);

    await expect(
      page.locator('footer').getByText(copy.footer.statusLine, { exact: true }),
    ).toBeVisible();

    await expect(page.getByRole('img', { name: copy.hero.mockAlt })).toBeVisible();
    await expect(page.locator('figcaption')).toHaveText(copy.hero.mockCaption);
    await expect(page.locator('figcaption')).toBeVisible();
  });
});

test.describe('responsive layout and type (AC8)', () => {
  test('phone, 320px: one column, no sideways scroll', async ({ page }) => {
    await page.setViewportSize(PHONE);
    await page.goto('/');
    await expectNoHorizontalScroll(page);

    expect(await computed(page, 'h1', ['font-size', 'font-weight'])).toEqual({
      'font-size': '28px',
      'font-weight': '700',
    });

    const lead = await box(page, '#top p');
    const mock = await box(page, '#top figure');
    const smallPrint = await box(page, '#top p.text-sm');
    expect(mock.y).toBeGreaterThanOrEqual(smallPrint.y + smallPrint.height);
    expect(Math.round(mock.x)).toBe(Math.round(lead.x));

    const cardXs = await page
      .locator('#features li:has(h3)')
      .evaluateAll((items) => items.map((item) => Math.round(item.getBoundingClientRect().x)));
    expect(new Set(cardXs).size).toBe(1);
  });

  test('desktop, 1280px: mock on the right, three card columns', async ({ page }) => {
    await page.setViewportSize(DESKTOP);
    await page.goto('/');
    await expectNoHorizontalScroll(page);

    expect(await computed(page, 'h1', ['font-size', 'font-weight'])).toEqual({
      'font-size': '40px',
      'font-weight': '700',
    });

    const headline = await box(page, '#top h1');
    const smallPrint = await box(page, '#top p.text-sm');
    const mock = await box(page, '#top figure');
    expect(mock.x).toBeGreaterThanOrEqual(headline.x + headline.width);
    expect(mock.y).toBeLessThan(smallPrint.y + smallPrint.height);

    const cardXs = await page
      .locator('#features li:has(h3)')
      .evaluateAll((items) => items.map((item) => Math.round(item.getBoundingClientRect().x)));
    expect(new Set(cardXs).size).toBe(3);

    expect(await computed(page, 'h2', ['font-size', 'line-height', 'font-weight'])).toEqual({
      'font-size': '28px',
      'line-height': '34px',
      'font-weight': '700',
    });
    expect(await computed(page, 'h3', ['font-size', 'line-height', 'font-weight'])).toEqual({
      'font-size': '20px',
      'line-height': '28px',
      'font-weight': '600',
    });
    expect(await computed(page, '#how-it-works > p', ['font-size', 'line-height'])).toEqual({
      'font-size': '16px',
      'line-height': '24px',
    });
  });

  test('desktop at 200% text size: no sideways scroll', async ({ page }) => {
    await page.setViewportSize(DESKTOP);
    await page.goto('/');
    await page.evaluate(() => {
      document.documentElement.style.fontSize = '200%';
    });
    expect(await computed(page, 'html', ['font-size'])).toEqual({ 'font-size': '32px' });
    await expectNoHorizontalScroll(page);
  });

  test('body uses the self-hosted next/font family', async ({ page }) => {
    await page.goto('/');
    const { variable, bodyFamily, loaded } = await page.evaluate(async () => {
      await document.fonts.ready;
      const root = getComputedStyle(document.documentElement);
      const family = root.getPropertyValue('--tunehold-font-sans').trim();
      return {
        variable: family,
        bodyFamily: getComputedStyle(document.body).fontFamily,
        loaded: document.fonts.check(`16px ${family}`),
      };
    });
    expect(variable).not.toBe('');
    expect(bodyFamily.startsWith(variable)).toBe(true);
    expect(bodyFamily.startsWith('system-ui')).toBe(false);
    expect(loaded).toBe(true);
  });
});

test.describe('"See how it works" (AC9)', () => {
  test.use({ viewport: DESKTOP });

  test('a click jumps to the section and focuses its heading', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('link', { name: copy.hero.button }).click();
    await expect(page).toHaveURL(/#how-it-works$/);
    const heading = page.getByRole('heading', { level: 2, name: copy.howItWorks.heading });
    await expect(heading).toBeFocused();
    await expect(heading).toBeInViewport();
  });

  test('the keyboard reaches the wordmark, then the button, and Enter does the same', async ({
    page,
  }) => {
    await page.goto('/');
    await page.keyboard.press('Tab');
    await expect(page.getByRole('link', { name: copy.header.wordmark })).toBeFocused();
    await page.keyboard.press('Tab');
    await expect(page.getByRole('link', { name: copy.hero.button })).toBeFocused();
    await page.keyboard.press('Enter');
    await expect(page).toHaveURL(/#how-it-works$/);
    const heading = page.getByRole('heading', { level: 2, name: copy.howItWorks.heading });
    await expect(heading).toBeFocused();
    await expect(heading).toBeInViewport();
  });

  test('smooth scrolling only without a reduced-motion preference', async ({ page }) => {
    await page.goto('/');
    await page.emulateMedia({ reducedMotion: 'reduce' });
    expect(await computed(page, 'html', ['scroll-behavior'])).toEqual({
      'scroll-behavior': 'auto',
    });
    await page.emulateMedia({ reducedMotion: 'no-preference' });
    expect(await computed(page, 'html', ['scroll-behavior'])).toEqual({
      'scroll-behavior': 'smooth',
    });
  });
});

test.describe('accessibility basics (AC10)', () => {
  test.use({ viewport: DESKTOP });

  test('names, heading order, targets, focus ring, no forms', async ({ page }) => {
    await page.goto('/');

    await expect(page.locator('img:not([alt])')).toHaveCount(0);
    for (const control of await page.locator('a, button').all()) {
      await expect(control).toHaveAccessibleName(/\S/);
    }

    const levels = await page
      .locator('h1, h2, h3, h4, h5, h6')
      .evaluateAll((headings) => headings.map((h) => Number(h.tagName.slice(1))));
    expect(levels[0]).toBe(1);
    levels.forEach((level, i) => {
      if (i > 0) expect(level).toBeLessThanOrEqual((levels[i - 1] ?? 0) + 1);
    });

    for (const name of [copy.header.wordmark, copy.hero.button]) {
      const target = await page.getByRole('link', { name }).boundingBox();
      expect(target?.width ?? 0).toBeGreaterThanOrEqual(44);
      expect(target?.height ?? 0).toBeGreaterThanOrEqual(44);
    }

    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    const cta = page.getByRole('link', { name: copy.hero.button });
    await expect(cta).toBeFocused();
    expect(
      await cta.evaluate((element) => {
        const style = getComputedStyle(element);
        return {
          outline: `${style.outlineWidth} ${style.outlineStyle} ${style.outlineColor}`,
          offset: style.outlineOffset,
        };
      }),
    ).toEqual({ outline: '2px solid rgb(172, 156, 250)', offset: '2px' });

    await expect(page.locator('form')).toHaveCount(0);
    await expect(page.locator('input')).toHaveCount(0);
  });

  test('loads with no console error, no failed request and nothing third-party', async ({
    page,
    baseURL,
  }) => {
    const problems: string[] = [];
    const requests: string[] = [];
    page.on('console', (message) => {
      if (message.type() === 'error') problems.push(`console: ${message.text()}`);
    });
    page.on('pageerror', (error) => problems.push(`page error: ${error.message}`));
    page.on('requestfailed', (request) => problems.push(`failed: ${request.url()}`));
    page.on('response', (response) => {
      if (response.status() >= 400) problems.push(`${response.status()}: ${response.url()}`);
    });
    page.on('request', (request) => requests.push(request.url()));

    await page.goto('/', { waitUntil: 'networkidle' });

    // The favicon (Chromium may not request it in headless mode, so fetch it directly).
    const icon = page.locator('link[rel="icon"]');
    await expect(icon).toHaveCount(1);
    const iconHref = await icon.getAttribute('href');
    expect(iconHref).toBeTruthy();
    const iconResponse = await page.request.get(iconHref ?? '');
    expect(iconResponse.status()).toBe(200);
    expect(iconResponse.headers()['content-type']).toContain('image/svg+xml');

    expect(problems).toEqual([]);
    const origin = new URL(baseURL ?? '').origin;
    expect(requests.length).toBeGreaterThan(0);
    for (const url of requests) {
      if (url.startsWith('data:')) continue;
      expect(new URL(url).origin).toBe(origin);
    }
    expect(requests.some((url) => /\.woff2(\?|$)/.test(url))).toBe(true);
  });
});

test.describe('metadata (AC11)', () => {
  test('noindex, description and Open Graph, no image', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('meta[name="robots"]')).toHaveAttribute('content', /noindex/);
    await expect(page.locator('meta[name="description"]')).toHaveAttribute(
      'content',
      copy.meta.description,
    );
    await expect(page.locator('meta[property="og:title"]')).toHaveAttribute('content', 'Tunehold');
    await expect(page.locator('meta[property="og:description"]')).toHaveAttribute(
      'content',
      copy.meta.description,
    );
    await expect(page.locator('meta[property="og:image"]')).toHaveCount(0);
  });
});

test.describe('tokens (AC13) and brand (AC14)', () => {
  test.use({ viewport: DESKTOP });

  test('the hero is on the dark bg and the body on the light bg', async ({ page }) => {
    await page.goto('/');
    expect(await effectiveBackground(page, '#top')).toBe('rgb(16, 14, 23)');
    expect(await effectiveBackground(page, '#problem')).toBe('rgb(251, 250, 254)');
  });

  test("the page and its styles carry none of the original's names, domains or colours", async ({
    page,
  }) => {
    await page.goto('/');
    const sources = [await page.content()];
    for (const href of await page
      .locator('link[rel="stylesheet"]')
      .evaluateAll((links) => links.map((link) => link.getAttribute('href') ?? ''))) {
      sources.push(await (await page.request.get(href)).text());
    }
    const forbidden = [...brand.avoid, ...brand.domains, ...brand.colors].map((s) =>
      s.toLowerCase(),
    );
    expect(forbidden.length).toBeGreaterThan(0);
    for (const source of sources) {
      const text = source.toLowerCase();
      for (const word of forbidden) {
        expect(text.includes(word), `found a forbidden string from brand.json`).toBe(false);
      }
    }
  });
});
