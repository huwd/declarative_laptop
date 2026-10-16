// Client-side search over the index Zola builds (elasticlunr).
// The index and library load on first use, so pages stay light.
(function () {
  var input = document.getElementById("search-input");
  var list = document.getElementById("search-results");
  if (!input || !list) return;

  var index = null;
  var loading = null;

  function load(src) {
    return new Promise(function (resolve, reject) {
      var script = document.createElement("script");
      script.src = src;
      script.onload = resolve;
      script.onerror = reject;
      document.head.appendChild(script);
    });
  }

  function ensureIndex() {
    if (index) return Promise.resolve(index);
    if (!loading) {
      loading = load(input.dataset.lib)
        .then(function () { return load(input.dataset.index); })
        .then(function () {
          index = elasticlunr.Index.load(window.searchIndex);
          return index;
        });
    }
    return loading;
  }

  function teaser(body, terms) {
    var lower = body.toLowerCase();
    var at = -1;
    for (var i = 0; i < terms.length && at < 0; i++) at = lower.indexOf(terms[i]);
    var start = Math.max(0, at - 40);
    var text = body.slice(start, start + 140).trim();
    return (start > 0 ? "… " : "") + text + (start + 140 < body.length ? " …" : "");
  }

  function render(results, terms) {
    list.textContent = "";
    if (results.length === 0) {
      var none = document.createElement("li");
      none.className = "search-empty";
      none.textContent = "No results";
      list.appendChild(none);
    }
    results.slice(0, 8).forEach(function (result) {
      var item = document.createElement("li");
      var link = document.createElement("a");
      link.href = result.ref;
      link.textContent = result.doc.title;
      var summary = document.createElement("span");
      summary.textContent = teaser(result.doc.body || "", terms);
      item.appendChild(link);
      item.appendChild(summary);
      list.appendChild(item);
    });
    list.hidden = false;
  }

  function search() {
    var query = input.value.trim();
    if (query.length < 2) {
      list.hidden = true;
      return;
    }
    ensureIndex().then(function (loaded) {
      var results = loaded.search(query, {
        fields: { title: { boost: 2 }, body: { boost: 1 } },
        bool: "AND",
        expand: true,
      });
      render(results, query.toLowerCase().split(/\s+/));
    });
  }

  input.addEventListener("focus", function () { ensureIndex(); });
  input.addEventListener("input", search);
  document.addEventListener("keydown", function (event) {
    if (event.key === "/" && document.activeElement !== input) {
      event.preventDefault();
      input.focus();
    } else if (event.key === "Escape") {
      list.hidden = true;
      input.blur();
    }
  });
  document.addEventListener("click", function (event) {
    if (!event.target.closest(".search")) list.hidden = true;
  });
})();
