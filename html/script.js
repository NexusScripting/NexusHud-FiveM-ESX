const updateCircle = (id, val) => {
    const el = document.getElementById(id);
    if (!el) return;
    el.style.strokeDashoffset = 264 - (val / 100 * 264);
    const box = el.closest('.icon-unit');
    if (box) val <= 20 ? box.classList.add('pulse-warning') : box.classList.remove('pulse-warning');
};

window.addEventListener('message', (e) => {
    const d = e.data;
    if (d.action === 'init') {
        const root = document.documentElement;
        root.style.setProperty('--primary', d.colors.primary);
        root.style.setProperty('--health', d.colors.health);
        root.style.setProperty('--armor', d.colors.armor);
        root.style.setProperty('--hunger', d.colors.hunger);
        root.style.setProperty('--thirst', d.colors.thirst);
        document.querySelector('.nexus').innerText = d.branding.name1;
        document.querySelector('.roleplay').innerText = d.branding.name2;
    }
    if (d.action === 'tick') {
        const h = document.getElementById('hud-wrapper');
        if (h) h.style.opacity = d.paused ? "0" : "1";
        updateCircle('health-circle', d.hp);
        updateCircle('armor-circle', d.arm);
        const mic = document.getElementById('mic');
        if (mic) {
            if (d.talking) {
                mic.style.color = "#00ff44";
                mic.classList.remove('fa-microphone-slash');
                mic.classList.add('fa-microphone', 'active');
            } else {
                mic.style.color = "rgba(255,255,255,0.35)";
                mic.classList.remove('fa-microphone', 'active');
                mic.classList.add('fa-microphone-slash');
            }
        }
        const s = document.getElementById('speedo-container');
        if (s) {
            if (d.inVeh) {
                s.style.display = 'flex';
                document.getElementById('speed-val').innerText = d.spd;
                document.getElementById('gear-val').innerText = d.gear;
                document.getElementById('rpm-bar-fill').style.width = (d.rpm * 100) + "%";
            } else s.style.display = 'none';
        }
    }
    if (d.action === 'updateStats') {
        updateCircle('hunger-circle', d.h);
        updateCircle('thirst-circle', d.t);
    }
    if (d.action === 'status') {
        document.getElementById('cash-text').innerText = d.cash.toLocaleString('de-DE');
        document.getElementById('bank-text').innerText = d.bank.toLocaleString('de-DE');
        document.getElementById('id-text').innerText = 'ID: ' + d.sid;
    }
});

document.addEventListener('DOMContentLoaded', () => {
    fetch(`https://${GetParentResourceName()}/nuiReady`, {
        method: 'POST',
        body: JSON.stringify({})
    });
});