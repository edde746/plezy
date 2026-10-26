import './foliate/view.js';
import { EPUB } from './foliate/epub.js';
import { makeComicBook } from './foliate/comic-book.js';
import { Overlayer } from './foliate/overlayer.js';

const send = (type, data = {}) => { window.dispatchEvent(new CustomEvent('publication-event', {detail:{type,...data}})); return window.flutter_inappwebview?.callHandler('publication', {type, ...data}); };
const view = document.createElement('foliate-view');
document.body.append(view);
let annotations = [], queryGeneration = 0, book, readerSettings = {}, originalDirection, originalSpread;
const fixedScale=()=>{const doc=view.renderer?.getContents?.()[0]?.doc;return doc?.defaultView?.frameElement?.getBoundingClientRect().width/(doc?.documentElement?.clientWidth||1)||1;};
const canPan=()=>view.isFixedLayout&&(typeof readerSettings.zoom==='number'||readerSettings.zoom==='fit-width');
const reportView=()=>send('viewState',{fixed:view.isFixedLayout,zoom:readerSettings.zoom??'fit-page',pages:book?.sections.length??0});
const commitSetting=async(key,value)=>{readerSettings[key]=value;await window.publication.settings(readerSettings);send('readerSetting',{key,value});};
const readerKey=e=>{
 if(/^(INPUT|TEXTAREA|SELECT)$/.test(e.target?.tagName))return;
 if((e.ctrlKey||e.metaKey)&&['+','=','-','0'].includes(e.key)){e.preventDefault();window.publication.zoom(e.key==='0'?'fit-page':e.key==='-'?'out':'in');}
 else if(e.key==='PageDown'){e.preventDefault();view.next();}
 else if(e.key==='PageUp'){e.preventDefault();view.prev();}
 else if(e.key.startsWith('Arrow')){
   if(canPan()){e.preventDefault();view.renderer.scrollBy({left:e.key==='ArrowRight'?80:e.key==='ArrowLeft'?-80:0,top:e.key==='ArrowDown'?80:e.key==='ArrowUp'?-80:0});}
   else if(e.key==='ArrowRight'){e.preventDefault();book.dir==='rtl'?view.prev():view.next();}
   else if(e.key==='ArrowLeft'){e.preventDefault();book.dir==='rtl'?view.next():view.prev();}
 }
};
document.addEventListener('keydown',readerKey);
const resourceURL = name => new URL('book/' + encodeURIComponent(name), location.href).href;
const clean = async (data, type) => {
    data = await data;
    if (!/html|xml|svg/.test(type)) return data;
    const input = data instanceof Blob ? await data.text() : data;
    const doc = new DOMParser().parseFromString(input, type.includes('html') && !type.includes('xhtml') ? 'text/html' : 'application/xml');
    for (const el of doc.querySelectorAll('*')) {
        if (['script','iframe','object','embed','form','base','audio','video'].includes(el.localName.toLowerCase())) { el.remove(); continue; }
        if (el.localName === 'meta' && el.getAttribute('http-equiv')?.toLowerCase() === 'refresh') {el.remove(); continue;}
        for (const attr of [...el.attributes]) if (/^on/i.test(attr.name) || /^(?:javascript|vbscript):/i.test(attr.value.trim())) el.removeAttributeNode(attr);
    }
    return new XMLSerializer().serializeToString(doc);
};
const flatTOC = (items, depth=0) => items.flatMap(i => [{title:i.label ?? '',href:i.href,depth},...flatTOC(i.subitems ?? [],depth+1)]);
view.addEventListener('external-link', e => {e.preventDefault(); send('externalLink');});
view.addEventListener('relocate', ({detail:d}) => send('location', {
    cfi:d.cfi, href:d.tocItem?.href ?? '', title:d.tocItem?.label ?? '',
    fraction:Number.isFinite(d.fraction) ? d.fraction : 0,
    section:d.section?.current ?? 0, sections:d.section?.total ?? book.sections.length,
    text:d.range?.toString().slice(0,500) ?? ''
}));
view.addEventListener('load', ({detail:{doc,index}}) => {
    const selection = () => {
        const selected=doc.getSelection();
        if (!selected?.rangeCount || selected.isCollapsed) return;
        send('selection',{cfi:view.getCFI(index, selected.getRangeAt(0)),quote:selected.toString().slice(0,10000)});
    };
    doc.addEventListener('pointerup',()=>setTimeout(selection,30));
    doc.addEventListener('keyup',selection);
    doc.addEventListener('keydown',readerKey);
    doc.addEventListener('wheel',e=>{if(e.ctrlKey||e.metaKey){e.preventDefault();window.publication.zoom(e.deltaY<0?'in':'out');}},{passive:false});
    let gesture;
    doc.addEventListener('touchstart',e=>{if(!view.isFixedLayout)return;const [a,b]=e.touches;gesture=b?{distance:Math.hypot(a.clientX-b.clientX,a.clientY-b.clientY),scale:fixedScale()}:{x:a.clientX,y:a.clientY};},{passive:true});
    doc.addEventListener('touchmove',e=>{if(!gesture||!view.isFixedLayout)return;const [a,b]=e.touches;if(b&&gesture.distance){e.preventDefault();const zoom=Math.min(6,Math.max(.25,gesture.scale*Math.hypot(a.clientX-b.clientX,a.clientY-b.clientY)/gesture.distance));readerSettings.zoom=zoom;view.renderer.setAttribute('zoom',zoom);}else if(a&&gesture.x!=null&&canPan()){e.preventDefault();view.renderer.scrollBy(gesture.x-a.clientX,gesture.y-a.clientY);gesture={x:a.clientX,y:a.clientY};}},{passive:false});
    doc.addEventListener('touchend',()=>{if(gesture&&view.isFixedLayout){reportView();send('readerSetting',{key:'zoom',value:readerSettings.zoom??'fit-page'});}gesture=null;});
    if(view.isFixedLayout){for(const img of doc.images)if(!img.alt)img.alt=window.readerOptions?.labels?.imagePage??book.sections[index]?.id??'';}

});
view.addEventListener('create-overlay', async () => {for(const a of annotations) await view.addAnnotation(a);});
view.addEventListener('draw-annotation', ({detail:{draw,annotation}}) => draw(Overlayer.highlight,{color:annotation.color ?? '#c9b77e'}));
view.addEventListener('show-annotation', ({detail:{value}}) => send('annotation',{cfi:value}));

