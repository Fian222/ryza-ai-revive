/* Screen clothing vs atlas variant. No costume ids, no player-keyword lists.

   With user permission, the LLM decides (including refuse). The tag-line field
   is `undress:on` / `undress:off` (`nsfw` still parsed as an alias). Player
   words never force it. Copying the filled prefix (or omit / keep) leaves the screen.
   Atlas files stay `{page}nsfw.png`. Policy text lives once in api.js. */
(function (global) {
  'use strict';

  var VARIANT = 'nsfw';

  function permitted() {
    try {
      var app = global.Config && global.Config.section('app');
      return !!(app && app.nsfwPermission === true);
    } catch (e) { return false; }
  }

  function apply(on) {
    on = !!on && permitted();
    Nsfw._on = on;
    var av = global.Avatar;
    if (av && typeof av.setAtlasVariant === 'function') {
      av.setAtlasVariant(on ? VARIANT : 'default');
    }
  }

  var Nsfw = {
    VARIANT: VARIANT,
    _on: false,
    permitted: permitted,
    active: function () {
      if (Nsfw._on && !permitted()) apply(false);
      return !!Nsfw._on;
    },
    apply: apply,
    setPermission: function (on) {
      on = on === true;
      if (global.Config && typeof global.Config.set === 'function') {
        global.Config.set('app.nsfwPermission', on);
      }
      if (!on) apply(false);
      return on;
    },
    syncPermission: function () {
      if (!permitted()) apply(false);
      return permitted();
    },
    reset: function () { apply(false); },
    /* One fact for the system prompt. Not a rule list. */
    screenFact: function () {
      return Nsfw.active()
        ? 'いまの画面：肌が見えている（服は脱いだあと）。'
        : 'いまの画面：普段の服を着ている。';
    },
    onTurn: function (reply) {
      var flag = reply && typeof reply.nsfw === 'boolean' ? reply.nsfw : null;
      if (flag === true) apply(true);
      else if (flag === false) apply(false);
    }
  };

  global.Nsfw = Nsfw;
})(typeof window !== 'undefined' ? window : globalThis);
