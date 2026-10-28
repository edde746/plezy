// Linux uses the same Foliate engine in the system browser. The loopback
// capability exists only while its owning PlezyNG reader/profile is alive.
const bridgeURL=new URL('bridge',location.href);bridgeURL.protocol='ws:';
const socket=new WebSocket(bridgeURL);
await new Promise((resolve,reject)=>{socket.addEventListener('open',resolve,{once:true});socket.addEventListener('error',reject,{once:true});});
const emit=(type,data={})=>socket.send(JSON.stringify({type,...data}));
window.flutter_inappwebview={callHandler:async(_handler,data)=>{if(!['options','notes','annotation'].includes(data.type))emit(data.type,data);}};
socket.addEventListener('message',async({data})=>{
    const command=JSON.parse(data);
    if(command.error){status.textContent=labels.error;return;}
    try {const value=await window.publication[command.method](command.argument);socket.send(JSON.stringify({reply:command.id,value:value??null}));}
    catch(_){socket.send(JSON.stringify({reply:command.id,error:true}));}
});
const style=document.createElement('style');
style.textContent=`
@font-face{font-family:ReaderNoto;src:url('reader-ui.ttf') format('truetype');font-display:swap}@font-face{font-family:ReaderHangul;src:url('reader-hangul.ttf') format('truetype');font-display:swap}
@font-face{font-family:MaterialSymbols;src:url('material-symbols.ttf') format('truetype')} .reader-icon{display:inline-block;font-family:MaterialSymbols;font-size:24px;font-weight:400;line-height:1;font-variation-settings:'FILL' var(--icon-fill,1),'wght' var(--icon-weight,700),'GRAD' 0,'opsz' 24} button{min-height:48px;min-width:48px}
:root{--reader-bg:#171717;--reader-text:#eee;--reader-text-scale:1}body{font-family:system-ui,ReaderNoto,ReaderHangul,sans-serif;color:var(--reader-text);background:var(--reader-bg);font-size:calc(16px * var(--reader-text-scale,1))}
foliate-view,comic-view{height:calc(100% - 64px)}header{box-sizing:border-box;display:flex;align-items:center;gap:8px;height:64px;padding:8px 20px;border-bottom:1px solid color-mix(in srgb,var(--reader-text) 12%,transparent)}
header{overflow-x:auto;flex-shrink:0}header button{flex-shrink:0}header strong{font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;flex:1;font-size:calc(14px * var(--reader-text-scale,1))}button,input,select,textarea{line-height:1.5;font:inherit;color:inherit}button{background:transparent;border:0;border-radius:24px;padding:10px 14px;cursor:pointer}button:hover{background:color-mix(in srgb,var(--reader-text) 10%,transparent)}button:focus-visible,input:focus-visible,textarea:focus-visible,select:focus-visible{outline:2px solid currentColor;outline-offset:2px}svg{height:22px;width:22px;vertical-align:middle;fill:none;stroke:currentColor;stroke-width:1.7;stroke-linecap:round;stroke-linejoin:round}#reader-status{font-size:calc(12px * var(--reader-text-scale,1));opacity:.65;white-space:nowrap}dialog{box-sizing:border-box;max-width:min(640px,90vw);max-height:80vh;width:100%;border:1px solid color-mix(in srgb,var(--reader-text) 15%,transparent);border-radius:24px;padding:24px;background:var(--reader-bg);color:var(--reader-text)}dialog::backdrop{background:#0008;backdrop-filter:blur(8px)}dialog h2{font-size:calc(20px * var(--reader-text-scale,1));font-weight:500;margin:0 0 20px}dialog .actions{display:flex;justify-content:flex-end;margin-top:20px}dialog input,dialog textarea,dialog select{box-sizing:border-box;padding:12px;border:1px solid color-mix(in srgb,var(--reader-text) 25%,transparent);border-radius:12px;background:var(--reader-bg);width:100%;margin:8px 0 16px}dialog textarea{min-height:100px}dialog .row{display:block;text-align:start;width:100%;border-radius:12px;padding:14px 12px;border-bottom:1px solid color-mix(in srgb,var(--reader-text) 8%,transparent)}dialog label{display:block;font-size:calc(14px * var(--reader-text-scale,1))}blockquote{opacity:.7;margin:12px 0;max-height:100px;overflow:auto;font-size:calc(14px * var(--reader-text-scale,1))}body.disconnected foliate-view,body.disconnected comic-view{pointer-events:none;opacity:.35}@media(max-width:600px){header{padding:8px;gap:0}header strong{display:none}button{padding:10px}#reader-status{margin-inline-start:auto}}
`;
style.textContent+=`dialog[open]{display:flex;flex-direction:column}dialog>.reader-dialog-content{flex:1 1 auto;min-height:0;overflow:auto}dialog .actions{flex:0 0 auto}`;
style.textContent+='[dir=rtl] header button[data-reader-directional] .reader-icon{transform:scaleX(-1)}';
document.head.append(style);
const header=document.createElement('header'),title=document.createElement('strong'),status=document.createElement('span');status.id='reader-status';status.setAttribute('aria-live','polite');title.dir='auto';title.textContent='PlezyNG';
const buttons={};
function button(key,action){const b=document.createElement('button');b.type='button';b.disabled=true;const icon=document.createElement('span');icon.className='reader-icon';icon.setAttribute('aria-hidden','true');b.append(icon);b.onclick=()=>Promise.resolve(action()).catch(()=>status.textContent=labels.error);if(key==='prev'||key==='next')b.dataset.readerDirectional='';buttons[key]=b;return b;}
let labels={},toc=[],notes=[],selection=null,locationState={},settings={},isFixed=false,isComic=false,pages=0,previewOnly=false;
let numbers=new Intl.NumberFormat(),percent=new Intl.NumberFormat(undefined,{style:'percent',maximumFractionDigits:0});
function pageNumber(text){
    const zeroes=[0x30,0x660,0x6f0,0x966,0x9e6,0xa66,0xae6,0xb66,0xbe6,0xc66,0xce6,0xd66,0xde6,0xe50,0xed0,0xf20,0x1040,0x1090,0x17e0,0x1810,0xff10];
    const normalized=Array.from(text.trim(),c=>{const code=c.codePointAt(0),zero=zeroes.find(z=>code>=z&&code<=z+9);return zero===undefined?c:String(code-zero);}).join('');
    return /^\d+$/.test(normalized)&&Number.isSafeInteger(Number(normalized))?Number(normalized):NaN;
}
const dialog=document.createElement('dialog');document.body.append(dialog);
function show(name){dialog.replaceChildren();const h=document.createElement('h2');h.textContent=name;h.id='reader-dialog-title';dialog.setAttribute('aria-labelledby',h.id);dialog.append(h);const content=document.createElement('div');content.className='reader-dialog-content';dialog.append(content);const actions=document.createElement('div');actions.className='actions';const close=document.createElement('button');close.textContent=labels.close??'Close';close.onclick=()=>dialog.close();actions.append(close);dialog.append(actions);if(!dialog.open)dialog.showModal();return {content,actions};}
function row(parent,label,action){const b=document.createElement('button');b.className='row';b.dir='auto';b.textContent=label;b.onclick=action;parent.append(b);return b;}
function showNotes(){const {content,actions}=show(labels.notes);for(const note of notes){row(content,note.note||note.quote||labels.bookmark,()=>{window.publication.goTo(note.value);dialog.close();});}const add=document.createElement('button');add.textContent=labels.addNote;add.onclick=createNote;actions.prepend(add);}
function createNote(){const {content,actions}=show(labels.addNote);const quote=document.createElement('blockquote');quote.textContent=selection?.quote??'';content.append(quote);const input=document.createElement('textarea');input.setAttribute('aria-label',labels.addNote);input.maxLength=10000;content.append(input);const save=document.createElement('button');save.textContent=labels.save;save.onclick=()=>{emit('saveNote',{note:input.value,quote:selection?.quote??'',cfi:selection?.cfi??locationState.cfi});dialog.close();selection=null;};actions.prepend(save);input.focus();}
function showContents(start=0){
    if(!isComic){const {content}=show(labels.toc);for(const item of toc){const b=row(content,item.title,()=>{window.publication.goTo(item.href);dialog.close();});b.style.paddingInlineStart=(12+item.depth*16)+'px';}return;}
    if(typeof start!=='number')start=0;
    const {content,actions}=show(labels.thumbnails),grid=document.createElement('div');
    grid.style.cssText='display:grid;grid-template-columns:repeat(auto-fit,minmax(120px,1fr));gap:12px';
    const end=Math.min(toc.length,start+8);
    for(let i=start;i<end;i++){
        const b=document.createElement('button'),img=document.createElement('img'),caption=document.createElement('span');
        b.type='button';b.style.borderRadius='12px';b.style.padding='8px';
        img.src=window.publication.thumbnail(i);img.alt='';img.loading='lazy';img.decoding='async';img.style.cssText='width:100%;height:160px;object-fit:contain;display:block';
        caption.textContent=toc[i].title;b.setAttribute('aria-label',caption.textContent);
        if(i===(locationState.section??0))b.setAttribute('aria-current','page');
        b.append(img,caption);b.onclick=()=>{window.publication.page(i+1);dialog.close();};grid.append(b);
    }
    content.append(grid);
    // show() opens the dialog before its lazy contents are appended, so move
    // initial focus from the Close action into the page list explicitly.
    grid.querySelector('button')?.focus();
    const previous=document.createElement('button'),next=document.createElement('button');
    previous.textContent=labels.prev;previous.disabled=start===0;previous.onclick=()=>showContents(Math.max(0,start-8));
    next.textContent=labels.next;next.disabled=end===toc.length;next.onclick=()=>showContents(end);
    actions.prepend(previous,next);
}
header.append(button('zoomOut',()=>window.publication.zoom('out')),button('zoomIn',()=>window.publication.zoom('in')),button('fitPage',()=>window.publication.zoom('fit-page')),button('prev',()=>window.publication.prev()),button('next',()=>window.publication.next()),title,
    button('toc',()=>showContents(Math.floor((locationState.section??0)/8)*8)),
    button('search',()=>{const {content}=show(labels.search),input=document.createElement('input'),results=document.createElement('div');input.placeholder=labels.search;input.setAttribute('aria-label',labels.search);input.type='search';results.setAttribute('aria-live','polite');content.append(input,results);input.onkeydown=async(e)=>{if(e.key!=='Enter')return;results.replaceChildren();const matches=await window.publication.search(input.value);if(!matches.length)results.textContent=labels.noMatches;for(const result of matches)row(results,result.text,()=>{window.publication.goTo(result.cfi);dialog.close();});};input.focus();}),
    button('note',()=>selection?createNote():showNotes()),
    button('speak',()=>emit('browserSpeech',{stop:speechSynthesis.speaking})),
    button('page',()=>{const label=isFixed?labels.goToPage:labels.goToSection;const {content,actions}=show(label),input=document.createElement('input'),go=document.createElement('button');input.type='text';input.inputMode='numeric';input.required=true;input.value=numbers.format((locationState.section??0)+1);input.oninput=()=>input.setCustomValidity('');input.setAttribute('aria-label',label);content.append(input);go.textContent=label;go.onclick=()=>{const value=pageNumber(input.value);if(Number.isInteger(value)&&value>=1&&value<=pages){window.publication.page(value);dialog.close();}else{input.setCustomValidity((labels.pageRange??'').replace('{count}',numbers.format(pages)));input.reportValidity();}};input.onkeydown=e=>{if(e.key==='Enter')go.click();};actions.prepend(go);input.focus();}),
    button('settings',()=>{
      settings=window.readerOptions.settings??settings;
      const {content,actions}=show(labels.settings);
      if(isComic){const help=document.createElement('p');help.textContent=labels.comicHelp;content.append(help);}
      const options=[['theme',labels.theme,['app','paper','sepia','night']],...(isFixed?
        [...(isComic?[['comicMode',labels.comicMode,['paged','webtoon']],['coverAlone',labels.coverAlone,[true,false]],['splitWide',labels.splitWide,[false,true]]]:[]),['zoom',labels.zoom,isComic?['fit-page','fit-width','fit-height',1]:['fit-page','fit-width',1]],['spread',labels.pageLayout,['auto','single','double']],['direction',labels.readingDirection,['auto','ltr','rtl']]]:
        [['font',labels.font,['serif','sans','mono']],['fontSize',labels.fontSize,[12,14,16,18,20,24,28,32,40,48,56,64,72]],['lineHeight',labels.lineHeight,[1,1.2,1.4,1.6,1.8,2,2.5]],['letterSpacing',labels.letterSpacing,[0,.05,.1,.2,.3]],['wordSpacing',labels.wordSpacing,[0,.1,.2,.3,.5]],['margin',labels.margin,[2,4,8,12,16,20]],['columns',labels.columns,[1,2]],['scrolled',labels.scrolled,[false,true]],['justify',labels.justify,[false,true]]])];
      const controls={};
      const updateControls=()=>{
        if(!isComic)return;
        controls.spread.disabled=settings.comicMode==='webtoon'||settings.splitWide===true;
        controls.coverAlone.disabled=controls.splitWide.disabled=settings.comicMode==='webtoon';
      };
      for(const [key,label,values] of options){
        const l=document.createElement('label');l.textContent=label;
        const select=document.createElement('select');select.setAttribute('aria-label',label??key);
        for(const value of values){
          const option=document.createElement('option');option.value=JSON.stringify(value);
          const names={'fit-page':labels.fitPage,'fit-width':labels.fitWidth,'fit-height':labels.fitHeight,auto:labels.automatic,single:labels.singlePage,double:labels.twoPages,ltr:labels.leftToRight,rtl:labels.rightToLeft};
          option.textContent=typeof value==='boolean'?(value?labels.on:labels.off):key==='zoom'&&value===1?labels.actualSize:(names[value]??labels[value]??(typeof value==='number'?numbers.format(value):String(value)));
          option.selected=settings[key]===value;select.append(option);
        }
        controls[key]=select;
        select.onchange=()=>{settings={...window.readerOptions.settings,...settings,[key]:JSON.parse(select.value)};updateControls();emit('browserSettings',{settings});};
        l.append(select);content.append(l);
      }
      updateControls();
      const reset=document.createElement('button');reset.textContent=labels.reset;reset.onclick=()=>{emit('browserSettings',{reset:true});dialog.close();};actions.prepend(reset);
    }),
    button('full',()=>document.fullscreenElement?document.exitFullscreen():document.documentElement.requestFullscreen()),status);
