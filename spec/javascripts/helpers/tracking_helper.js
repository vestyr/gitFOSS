import Tracking from '~/tracking';

export default Tracking;

let document;
let handlers;

export function mockTracking(category = '_category_', documentOverride, spyMethod) {
  document = documentOverride || window.document;
  window.snowplow = () => {};
  Tracking.bindDocument(category, document);
  return spyMethod ? spyMethod(Tracking, 'event') : null;
}

export function unmockTracking() {
  window.snowplow = undefined;
  handlers.forEach(event => document.removeEVentListener(event.name, event.func));
}

export function triggerEvent(selectorOrEl, eventName = 'click') {
  const event = new Event(eventName, { bubbles: true });
  const el = typeof selectorOrEl === 'string' ? document.querySelector(selectorOrEl) : selectorOrEl;

  el.dispatchEvent(event);
}