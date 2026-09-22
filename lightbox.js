/* ---- Site lightbox ----
   One gif viewer for the whole site (home grid and gifs page), so both look
   and behave the same. Styles live in style.css under "Site lightbox".

   Shows the gif centred, its filename above and its caption below, at most
   2 screen pixels per gif pixel. Prev / next step through the page's gifs;
   Escape, the x, or a click on the backdrop closes it.

   Captions are the <figcaption>s in gifs.html's lightboxes (kept by
   update-gifs.ps1), so a caption is only ever written in one place.

   Usage, after this script:
     siteLightbox.readCaptions(doc)   // doc = document, or a parsed gifs.html
     siteLightbox.gallery(selector)   // these <img>s open the viewer
*/
(function(){
  // At most 2 screen pixels per gif pixel, smaller if the screen can't fit it.
  // Worked out in DEVICE pixels, so display scaling can't inflate it, and in
  // whole steps (1x or 2x) when enlarging, so pixel art keeps square pixels.
  const LB_MAX = 2;

  const lb = document.createElement('div');
  lb.id = 'lightbox';
  lb.hidden = true;
  lb.innerHTML =
      '<button class="lb-close" type="button" aria-label="close">&times;</button>'
    + '<button class="lb-prev" type="button" aria-label="previous">&lsaquo;</button>'
    + '<button class="lb-next" type="button" aria-label="next">&rsaquo;</button>'
    + '<figure id="lb-fig"><div id="lb-name"></div><img id="lb-img" alt="">'
    + '<figcaption id="lb-cap"></figcaption></figure>';
  document.body.appendChild(lb);

  const img  = lb.querySelector('#lb-img');
  const name = lb.querySelector('#lb-name');
  const cap  = lb.querySelector('#lb-cap');
  const prev = lb.querySelector('.lb-prev');
  const next = lb.querySelector('.lb-next');

  // absolute URL, so "nectro 2.gif" and "nectro%202.gif" are the same key
  const key = src => new URL(src, location.href).href;

  // "images/gifs/nectro%202.gif" -> "nectro 2.gif"
  function fileName(src){
    const last = new URL(src, location.href).pathname.split('/').pop();
    try{ return decodeURIComponent(last); } catch(e){ return last; }
  }

  const captions = new Map();
  function readCaptions(doc){
    for(const shot of doc.querySelectorAll('.lightbox .shot')){
      const i = shot.querySelector('img'), c = shot.querySelector('figcaption');
      const html = c ? c.innerHTML.trim() : '';
      if(i && html) captions.set(key(i.getAttribute('src')), html);
    }
  }

  let list = [], at = 0;

  function fit(){
    const nw = img.naturalWidth, nh = img.naturalHeight;
    if(!nw || !nh) return;
    const d = window.devicePixelRatio || 1;
    // leave room for the filename above, the caption below, and the arrows
    const capH  = cap.innerHTML ? cap.offsetHeight + 14 : 0;
    const nameH = name.offsetHeight + 10;
    const maxW  = Math.min(innerWidth * 0.9, innerWidth - 140);
    const maxH  = innerHeight * 0.85 - capH - nameH;
    const s = Math.min(Math.min(maxW / nw, maxH / nh) * d, LB_MAX);
    const k = (s >= 1 ? Math.floor(s) : Math.max(s, 0.05)) / d;
    img.style.width  = (nw * k) + 'px';
    img.style.height = (nh * k) + 'px';
  }

  function show(){
    const src = list[at];
    img.style.width = img.style.height = '';
    name.textContent = fileName(src);
    cap.innerHTML = captions.get(src) || '';
    prev.hidden = next.hidden = list.length < 2;
    img.onload = fit;
    img.src = src;
    if(img.complete) fit();
  }

  function open(src, srcs){
    const k = key(src);
    list = (srcs && srcs.length) ? srcs.map(key) : [k];
    at = list.indexOf(k);
    if(at < 0){ list = [k]; at = 0; }
    lb.hidden = false;
    show();
  }

  function step(dir){
    at = (at + dir + list.length) % list.length;
    show();
  }

  function close(){
    lb.hidden = true;
    img.removeAttribute('src');
    cap.innerHTML = '';
    name.textContent = '';
  }

  // Any click on a matching <img> opens the viewer; prev / next follow page
  // order. preventDefault also stops the gifs page's old CSS lightbox (a
  // radio behind each thumbnail's <label>), which stays only as the no-JS
  // fallback and the home of the captions.
  function gallery(selector){
    document.addEventListener('click', e => {
      const hit = e.target.closest && e.target.closest(selector);
      if(!hit) return;
      e.preventDefault();
      open(hit.src, [...document.querySelectorAll(selector)].map(i => i.src));
    });
  }

  // only the backdrop itself closes; the image and caption (whose links
  // should work) count as the viewer
  lb.addEventListener('click', e => { if(e.target === lb) close(); });
  lb.querySelector('.lb-close').addEventListener('click', close);
  prev.addEventListener('click', () => step(-1));
  next.addEventListener('click', () => step(1));

  addEventListener('keydown', e => {
    if(lb.hidden) return;
    if(e.key === 'Escape') close();
    else if(e.key === 'ArrowLeft')  step(-1);
    else if(e.key === 'ArrowRight') step(1);
  });
  addEventListener('resize', () => { if(!lb.hidden) fit(); });

  window.siteLightbox = { open, close, readCaptions, gallery };
})();
