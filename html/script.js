const limit = 20;

const updateCircle = (id, val) => {
    const el = document.getElementById(id);
    if (!el) return;
    el.style.strokeDashoffset = 264 - (val / 100 * 264);
    const box = el.closest('.icon-unit');
    val <= limit ? box.classList.add('pulse-warning') : box.classList.remove('pulse-warning');
};

window.addEventListener('message', (e) => {
    const d = e.data;

    if (d.action === 'tick') {
        document.getElementById('hud-wrapper').style.opacity = d.paused ? "0" : "1";
        updateCircle('health-circle', d.hp);
        updateCircle('armor-circle', d.arm);

        const mic = document.getElementById('mic');
        d.talking ? mic.classList.add('active') : mic.classList.remove('active');
        mic.className = d.talking ? 'fa-solid fa-microphone' : 'fa-solid fa-microphone-slash';

        const speedo = document.getElementById('speedo-container');
        if (d.inVeh) {
            speedo.style.display = 'flex';
            document.getElementById('speed-val').innerText = d.spd;
            document.getElementById('gear-val').innerText = d.gear;
            document.getElementById('rpm-bar-fill').style.width = (d.rpm * 100) + "%";
        } else {
            speedo.style.display = 'none';
        }
    }

    if (d.action === 'status') {
        document.getElementById('cash-text').innerText = d.cash.toLocaleString('de-DE');
        document.getElementById('bank-text').innerText = d.bank.toLocaleString('de-DE');
        document.getElementById('id-text').innerText = 'ID: ' + d.sid;
        updateCircle('hunger-circle', d.h);
        updateCircle('thirst-circle', d.t);
    }
});