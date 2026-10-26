import {comicTurns, comicLocator, parseComicLocator} from './comic-layout.js';

// The existing reader shell owns chrome, localization, notes and persistence.
// This element owns image layout and keeps only nearby images resident.
export class ComicReader extends HTMLElement {
    constructor() {
        super();
        this.attachShadow({mode: 'open'});
        this.shadowRoot.innerHTML = `<style>
          :host{display:block;min-height:0;width:100%;height:100%;overflow:hidden;position:relative;color:var(--reader-text);background:var(--reader-bg)}
          #viewport{width:100%;height:100%;overflow:auto;overscroll-behavior:contain;touch-action:none;outline-offset:-3px;direction:ltr}
          #stage{min-height:100%;display:flex;justify-content:center;align-items:center;gap:0;direction:ltr}
          #stage.strip{display:block;min-height:0;position:relative}figure{margin:0;flex-shrink:0;position:relative;overflow:hidden}
          img{display:block;max-width:none;user-select:none;-webkit-user-drag:none}figure.split img{position:absolute;top:0}
          button{font:inherit;color:inherit;background:var(--reader-bg);border:1px solid currentColor;border-radius:12px;padding:16px;min-height:48px;cursor:pointer}
          button:focus-visible{outline:2px solid currentColor;outline-offset:2px}.error{display:flex;align-items:center;justify-content:center}
          .strip figure{margin-inline:auto}.strip img{width:100%;height:100%;object-fit:contain}
          #status{position:absolute;width:1px;height:1px;overflow:hidden;clip-path:inset(50%)}
        </style><div id="viewport" tabindex="0"><div id="stage"></div></div><div id="status" role="status" aria-live="polite"></div>`;
        this.viewport = this.shadowRoot.querySelector('#viewport');
        this.stage = this.shadowRoot.querySelector('#stage');
        this.status = this.shadowRoot.querySelector('#status');
        this.settings = {}; this.index = 0; this.half = undefined; this.offset = 0; this.epoch = 0;
        this.resize = new ResizeObserver(() => {
            const size=`${this.clientWidth}:${this.clientHeight}`;
            if(this.pages && size!==this.lastSize){this.lastSize=size;this.render();}
        });
        this.resize.observe(this);
        this.viewport.addEventListener('keydown', e => this.key(e));
        this.viewport.addEventListener('scroll', () => {
            if (this.settings.comicMode !== 'webtoon' || this.scrollScheduled) return;
            this.scrollScheduled = true;
            requestAnimationFrame(() => {this.scrollScheduled = false; this.scrolled();});
        });
        this.viewport.addEventListener('dblclick', () => this.zoom(this.settings.zoom === 'fit-page' ? 'fit-width' : 'fit-page'));
        this.viewport.addEventListener('wheel', e => {
            if(e.ctrlKey || e.metaKey){e.preventDefault();this.zoom(e.deltaY < 0 ? 'in' : 'out');}
        }, {passive:false});
        const pointers=new Map();
        let gesture, pinch;
        this.viewport.addEventListener('pointerdown', e => {
            if(e.button!==0 || e.target.closest('button'))return;
            pointers.set(e.pointerId,{x:e.clientX,y:e.clientY});
            this.viewport.focus({preventScroll:true});
            this.viewport.setPointerCapture(e.pointerId);
            if(pointers.size===1)gesture={x:e.clientX,y:e.clientY,lastX:e.clientX,lastY:e.clientY};
            if(pointers.size===2){
                const [a,b]=[...pointers.values()];
                const stage=this.stage.getBoundingClientRect(),viewport=this.viewport.getBoundingClientRect();
                pinch={distance:Math.hypot(a.x-b.x,a.y-b.y),scale:this.scale,zoom:this.scale,changed:false,
                    originX:this.viewport.clientWidth/2-(stage.left-viewport.left),
                    originY:this.viewport.clientHeight/2-(stage.top-viewport.top)};
                gesture=null;
            }
        });
        this.viewport.addEventListener('pointermove',e=>{
            if(!pointers.has(e.pointerId))return;
            pointers.set(e.pointerId,{x:e.clientX,y:e.clientY});
            if(pinch && pointers.size===2 && this.settings.comicMode!=='webtoon'){
                const [a,b]=[...pointers.values()];
                pinch.zoom=Math.min(6,Math.max(.25,pinch.scale*Math.hypot(a.x-b.x,a.y-b.y)/Math.max(1,pinch.distance)));
                pinch.changed=Math.abs(pinch.zoom-pinch.scale)>0.001;
                this.previewZoom(pinch.zoom,pinch.scale,pinch.originX,pinch.originY);
            }else if(gesture && (this.canPan||this.settings.comicMode==='webtoon')){
                this.pan({x:gesture.lastX-e.clientX,y:gesture.lastY-e.clientY});gesture.lastX=e.clientX;gesture.lastY=e.clientY;
            }
        });
        const end=e=>{
            pointers.delete(e.pointerId);
            if(pinch){
                if(!pointers.size){
                    const completedPinch=pinch;pinch=null;
                    if(completedPinch.changed&&this.settings.comicMode!=='webtoon')this.applyZoom(completedPinch.zoom,false);
                    else{this.stage.style.removeProperty('transform');this.stage.style.removeProperty('transform-origin');this.stage.style.removeProperty('will-change');this.report();}
                    this.send('readerSetting',{key:'zoom',value:this.settings.zoom});
                }
                return;
            }
            if(!gesture)return;
            const dx=e.clientX-gesture.x,dy=e.clientY-gesture.y;gesture=null;
            if(e.type==='pointercancel'||this.settings.comicMode==='webtoon'||this.canPan)return;
            if(Math.abs(dx)>60&&Math.abs(dx)>Math.abs(dy)*1.5)(dx<0)!==this.rtl?this.next():this.prev();
        };
        this.viewport.addEventListener('pointerup',end);this.viewport.addEventListener('pointercancel',end);

    }
    get rtl(){return this.settings.direction === 'rtl';}
    get canPan(){return typeof this.settings.zoom === 'number' || ['fit-width','fit-height'].includes(this.settings.zoom);}
    async open(document, options, send, resource) {
        const dimension=value=>Number.isFinite(value)&&value>0&&value<=100000?value:undefined;
        this.pages = document.pages.map(p=>({...p,width:dimension(p.width),height:dimension(p.height)})); this.metadata=document.metadata;
        this.options=options;this.send=send;this.resource=resource;this.defaultDirection=document.direction;
        this.numbers=new Intl.NumberFormat(options.formattingLocale??options.interfaceLocale,{useGrouping:false});
        this.viewport.setAttribute('aria-label',options.title);
        const location=parseComicLocator(options.cfi, Math.max(0,(options.page??1)-1));
        this.index=Math.min(this.pages.length-1,Math.max(0,location.index));this.half=location.half;this.offset=location.offset;
        this.configure(options.settings);
        this.viewport.focus({preventScroll:true});
    }
    configure(settings) {
        if(settings.direction)this.directionPreference=settings.direction;
        this.settings={...this.settings,...settings};
        this.settings.direction=!this.directionPreference||this.directionPreference==='auto'?this.defaultDirection:this.directionPreference;
        this.render();this.report();
    }
    report(){this.send('viewState',{fixed:true,comic:true,zoom:this.settings.zoom??'fit-page',pages:this.pages.length});}
    pageLabel(index){return `${this.options.labels?.imagePage??''} ${this.numbers.format(index+1)}`;}
    turns(){return comicTurns(this.pages,this.settings,this.clientWidth,this.clientHeight);}
    currentTurn(turns=this.turns()) {
        let n=turns.findIndex(turn=>turn.some(p=>p.index===this.index && (this.half===undefined || p.half===this.half)));
        if(n<0)n=turns.findIndex(turn=>turn.some(p=>p.index===this.index));
        return Math.max(0,n);
    }
    location() {
        if(this.closed)return;
        const section=this.pages[this.index];
        const turns=this.turns(),turn=turns[this.currentTurn(turns)];
        const end = this.settings.comicMode === 'webtoon' ? this.index+this.offset : Math.max(...turn.map(p=>p.index))+1;
        const fraction=Math.min(1,Math.max(0,end/this.pages.length));
        const title=section.bookmark || this.pageLabel(this.index);
        this.send('location',{cfi:comicLocator(this.index,this.half,this.offset),href:section.name,title,
            fraction,section:this.index,sections:this.pages.length,text:''});
        this.status.textContent=title;
    }
    render() {
        if(!this.pages || !this.clientWidth || !this.clientHeight)return;
        this.stage.style.removeProperty('transform');this.stage.style.removeProperty('transform-origin');this.stage.style.removeProperty('will-change');
        this.epoch++;this.unload(this.stage);
        this.rendering=true;
        this.stage.className=this.settings.comicMode==='webtoon'?'strip':'';
        if(this.settings.comicMode==='webtoon'){
            this.pages.forEach((page,i)=>this.stage.append(this.figure({index:i},true)));
            this.resident=new Set();
            const target=this.stage.children[this.index];
            this.viewport.scrollTop=target.offsetTop+target.offsetHeight*this.offset;
            this.window();
        }else{
            const turn=this.turns()[this.currentTurn()];
            const width=turn.reduce((sum,item)=>sum+(this.pages[item.index].width||800)/(item.half===undefined?1:2),0);
            const height=Math.max(...turn.map(item=>this.pages[item.index].height||1200));
            const scale=typeof this.settings.zoom==='number'?this.settings.zoom:
                this.settings.zoom==='fit-width'?this.clientWidth/width:this.settings.zoom==='fit-height'?this.clientHeight/height:
                Math.min(this.clientWidth/width,this.clientHeight/height);
            this.stage.style.width=`${Math.max(this.clientWidth,width*scale)}px`;
            this.stage.style.height=`${Math.max(this.clientHeight,height*scale)}px`;
            for(const item of turn){const figure=this.figure(item,false,scale);this.stage.append(figure);this.load(figure);}
            this.viewport.scrollTop=0;this.viewport.scrollLeft=0;
        }
        this.rendering=false;this.location();
    }
    figure(item,strip,scale) {
        const page=this.pages[item.index],figure=document.createElement('figure');
        figure.dataset.index=item.index;if(item.half!==undefined){figure.dataset.half=item.half;figure.className='split';}
        const width=page.width||800,height=page.height||1200,half=item.half===undefined?1:2;
        if(strip)scale=this.clientWidth/width*(typeof this.settings.zoom==='number'?this.settings.zoom:1);
        figure.style.width=`${width/half*scale}px`;figure.style.height=`${strip?Math.max(32,height*scale):height*scale}px`;
        if(strip){this.stage.style.width='100%';this.stage.style.height='auto';}
        figure.dataset.scale=scale;figure.dataset.epoch=this.epoch;
        return figure;
    }
    load(figure) {
        if(figure.firstChild || this.closed)return;
        const i=Number(figure.dataset.index),page=this.pages[i],img=document.createElement('img');
        img.alt=this.pageLabel(i);
        img.decoding='async';img.draggable=false;
        const half=figure.dataset.half,scale=Number(figure.dataset.scale);
        if(this.settings.comicMode!=='webtoon'){
            img.style.width=`${(page.width||800)*scale}px`;img.style.height=`${(page.height||1200)*scale}px`;
            if(half!==undefined)img.style.left=Number(half)===1?`-${(page.width||800)*scale/2}px`:'0';
        }
        img.onload=()=>{
            if(!figure.isConnected || Number(figure.dataset.epoch)!==this.epoch)return;
            if(img.naturalWidth>0 && img.naturalHeight>0 && (page.width!==img.naturalWidth||page.height!==img.naturalHeight)){
                page.width=img.naturalWidth;page.height=img.naturalHeight;
                // Repair dimensions before publishing a scroll locator. Rebuilding keeps the anchor.
                if(!this.relayoutPending){
                    this.relayoutPending=true;requestAnimationFrame(()=>{this.relayoutPending=false;if(this.isConnected&&!this.closed)this.render();});
                }
            }
        };
        img.onerror=()=>{
            if(!figure.isConnected)return;
            const retry=document.createElement('button');retry.textContent=this.options.labels?.retry??this.options.labels?.error??'';
            retry.setAttribute('aria-label',`${retry.textContent} · ${img.alt}`);
            retry.onclick=()=>{figure.classList.remove('error');figure.replaceChildren();this.load(figure);};
            figure.classList.add('error');figure.replaceChildren(retry);
        };
        img.src=this.resource(page.name);figure.append(img);
    }
    unload(figure){for(const img of figure.querySelectorAll('img')){img.onload=null;img.onerror=null;img.removeAttribute('src');}figure.replaceChildren();}
    window(){
        const keep=new Set();
        // Include the whole viewport, even when a strip consists of short panels.
        // The 32px minimum placeholder height bounds residency by viewport size.
        let last=this.index;
        const bottom=this.viewport.scrollTop+this.viewport.clientHeight;
        while(last<this.pages.length-1&&this.stage.children[last].offsetTop+this.stage.children[last].offsetHeight<bottom)last++;
        for(let i=Math.max(0,this.index-2);i<=Math.min(this.pages.length-1,last+2);i++)keep.add(i);
        for(const i of this.resident??[])if(!keep.has(i))this.unload(this.stage.children[i]);
        for(const i of keep)this.load(this.stage.children[i]);
        this.resident=keep;
    }
    scrolled(){
        if(this.closed||this.rendering||this.settings.comicMode!=='webtoon' || !this.stage.children.length)return;
        const y=this.viewport.scrollTop;
        // Binary search avoids walking thousands of strip placeholders every frame.
        let lo=0,hi=this.pages.length-1;
        while(lo<hi){const mid=Math.ceil((lo+hi)/2);if(this.stage.children[mid].offsetTop<=y+1)lo=mid;else hi=mid-1;}
        this.index=lo;this.half=undefined;
        const figure=this.stage.children[lo];this.offset=Math.min(1,Math.max(0,(y-figure.offsetTop)/figure.offsetHeight));
        if(y+this.viewport.clientHeight>=this.viewport.scrollHeight-2){this.index=this.pages.length-1;this.offset=1;}
        this.window();this.location();
    }
    move(delta){
        if(this.settings.comicMode==='webtoon'){this.page(this.index+1+delta);return;}
        const turns=this.turns(),n=this.currentTurn(turns),next=Math.min(turns.length-1,Math.max(0,n+delta));
        if(n===next)return;
        const target=this.rtl?turns[next].at(-1):turns[next][0];
        this.index=target.index;this.half=target.half;this.offset=0;this.render();
    }
    next(){this.move(1);}prev(){this.move(-1);}
    page(number){this.index=Math.min(this.pages.length-1,Math.max(0,Math.round(Number(number)||1)-1));this.half=undefined;this.offset=0;this.render();}
    goTo(target){
        const known=this.pages.findIndex(p=>p.name===target);
        const location=parseComicLocator(target,known<0?0:known);
        this.index=Math.min(this.pages.length-1,location.index);this.half=location.half;this.offset=location.offset;this.render();
    }
    get scale(){return Number(this.stage.children[this.settings.comicMode==='webtoon'?this.index:0]?.dataset.scale)||1;}
    zoom(value){
        const scale=this.settings.comicMode==='webtoon'?(typeof this.settings.zoom==='number'?this.settings.zoom:1):this.scale;
        const zoom=value==='actual'?1:value==='in'?Math.min(6,scale*1.25):value==='out'?Math.max(.25,scale/1.25):value;
        this.applyZoom(zoom);
    }
    applyZoom(zoom,save=true){
        const x=this.viewport.scrollLeft,y=this.viewport.scrollTop,oldScale=this.scale;
        this.settings.zoom=zoom;this.options.settings.zoom=zoom;this.render();
        if(typeof zoom==='number'&&this.settings.comicMode!=='webtoon'){this.viewport.scrollLeft=(x+this.clientWidth/2)*this.scale/oldScale-this.clientWidth/2;this.viewport.scrollTop=(y+this.clientHeight/2)*this.scale/oldScale-this.clientHeight/2;}
        this.report();if(save)this.send('readerSetting',{key:'zoom',value:zoom});
    }
    previewZoom(zoom,baseScale,originX,originY){
        this.stage.style.willChange='transform';
        this.stage.style.transformOrigin=`${originX}px ${originY}px`;
        this.stage.style.transform=`scale(${zoom/baseScale})`;
    }
    pan({x=0,y=0}){this.viewport.scrollBy(x,y);}
    key(e){
        if(e.target.closest('button') || e.altKey)return;
        let action;
        if((e.ctrlKey||e.metaKey)&&['+','=','-','0'].includes(e.key))action=()=>this.zoom(e.key==='0'?'fit-page':e.key==='-'?'out':'in');
        else if(e.key==='Home')action=()=>this.page(1);
        else if(e.key==='End')action=()=>this.page(this.pages.length);
        else if(e.key==='PageDown'||e.key===' ')action=()=>this.settings.comicMode==='webtoon'?this.pan({y:this.clientHeight*.9}):e.shiftKey?this.prev():this.next();
        else if(e.key==='PageUp')action=()=>this.settings.comicMode==='webtoon'?this.pan({y:-this.clientHeight*.9}):this.prev();
        else if(e.key.startsWith('Arrow'))action=()=>{
            if(this.canPan||this.settings.comicMode==='webtoon')this.pan({x:e.key==='ArrowRight'?80:e.key==='ArrowLeft'?-80:0,y:e.key==='ArrowDown'?80:e.key==='ArrowUp'?-80:0});
            else if(e.key==='ArrowRight')this.rtl?this.prev():this.next();
            else if(e.key==='ArrowLeft')this.rtl?this.next():this.prev();
            else e.key==='ArrowDown'?this.next():this.prev();
        };
        if(action){e.preventDefault();e.stopPropagation();action();}
    }
    close(){this.closed=true;this.resize.disconnect();this.unload(this.stage);this.remove();}
}
customElements.define('comic-view',ComicReader);
