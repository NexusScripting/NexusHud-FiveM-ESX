let isEdit = false;

function loadPos() {
    const s = JSON.parse(localStorage.getItem('nexus_pos_v2') || '{}');
    Object.keys(s).forEach(id => {
        const el = document.getElementById(id);
        if (el) {
            el.style.top = s[id].t; el.style.left = s[id].l;
            el.style.right = 'auto'; el.style.bottom = 'auto'; el.style.transform = 'none';
        }
    });
}

function updateCircle(id, v) {
    const el = document.getElementById(id);
    if (el) el.style.strokeDashoffset = 264 - (v / 100 * 264);
}

window.addEventListener('message', (e) => {
    const p = e.data;
    if (p.action === "resetHud") {
        localStorage.removeItem('nexus_pos_v2');
        document.querySelectorAll('.drag-item').forEach(el => { el.style = ''; });
        return;
    }
    if (p.action === "init") {
        if (p.colors) {
            const r = document.documentElement;
            r.style.setProperty('--primary', p.colors.primary);
            r.style.setProperty('--health', p.colors.health);
            r.style.setProperty('--armor', p.colors.armor);
            r.style.setProperty('--hunger', p.colors.hunger);
            r.style.setProperty('--thirst', p.colors.thirst);
        }
        if (p.branding) {
            document.querySelector('.nexus').innerText = p.branding.name1;
            document.querySelector('.roleplay').innerText = p.branding.name2;
        }
        if (p.settings) {
            document.getElementById('id-text').style.display = p.settings.showID ? 'block' : 'none';
            document.getElementById('drag-mic').style.display = p.settings.showMic ? 'block' : 'none';
            document.getElementById('unit-health').style.display = p.settings.showHealth ? 'flex' : 'none';
            document.getElementById('unit-armor').style.display = p.settings.showArmor ? 'flex' : 'none';
            document.getElementById('unit-hunger').style.display = p.settings.showHunger ? 'flex' : 'none';
            document.getElementById('unit-thirst').style.display = p.settings.showThirst ? 'flex' : 'none';
            document.getElementById('mileage-container').style.display = p.settings.showMileage ? 'flex' : 'none';
        }
        loadPos();
    }
    if (p.action === "tick") {
        document.body.style.display = p.paused ? 'none' : 'block';
        if (!isEdit && p.mapPos) {
            const b = document.getElementById('drag-status');
            if (!JSON.parse(localStorage.getItem('nexus_pos_v2') || '{}')['drag-status']) {
                b.style.left = (p.mapPos.x + (p.mapPos.w / 2) - 3.5) + "%";
                b.style.top = (p.mapPos.y - 4.5) + "%";
                b.style.transform = 'translateX(-50%)';
            }
        }
        updateCircle('health-circle', p.hp);
        updateCircle('armor-circle', p.arm);
        const s = document.getElementById('speedo-container');
        if (p.inVeh) {
            s.classList.add('visible');
            document.getElementById('speed-val').innerText = p.spd;
            document.getElementById('gear-val').innerText = p.gear;
            document.getElementById('rpm-bar-fill').style.width = (p.rpm * 100) + "%";
            document.getElementById('mileage-val').innerText = parseFloat(p.mileage || 0).toFixed(1);
        } else { s.classList.remove('visible'); }
        const m = document.getElementById('mic');
        if (p.talking) { m.classList.add('active'); m.classList.replace('fa-microphone-slash', 'fa-microphone'); }
        else { m.classList.remove('active'); m.classList.replace('fa-microphone', 'fa-microphone-slash'); }
    }
    if (p.action === "updateStats") { updateCircle('hunger-circle', p.h); updateCircle('thirst-circle', p.t); }
    if (p.action === "status") {
        if (p.cash !== undefined) document.getElementById('cash-text').innerText = p.cash.toLocaleString();
        if (p.bank !== undefined) document.getElementById('bank-text').innerText = p.bank.toLocaleString();
        if (p.sid !== undefined) document.getElementById('id-text').innerText = "ID: " + p.sid;
    }
    if (p.action === "toggleEdit") { isEdit = p.state; document.body.classList.toggle('edit-mode', isEdit); }
});

let act = null;
document.addEventListener('mousedown', (e) => {
    if (!isEdit) return; act = e.target.closest('.drag-item');
    if (act) act.style.transform = 'none';
});
document.addEventListener('mousemove', (e) => {
    if (!isEdit || !act) return;
    act.style.left = e.clientX - (act.offsetWidth/2) + "px";
    act.style.top = e.clientY - (act.offsetHeight/2) + "px";
});
document.addEventListener('mouseup', () => {
    if (act) {
        const s = JSON.parse(localStorage.getItem('nexus_pos_v2') || '{}');
        s[act.id] = { t: act.style.top, l: act.style.left };
        localStorage.setItem('nexus_pos_v2', JSON.stringify(s));
        act = null;
    }
});
document.addEventListener('keydown', (e) => {
    if (e.key === "Escape" && isEdit) fetch(`https://${GetParentResourceName()}/closeEdit`, {method: 'POST', body: JSON.stringify({})});
});
document.addEventListener('DOMContentLoaded', () => {
    fetch(`https://${GetParentResourceName()}/nuiReady`, {method: 'POST', body: JSON.stringify({})});
    loadPos();
});