// Optional integration test driver. Uses a real browser, never a hosted book.
const { chromium } = require(process.env.PLEZY_PLAYWRIGHT_PATH || 'playwright');
(async () => {
  const browser = await chromium.launch({executablePath: process.env.PLEZY_CHROME_PATH, headless:true, args:['--no-sandbox']});
  try {
    const page = await browser.newPage({viewport:{width:1280,height:900}});
    const errors=[];
    page.on('pageerror', e=>errors.push(e.message));
    await page.goto(process.argv[2]);
    await page.waitForFunction(()=>document.title.includes('Reading fixture'),{},{timeout:20000});
    await page.waitForFunction(()=>document.querySelector('foliate-view')?.lastLocation?.cfi,{},{timeout:20000});
    await page.evaluate(()=>document.fonts.ready);
    if(await page.locator('header .reader-icon').count()!==12)throw Error('Reader did not use the shared icon controls');
    if(process.argv[3]==='comic') {
      await page.getByRole('button',{name:'Reading settings',exact:true}).click();
      await page.getByLabel('Page layout',{exact:true}).selectOption(JSON.stringify('single'));
      await page.getByLabel('Reading direction',{exact:true}).selectOption(JSON.stringify('rtl'));
      await page.getByLabel('Zoom',{exact:true}).selectOption(JSON.stringify('fit-width'));
      await page.waitForFunction(()=>window.readerOptions.settings.direction==='rtl'&&window.readerOptions.settings.spread==='single'&&document.querySelector('foliate-view').renderer.getAttribute('zoom')==='fit-width');
      await page.getByRole('button',{name:'Close',exact:true}).click();
    }
    const result = await page.evaluate(async(comic)=>{
      const view=document.querySelector('foliate-view');
      const initial=view.lastLocation.cfi;
      if(comic){
        await publication.settings({spread:'single',direction:'rtl'});
        await publication.zoom('actual');await publication.zoom('in');
        if(Number(view.renderer.getAttribute('zoom'))<=1)throw Error('Comic zoom did not enlarge');
        await publication.pan({x:80,y:80});
        await publication.page(2);
        const second=view.lastLocation.cfi;
        if(initial===second)throw Error('Comic page navigation failed');
        await publication.zoom('fit-width');
        if(view.renderer.getAttribute('zoom')!=='fit-width')throw Error('Fit width failed');
        view.renderer.scrollTop=0;
        document.dispatchEvent(new KeyboardEvent('keydown',{key:'ArrowDown',bubbles:true}));
        if(view.renderer.scrollHeight>view.renderer.clientHeight&&view.renderer.scrollTop<=0)throw Error('Fit-width keyboard pan did not scroll');
        if(view.renderer.rtl!==true)throw Error('RTL was not applied');
        return {search:1,initial,second};
      }
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
    if(process.env.PLEZY_READER_SCREENSHOT)await page.screenshot({path:process.env.PLEZY_READER_SCREENSHOT.replace('.png',process.argv[3]==='comic'?'-comic.png':'.png')});
    if(errors.length)throw Error(errors.join('\n'));
    process.stdout.write(JSON.stringify(result));
  } finally {await browser.close();}
})().catch(e=>{process.stderr.write(e.stack);process.exitCode=1});
