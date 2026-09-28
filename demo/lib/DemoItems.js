.pragma library

function findAll(item, pred, out) {
    const found = out ?? [];
    if (!item)
        return found;
    if (pred(item))
        found.push(item);
    for (const child of (item.children ?? []))
        findAll(child, pred, found);
    return found;
}

function byName(item, name) {
    return findAll(item, it => it.objectName === name);
}

function tiles(item) {
    return findAll(item, it => it.widget !== undefined && it.dimmed !== undefined && it.valueText !== undefined);
}

function rows(item) {
    return findAll(item, it => it.modelData !== undefined && it.member !== undefined && it.bodyShown !== undefined);
}

function rowOf(item, accountId) {
    return rows(item).find(r => r.modelData === accountId) ?? null;
}

function shownText(item, name) {
    return byName(item, name).filter(it => it.visible).map(it => it.text);
}

// Loader.Status.Ready is 1; a form that failed to compile leaves its tile blank without failing the case
function brokenForms(item) {
    return byName(item, "tileForm").filter(l => l.file && l.status !== 1).map(l => l.file);
}

// A widget comes back out of a Repeater model as a copy with its keys reordered
function sameWidget(a, b) {
    const p = a?.place, q = b?.place;
    return !!p && !!q && a.type === b.type && a.source === b.source && a.form === b.form && p.col === q.col && p.row === q.row && p.cols === q.cols && p.rows === q.rows;
}
