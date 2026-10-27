// CI integration driver. Uses generated fixtures through the real loopback server.
const { chromium } = require(process.env.PLEZY_PLAYWRIGHT_PATH || '../../../tools/reader-tests/node_modules/playwright');
(async () => {
  const browser = await chromium.launch({executablePath: process.env.PLEZY_CHROME_PATH, headless:true, args:['--no-sandbox']});
  try {
    const page = await browser.newPage({viewport:{width:1280,height:900},hasTouch:true});
    const errors=[];const rtl=process.argv[4]==='rtl';
    page.on('pageerror', e=>errors.push(e.message));
    await page.goto(process.argv[2]);
    await page.waitForFunction(()=>document.title.includes('Reading fixture'),{},{timeout:20000});
    await page.waitForFunction(()=>document.querySelector('comic-view')?.pages||document.querySelector('foliate-view')?.lastLocation?.cfi,{},{timeout:20000});
    await page.evaluate(()=>document.fonts.ready);
    if(await page.locator('header .reader-icon').count()!==12)throw Error('Reader did not use the shared icon controls');
    const labels=await page.evaluate(()=>window.readerOptions.labels);
    if(process.argv[3]==='comic') {
      await page.getByRole('button',{name:labels.settings,exact:true}).click();
      await page.getByLabel(labels.comicMode,{exact:true}).selectOption(JSON.stringify('webtoon'));
      if(!await page.getByLabel(labels.pageLayout,{exact:true}).isDisabled())throw Error('Strip layout controls stayed enabled');
      await page.getByLabel(labels.comicMode,{exact:true}).selectOption(JSON.stringify('paged'));
      if(await page.getByLabel(labels.pageLayout,{exact:true}).isDisabled())throw Error('Page layout did not re-enable');
      await page.getByLabel(labels.pageLayout,{exact:true}).selectOption(JSON.stringify('single'));
      await page.getByLabel(labels.readingDirection,{exact:true}).selectOption(JSON.stringify('rtl'));
      await page.getByLabel(labels.zoom,{exact:true}).selectOption(JSON.stringify('fit-width'));
      await page.waitForFunction(()=>window.readerOptions.settings.direction==='rtl'&&window.readerOptions.settings.spread==='single'&&document.querySelector('comic-view').settings.zoom==='fit-width');
      await page.getByRole('button',{name:labels.close,exact:true}).click();
    }
    if(process.argv[3]==='comic') {
      await page.getByRole('button',{name:labels.thumbnails,exact:true}).click();
      if(await page.locator('dialog img').count()!==8)throw Error('Thumbnail paging is not bounded');
      await page.getByRole('button',{name:labels.prev,exact:true}).last().isDisabled();
      await page.getByRole('button',{name:labels.next,exact:true}).last().click();
      if(await page.locator('dialog img').count()!==4)throw Error('Thumbnail next group failed');
      await page.getByRole('button',{name:labels.close,exact:true}).click();
    }
    if(rtl){
      if(await page.locator('html').getAttribute('lang')!=='ar'||await page.locator('html').getAttribute('dir')!=='rtl')throw Error('Reader chrome did not apply Arabic language and direction');
      await page.getByRole('button',{name:labels.page,exact:true}).click();
      const input=page.getByRole('textbox',{name:labels.goToPage,exact:true});
      await input.fill('٢.٥');
      await page.locator('dialog').getByRole('button',{name:labels.goToPage,exact:true}).click();
      if(!await page.locator('dialog').isVisible())throw Error('Fractional page number was accepted');
      await input.fill('٢');
      await page.locator('dialog').getByRole('button',{name:labels.goToPage,exact:true}).click();
      await page.waitForFunction(()=>document.querySelector('comic-view').index===1);
      if(await page.locator('dialog').isVisible())throw Error('Arabic page number was rejected');
      await page.evaluate(()=>publication.page(1));
    }
    const result = await page.evaluate(async(comic)=>{
      if(comic){
        const reader=document.querySelector('comic-view');
        const nextFrame=()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve)));
        const initial=reader.index;
        await publication.settings({spread:'double',direction:'ltr',coverAlone:true,zoom:'fit-page'});
        await publication.page(2);await nextFrame();
        if(reader.stage.children.length!==1)throw Error('Wide-page neighbor must be isolated');
        await publication.page(4);await nextFrame();
        if(reader.stage.children.length!==2)throw Error('Double spread missing');
        await publication.settings({spread:'single',direction:'rtl',splitWide:true});
        await publication.page(3);
        if(reader.stage.firstChild.dataset.half!=='1')throw Error('RTL wide page did not start at right half');
        await publication.next();
        if(reader.index!==2||reader.half!==0)throw Error('Wide page second half skipped');
        await publication.next();
        if(reader.index!==3)throw Error('Split page did not advance to next physical image');
        await publication.goTo('epubcfi(/6/4)');
        if(reader.index!==1)throw Error('Legacy bookmark migration failed');
        await publication.settings({splitWide:false,zoom:'fit-width'});
        await publication.zoom('actual');await publication.zoom('in');
        if(reader.settings.zoom<=1)throw Error('Comic zoom did not enlarge');
        await publication.pan({x:80,y:80});
        await publication.page(2);
        const second=reader.index;
        if(initial===second)throw Error('Comic page navigation failed');
        await publication.zoom('fit-height');
        if(reader.settings.zoom!=='fit-height')throw Error('Fit height failed');
        await publication.settings({comicMode:'webtoon',zoom:'fit-width'});await publication.page(6);await nextFrame();
        if(reader.stage.querySelectorAll('img').length>5)throw Error('Webtoon retained too many images');
        reader.viewport.scrollTop=reader.stage.children[5].offsetTop+reader.stage.children[5].offsetHeight*.35;
        reader.scrolled();await nextFrame();
        const saved=`plezy-comic:${reader.index}:-1:${reader.offset}`;
        await publication.page(1);await publication.goTo(saved);await nextFrame();
        if(reader.index!==5||Math.abs(reader.offset-.35)>.03)throw Error('Webtoon resume lost page offset');
        reader.viewport.scrollTop=reader.viewport.scrollHeight;reader.scrolled();
        if(reader.index!==11||reader.offset!==1)throw Error('End of strip not reached');
        await publication.settings({comicMode:'paged',splitWide:false,spread:'single',zoom:'fit-page',direction:'rtl'});
        await publication.page(5);reader.viewport.focus();
        reader.viewport.dispatchEvent(new KeyboardEvent('keydown',{key:'ArrowLeft',bubbles:true,composed:true}));
        if(reader.index!==5)throw Error('RTL keyboard next failed');
        await publication.settings({direction:'auto'});
        if(!reader.rtl)throw Error('Metadata direction not restored');
        await publication.settings({spread:'auto',direction:'ltr'});
        await nextFrame();
        return {search:1,initial,second};
      }
      const view=document.querySelector('foliate-view');
      const initial=view.lastLocation.cfi;
      const search=await publication.search('lighthouse');
      if(!search.length)throw Error('Search did not find fixture text');
      await publication.goTo('EPUB/two.xhtml');
      const second=view.lastLocation.cfi;
      if(initial===second)throw Error('Chapter navigation did not move');
      await publication.goTo(initial);
      await publication.annotate({value:search[0].cfi,color:'#c9b77e',note:'Fixture note'});
      const docs=view.renderer.getContents().map(x=>x.doc);
      if(docs.some(doc=>doc.querySelector('script,[onclick],form,iframe')))throw Error('Unsafe publisher content survived');
      if(window.publisherScriptRan)throw Error('Publisher script executed');
      await publication.settings({background:'#0E0F12',foreground:'#EDEDED',dark:true,fontSize:32,font:'sans',lineHeight:2,columns:2});
      const p=docs[0].querySelector('p'),typography=p.ownerDocument.defaultView.getComputedStyle(p);
      if(typography.fontSize!=='32px'||typography.lineHeight!=='64px'||typography.color!=='rgb(237, 237, 237)')throw Error('Publisher CSS overrode accessible typography: '+typography.cssText);
      await publication.settings({background:'#0E0F12',foreground:'#EDEDED',dark:true,fontSize:22,columns:2});
      return {search:search.length,initial,second};
    },process.argv[3]==='comic');
    if(process.argv[3]==='comic') {
      await page.setViewportSize({width:390,height:844});
      await page.waitForFunction(()=>document.querySelector('comic-view').stage.children.length===1);
      await page.setViewportSize({width:1280,height:900});
      await page.waitForFunction(()=>document.querySelector('comic-view').stage.children.length===2);
      await page.evaluate(async()=>{await publication.page(4);await publication.zoom('fit-width');});
      await page.waitForFunction(()=>[...document.querySelector('comic-view').stage.querySelectorAll('img')].every(i=>i.complete&&i.naturalWidth));
      const fits=await page.evaluate(()=>{const r=document.querySelector('comic-view');return r.viewport.scrollWidth<=r.clientWidth+1&&Math.abs(r.stage.children[0].offsetHeight-r.stage.children[1].offsetHeight)<=1;});
      if(!fits)throw Error('Mixed-width spread does not fit or use a common scale');
      await page.evaluate(async()=>{await publication.settings({spread:'single',zoom:'fit-page'});await publication.page(1);});
      let failed=false;
      await page.route('**/book/page7.svg',route=>{if(!failed){failed=true;return route.abort();}return route.continue();});
      await page.evaluate(()=>publication.page(7));
      const retryName=await page.evaluate(()=>{const r=document.querySelector('comic-view');return `${r.options.labels.retry} · ${r.pageLabel(6)}`;});
      await page.getByRole('button',{name:retryName,exact:true}).click();
      await page.waitForFunction(()=>document.querySelector('comic-view').stage.querySelector('img')?.naturalWidth>0);
      if(!failed)throw Error('Page retry fixture did not run');
      // Actual Chromium touch input exercises pointer capture, swipe and pinch.
      const session=await page.context().newCDPSession(page);
      const touch=(type,touchPoints)=>session.send('Input.dispatchTouchEvent',{type,touchPoints});
      await touch('touchStart',[{x:700,y:450,id:1}]);
      await touch('touchMove',[{x:450,y:450,id:1}]);
      await touch('touchEnd',[]);
      await page.waitForFunction(()=>document.querySelector('comic-view').index===7);
      await touch('touchStart',[{x:500,y:450,id:1},{x:700,y:450,id:2}]);
      await touch('touchMove',[{x:400,y:450,id:1},{x:800,y:450,id:2}]);
      await touch('touchEnd',[]);
      await page.waitForFunction(()=>typeof document.querySelector('comic-view').settings.zoom==='number');
      await session.detach();
    }
    if(process.env.PLEZY_READER_SCREENSHOT)await page.screenshot({path:process.env.PLEZY_READER_SCREENSHOT.replace('.png',process.argv[3]==='comic'?'-comic.png':'.png')});
    if(errors.length)throw Error(errors.join('\n'));
    process.stdout.write(JSON.stringify(result));
  } finally {await browser.close();}
})().catch(e=>{process.stderr.write(e.stack);process.exitCode=1});