const readSMIL = async () => {
    const clips=[];
    const time=value=>{
        const text=(value??'0').replace(/^npt=/,'');
        if(text.endsWith('ms'))return parseFloat(text)/1000;
        const numbers=text.replace(/s$/,'').split(':').map(Number);
        return numbers.reduce((a,n)=>a*60+n,0);
    };
    const relative=(base,ref)=>decodeURIComponent(new URL(ref,new URL(base,'https://publication.invalid/')).pathname.substring(1));
    for(const section of book.sections) {
        if(!section.mediaOverlay)continue;
        const href=section.mediaOverlay.href;
        const xml=await book.loadText(href);
        const doc=new DOMParser().parseFromString(xml,'application/xml');
        for(const par of doc.getElementsByTagNameNS('*','par')) {
            const audio=par.getElementsByTagNameNS('*','audio')[0],text=par.getElementsByTagNameNS('*','text')[0];
            if(!audio||!text)continue;
            const begin=time(audio.getAttribute('clipBegin')),end=time(audio.getAttribute('clipEnd'));
            const textRef=new URL(text.getAttribute('src'),new URL(href,'https://publication.invalid/'));
            if(Number.isFinite(begin)&&Number.isFinite(end)&&end>begin)clips.push({
                audio:relative(href,audio.getAttribute('src')),href:decodeURIComponent(textRef.pathname.substring(1))+textRef.hash,
                beginMs:Math.round(begin*1000),endMs:Math.round(end*1000)
            });
        }
    }
    return clips;
};
window.publication = {
    async open(options) {
        window.readerOptions=options; send('options', options);
        const manifest=await (await fetch('manifest.json')).json();
        const loadBlob=async(name,type)=>{
            if(!(name in manifest.files))return null;
            const blob=await (await fetch(resourceURL(name))).blob();
            return type ? new Blob([blob],{type}) : blob;
        };
        const loadText=async name=>(await loadBlob(name))?.text() ?? null;
        const loader={loadBlob,loadText,getSize:name=>manifest.files[name]??0,
            entries:Object.keys(manifest.files).map(filename=>({filename}))};
        // Foliate's comic extension filter is case-sensitive. Use unique virtual
        // names while resolving bytes against the exact archive paths; changing
        // case in the archive itself could collide on case-sensitive editions.
        const comicFiles=Object.keys(manifest.files)
            .filter(name=>/\.(?:jpe?g|png|gif|bmp|webp|svg|jxl|avif)$/i.test(name))
            .sort(new Intl.Collator([], {numeric:true}).compare);
        const aliases=new Map(comicFiles.map((name,index)=>[
            `${String(index+1).padStart(8,'0')}-${name.replace(/\.[^.]+$/,x=>x.toLowerCase())}`,name]));
        const comicLoader={
            entries:[...aliases.keys()].map(filename=>({filename})),
            loadBlob:name=>loadBlob(aliases.get(name)),getSize:name=>loader.getSize(aliases.get(name)),
        };
        book=manifest.comic ? makeComicBook(comicLoader,{name:options.title}) : await new EPUB(loader).init();
        if(manifest.comic)book.toc.forEach(item=>{item.label=aliases.get(item.href);});
        book.transformTarget?.addEventListener('data',e=>{e.detail.data=clean(e.detail.data,e.detail.type);});
        originalDirection=book.dir; originalSpread=book.rendition?.spread;
        await view.open(book);
        await this.settings(options.settings);
        annotations=options.annotations??[];
        await view.init({lastLocation:options.cfi||undefined,showTextStart:true});
        try {const cover=await book.getCover?.();if(cover&&cover.size<4*1024*1024){const r=new FileReader();r.onload=()=>send('cover',{data:r.result});r.readAsDataURL(cover);}}catch(_){}
        reportView();
        send('ready',{toc:flatTOC(book.toc??[]),fixed:view.isFixedLayout,pages:book.sections.length,language:book.metadata?.language??'',
            overlays:manifest.comic?[]:await readSMIL()});
    },
    async settings(s={}) {
        readerSettings={...readerSettings,...s}; s=readerSettings;
        window.readerOptions.settings=s;
        document.documentElement.style.setProperty('--reader-bg', s.background??'#171717');
        document.documentElement.style.setProperty('--reader-text', s.foreground??'#eeeeee');
        document.body.style.backgroundColor=s.background??'#171717';
        document.body.style.color=s.foreground??'#eeeeee';
        if(!view.renderer)return;
        if(view.isFixedLayout){
            const dir=s.direction==='rtl'?'rtl':s.direction==='ltr'?'ltr':originalDirection;
            const spread=s.spread==='single'?'none':s.spread==='double'?'both':originalSpread;
            if(book.dir!==dir||book.rendition.spread!==spread){const location=view.lastLocation?.cfi;book.dir=dir;book.rendition.spread=spread;view.renderer.open(book);if(location)await view.goTo(location);}
            view.renderer.setAttribute('zoom',s.zoom??'fit-page');
            reportView();return;
        }
        view.renderer.toggleAttribute('animated',!s.reduceMotion);
        view.renderer.setAttribute('flow',s.scrolled?'scrolled':'paginated');
        view.renderer.setAttribute('max-column-count',String(s.columns??2));
        view.renderer.setAttribute('max-inline-size','720px');
        view.renderer.setAttribute('gap',`${Math.min(25,Math.max(2,s.margin??8))}%`);
        view.renderer.setAttribute('margin','24px');
        const size=Math.min(72,Math.max(12,s.fontSize??20))*(s.textScale??1);
        const family=s.font==='sans'?'sans-serif':s.font==='mono'?'monospace':'serif';
        // Publisher CSS often fixes paragraph sizes or colours. User typography
        // must affect that text too; leave fixed-layout art and code intact.
        view.renderer.setStyles?.(`
          :root{color-scheme:${s.dark?'dark':'light'}}
          html{font-size:${size}px!important}
          html,body{color:${s.foreground}!important;background:${s.background}!important}
          body{font-size:1rem!important}
          body,:is(p,div,span,li,dd,dt,blockquote,table,td,th,caption,h1,h2,h3,h4,h5,h6,a){
            font-family:${family}!important;line-height:${s.lineHeight??1.6}!important;
            color:inherit!important;background-color:transparent!important;
          }
          :is(p,li,dd,dt,blockquote,td,th){font-size:1rem!important}
          :is(p,li,dd,dt,blockquote,td,th) span{font-size:inherit!important}
          :is(p,li,dd,dt,blockquote){letter-spacing:${s.letterSpacing??0}em!important;word-spacing:${s.wordSpacing??0}em!important;text-align:${s.justify?'justify':'start'}!important}
          h1{font-size:2rem!important}h2{font-size:1.5rem!important}h3{font-size:1.17rem!important}
          :is(h4,h5,h6){font-size:1rem!important}
          :is(code,pre,kbd,samp),:is(code,pre,kbd,samp) *{font-family:monospace!important}
          img,svg{max-width:100%}
        `);
    },
    next:()=>view.next(), prev:()=>view.prev(), goTo:target=>view.goTo(target),
    async zoom(value){
        if(view.isFixedLayout){const next=value==='actual'?1:value==='in'?Math.min(6,fixedScale()*1.25):value==='out'?Math.max(.25,fixedScale()/1.25):value;await commitSetting('zoom',next);}
        else {const current=readerSettings.fontSize??20;await commitSetting('fontSize',value==='in'?Math.min(72,current+2):value==='out'?Math.max(12,current-2):20);}
        reportView();
    },
    async page(number){const index=Math.min(book.sections.length-1,Math.max(0,Math.round(number)-1));await view.goTo(index);},
    pan:({x=0,y=0})=>view.renderer?.scrollBy(x,y),
    async annotate(a){annotations=annotations.filter(x=>x.value!==a.value);annotations.push(a);await view.addAnnotation(a);send('notes',{annotations});},
    async remove(cfi){annotations=annotations.filter(x=>x.value!==cfi);await view.deleteAnnotation({value:cfi});send('notes',{annotations});},
    async search(query){
        const generation=++queryGeneration;
        if(!query.trim()){view.clearSearch();return [];}
        const results=[];
        for await(const result of view.search({query, draw:Overlayer.outline, drawOptions:{color:window.readerOptions?.settings?.foreground??'#c9b77e', width:1.5, radius:3}})) {
            if(generation!==queryGeneration)return [];
            for(const item of result.subitems??[])results.push({cfi:item.cfi,text:Object.values(item.excerpt??{}).join('')});
            if(results.length>=100)break;
        }
        return results.slice(0,100);
    },
    visibleText(){return view.lastLocation?.range?.toString()??'';},
    toggleSpeech(){
        if(speechSynthesis.speaking){speechSynthesis.cancel();return;}
        const speech=new SpeechSynthesisUtterance(this.visibleText());
        speech.lang=book.metadata?.language??'';speechSynthesis.speak(speech);
    },
    stopSpeech(){globalThis.speechSynthesis?.cancel();},
    async highlightHref(href){await view.goTo(href);},
    close(){queryGeneration++;view.close();}
};
const ready=()=>send('engineReady');
if(new URL(location.href).searchParams.has('external')) { await import('./browser.js'); ready(); }
else if(window.flutter_inappwebview?.callHandler)ready();
else window.addEventListener('flutterInAppWebViewPlatformReady',ready,{once:true});
