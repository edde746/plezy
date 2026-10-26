// Pure physical-page planning; neither layout nor reading direction changes identity.
export const isWide = page => page.doublePage || (page.width > 0 && page.height > 0 && page.width > page.height);
export function comicTurns(pages, settings, width, height) {
    const double = settings.comicMode !== 'webtoon' && !settings.splitWide &&
        (settings.spread === 'double' || (settings.spread === 'auto' && width >= 900 && width > height));
    const turns = [];
    for (let i = 0; i < pages.length; i++) {
        const page = pages[i];
        if (settings.splitWide && settings.comicMode !== 'webtoon' && isWide(page)) {
            const halves = settings.direction === 'rtl' ? [1, 0] : [0, 1];
            turns.push(...halves.map(half => [{index: i, half}]));
        } else if (double && !(i === 0 && settings.coverAlone !== false) &&
            !isWide(page) && i + 1 < pages.length && !isWide(pages[i + 1])) {
            const pair = [{index: i}, {index: ++i}];
            turns.push(settings.direction === 'rtl' ? pair.reverse() : pair);
        } else turns.push([{index: i}]);
    }
    return turns;
}
export function comicLocator(index, half, offset = 0) {
    return `plezy-comic:${index}:${half ?? -1}:${Math.min(1, Math.max(0, offset))}`;
}
export function parseComicLocator(value, fallback = 0) {
    const match = /^plezy-comic:(\d+):(-1|0|1):([\d.]+)$/.exec(value ?? '');
    if (match) return {index: Number(match[1]), half: match[2] === '-1' ? undefined : Number(match[2]), offset: Math.min(1, Math.max(0, Number(match[3]) || 0))};
    // Foliate CBZ CFIs encoded spine index as an even step: /6/2, /6/4, ...
    const legacy = /^epubcfi\(\/6\/(\d+)/.exec(value ?? '');
    return {index: legacy ? Math.max(0, Math.floor(Number(legacy[1]) / 2) - 1) : fallback, offset: 0};
}
