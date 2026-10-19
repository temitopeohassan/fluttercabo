// Waitlist form handling for the Cabo landing page.
//
// Set WAITLIST_ENDPOINT to a URL that accepts a JSON POST of
// { name, email, source }: the Cabo backend's /api/v1/waitlist (for example
// https://api.caboapp.online/api/v1/waitlist), or a form service such as Formspree. While it is empty, submissions are only validated and
// logged to the console, and nothing is stored.
const WAITLIST_ENDPOINT = '';

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

document.addEventListener('DOMContentLoaded', () => {
  const year = document.getElementById('year');
  if (year) year.textContent = String(new Date().getFullYear());

  const form = document.getElementById('waitlist-form');
  if (!form) return;

  const name = form.elements.namedItem('name');
  const email = form.elements.namedItem('email');
  const honeypot = form.elements.namedItem('company');
  const status = document.getElementById('form-status');
  const button = form.querySelector('button[type="submit"]');

  function setError(input, message) {
    const error = document.getElementById(`${input.id}-error`);
    input.setAttribute('aria-invalid', message ? 'true' : 'false');
    if (message) input.setAttribute('aria-describedby', error.id);
    else input.removeAttribute('aria-describedby');
    error.hidden = !message;
  }

  function validate() {
    const nameOk = name.value.trim().length > 0;
    const emailOk = EMAIL_PATTERN.test(email.value.trim());
    setError(name, nameOk ? '' : 'invalid');
    setError(email, emailOk ? '' : 'invalid');
    if (!nameOk) name.focus();
    else if (!emailOk) email.focus();
    return nameOk && emailOk;
  }

  function showStatus(message, kind) {
    status.textContent = message;
    status.className = `form-status ${kind}`;
  }

  // Clear an error as soon as the person fixes the field.
  [name, email].forEach((input) =>
    input.addEventListener('input', () => {
      if (input.getAttribute('aria-invalid') === 'true') setError(input, '');
    }),
  );

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    showStatus('', '');
    if (!validate()) return;

    const entry = { name: name.value.trim(), email: email.value.trim(), source: 'website' };
    const firstName = entry.name.split(/\s+/)[0];

    // Bots fill in the hidden field; pretend it worked and drop the entry.
    if (honeypot.value) {
      form.reset();
      showStatus(`Thanks, ${firstName}! You're on the list.`, 'success');
      return;
    }

    button.disabled = true;
    button.textContent = 'Joining…';
    try {
      if (WAITLIST_ENDPOINT) {
        const response = await fetch(WAITLIST_ENDPOINT, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
          body: JSON.stringify(entry),
        });
        if (!response.ok) throw new Error(`Waitlist request failed: ${response.status}`);
      } else {
        console.info('WAITLIST_ENDPOINT is not set; this sign-up was not saved.', entry);
      }
      form.reset();
      showStatus(`Thanks, ${firstName}! You're on the list. We'll email you when Cabo launches.`, 'success');
    } catch (error) {
      console.error(error);
      showStatus('Something went wrong. Please try again in a moment.', 'error');
    } finally {
      button.disabled = false;
      button.textContent = 'Join the waitlist';
    }
  });
});
