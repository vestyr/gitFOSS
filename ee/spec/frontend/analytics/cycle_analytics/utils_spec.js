import {
  isStartEvent,
  isLabelEvent,
  getAllowedEndEvents,
  eventToOption,
  eventsByIdentifier,
  getLabelEventsIdentifiers,
} from 'ee/analytics/cycle_analytics/utils';
import { apiResponse } from './mock_data';

const { events } = apiResponse;

const startEvent = events[0];
const endEvent = events[1];
const labelEvent = events[11];
const labelEvents = [events[10], events[11]].map(i => i.identifier);

describe('Cycle analytics utils', () => {
  describe('isStartEvent', () => {
    it('will return true for a valid start event', () => {
      expect(isStartEvent(startEvent)).toEqual(true);
    });

    it('will return false for input that is not a start event', () => {
      [endEvent, {}, [], null, undefined].forEach(ev => {
        expect(isStartEvent(ev)).toEqual(false);
      });
    });
  });

  describe('isLabelEvent', () => {
    it('will return true if the given event identifier is in the labelEvents array', () => {
      expect(isLabelEvent(labelEvents, labelEvent.identifier)).toEqual(true);
    });
    it('will return false if the given event identifier is not in the labelEvents array', () => {
      [startEvent.identifier, null, undefined, ''].forEach(ev => {
        expect(isLabelEvent(labelEvents, ev)).toEqual(false);
      });
      expect(isLabelEvent(labelEvents)).toEqual(false);
    });
  });

  describe('eventToOption', () => {
    it('will return null if no valid object is passed in', () => {
      [{}, [], null, undefined].forEach(i => {
        expect(eventToOption(i)).toEqual(null);
      });
    });

    it('will set the "value" property to the events identifier', () => {
      events.forEach(ev => {
        const res = eventToOption(ev);
        expect(res.value).toEqual(ev.identifier);
      });
    });

    it('will set the "text" property to the events name', () => {
      events.forEach(ev => {
        const res = eventToOption(ev);
        expect(res.text).toEqual(ev.name);
      });
    });
  });

  describe('getLabelEventsIdentifiers', () => {
    it('will return an array of identifiers for the label events', () => {
      const res = getLabelEventsIdentifiers(events);
      expect(res.length).toEqual(labelEvents.length);
      expect(res).toEqual(labelEvents);
    });
    it('will return an empty array when there are no matches', () => {
      const ev = [{ _type: 'simple' }, { type: 'simple' }, { t: 'simple' }];
      expect(getLabelEventsIdentifiers(ev)).toEqual([]);
      expect(getLabelEventsIdentifiers([])).toEqual([]);
    });
  });

  describe('getAllowedEndEvents', () => {
    it('will return the relevant end events for a given start event identifier', () => {
      const se = events[10].allowedEndEvents;
      expect(getAllowedEndEvents(events, 'issue_label_added')).toEqual(se);
    });

    it('will return an empty array if there are no end events available', () => {
      ['cool_issue_label_added', [], {}, null, undefined].forEach(ev => {
        expect(getAllowedEndEvents(events, ev)).toEqual([]);
      });
    });
  });

  describe('eventsByIdentifier', () => {
    it('will return the events with an identifier in the provided array', () => {
      expect(eventsByIdentifier(events, labelEvents)).toEqual([events[10], events[11]]);
    });

    it('will return an empty array if there are no matching events', () => {
      [['lol', 'bad'], [], {}, null, undefined].forEach(items => {
        expect(eventsByIdentifier(events, items)).toEqual([]);
      });
      expect(eventsByIdentifier([], labelEvents)).toEqual([]);
    });
  });
});