document.body.prepend(header);
function updateJumpButtonLabel(){
    const label=(isFixed?labels.goToPage:labels.goToSection)??labels.page??'page';
    buttons.page.title=label;buttons.page.setAttribute('aria-label',label);
}
window.addEventListener('publication-event',({detail:d})=>{
    if(d.type==='options'){document.documentElement.lang=d.interfaceLocale??'en';document.documentElement.dir=d.interfaceDirection==='rtl'?'rtl':'ltr';numbers=new Intl.NumberFormat(d.formattingLocale??d.interfaceLocale,{useGrouping:false,maximumFractionDigits:2});percent=new Intl.NumberFormat(d.formattingLocale??d.interfaceLocale,{style:'percent',maximumFractionDigits:0});title.textContent=d.title;document.title=d.title+' · PlezyNG';labels=d.labels??{};previewOnly=d.previewOnly===true;document.documentElement.style.setProperty('--icon-fill',d.iconStyle?.fill??1);document.documentElement.style.setProperty('--icon-weight',d.iconStyle?.weight??700);settings=d.settings??{};const textScale=Number(settings.textScale);document.documentElement.style.setProperty('--reader-text-scale',Number.isFinite(textScale)&&textScale>0?String(textScale):'1');notes=d.annotations??[];for(const [key,b] of Object.entries(buttons)){b.title=labels[key]??key;b.setAttribute('aria-label',b.title);if(d.icons?.[key])b.firstChild.textContent=String.fromCodePoint(d.icons[key]);}buttons.note.hidden=previewOnly;updateJumpButtonLabel();}
    if(d.type==='ready'){toc=d.toc;isFixed=d.fixed;isComic=d.comic===true;pages=d.pages;updateJumpButtonLabel();for(const b of Object.values(buttons))b.disabled=false;if(isComic){buttons.search.hidden=true;buttons.speak.hidden=true;buttons.toc.title=labels.thumbnails;buttons.toc.setAttribute('aria-label',labels.thumbnails);}}
    if(d.type==='viewState'){isFixed=d.fixed;pages=d.pages;updateJumpButtonLabel();}
    if(d.type==='readerSetting')settings[d.key]=d.value;
    if(d.type==='notes')notes=d.annotations;
    if(d.type==='location'){locationState=d;selection=null;status.textContent=percent.format(d.fraction);}
    if(d.type==='selection')selection=d;
    if(d.type==='annotation')showNotes();
});
socket.addEventListener('close',()=>{speechSynthesis.cancel();document.body.classList.add('disconnected');status.textContent=labels.disconnected??'Return to PlezyNG';for(const b of Object.values(buttons))b.disabled=true;});
window.addEventListener('pagehide',()=>{speechSynthesis.cancel();socket.close();});
