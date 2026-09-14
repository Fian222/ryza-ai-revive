/* User-controlled screen clothing vs atlas variant. No costume ids or
   player/model keyword lists. Legacy `undress` / `nsfw` tags are parsed in
   api.js for compatibility, but only the persisted setting is applied here.
   Atlas files stay `{page}nsfw.png`. */
(function (global) {
  'use strict';

  var VARIANT = 'nsfw';

  function enabled() {
    try {
      var app = global.Config && global.Config.section('app');
      return !!(app && app.nsfwPermission === true);
    } catch (e) { return false; }
  }

  function applySetting() {
    var on = enabled();
    var av = global.Avatar;
    if (av && typeof av.setAtlasVariant === 'function') {
      av.setAtlasVariant(on ? VARIANT : 'default');
    }
    return on;
  }

  var Nsfw = {
    VARIANT: VARIANT,
    enabled: enabled,
    permitted: enabled,  // compatibility with the first permission-toggle build
    active: enabled,
    setPermission: function (on) {
      on = on === true;
      if (global.Config && typeof global.Config.set === 'function') {
        global.Config.set('app.nsfwPermission', on);
      }
      return applySetting();
    },
    syncPermission: applySetting,
    /* Legacy callers may ask for a visual reset; re-apply the user's setting
       instead of overriding it. Full settings reset changes Config first. */
    reset: applySetting,
    /* One fact for the system prompt. Not a rule list. */
    screenFact: function () {
      return enabled()
        ? 'いまの画面：肌が見えている（服は脱いだあと）。'
        : 'いまの画面：普段の服を着ている。';
    },
    /* Parsed legacy tags are intentionally inert. */
    onTurn: function () {}
  };

  global.Nsfw = Nsfw;
})(typeof window !== 'undefined' ? window : globalThis);
