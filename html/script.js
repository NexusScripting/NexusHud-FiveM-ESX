const LOW_LIMIT = 20;

function updateCircle(id, value) {
    const el = document.getElementById(id);
    if (!el) return;

    const val = Math.max(0, Math.min(value, 100));
    el.style.strokeDashoffset = 264 - (val / 100 * 264);

    const parent = el.closest('.icon-unit');
    if (parent) {
        if (val > 0 && val <= LOW_LIMIT) {
            parent.classList.add('pulse-warning');
        } else {
            parent.classList.remove('pulse-warning');
        }
    }
}

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'updateMic') {
        const icon = document.getElementById('mic');
        if (icon) {
            if (data.talking) {
                icon.classList.add('active');
                icon.classList.replace('fa-microphone-slash', 'fa-microphone');
            } else {
                icon.classList.remove('active');
                icon.classList.replace('fa-microphone', 'fa-microphone-slash');
            }
        }
    }

    if (data.action === 'updateFast') {
        updateCircle('health-circle', data.health);
        updateCircle('armor-circle', data.armor);

        const container = document.getElementById('speedo-container');
        if (container) {
            if (data.inVehicle) {
                container.style.display = 'flex';
                document.getElementById('speed-val').innerText = data.speed;
                document.getElementById('gear-val').innerText = data.gear;
                document.getElementById('rpm-bar-fill').style.width = (data.rpm * 100) + "%";
            } else {
                container.style.display = 'none';
            }
        }
    }

    if (data.action === 'updateStatus') {
        const cash = document.getElementById('cash-text');
        const bank = document.getElementById('bank-text');
        const id = document.getElementById('id-text');

        if (cash) cash.innerText = data.cash.toLocaleString('de-DE');
        if (bank) bank.innerText = data.bank.toLocaleString('de-DE');
        if (id) id.innerText = `ID: ${data.id}`;

        updateCircle('hunger-circle', data.hunger);
        updateCircle('thirst-circle', data.thirst);
    }

    if (data.action === 'fade') {
        const hud = document.getElementById('hud-wrapper');
        if (hud) hud.className = data.state ? 'hidden' : '';
    }
});