let isEditMode = false;
let forceHidden = false;

function loadPositions() {
    const saved = JSON.parse(localStorage.getItem('nexus_pos_v2') || '{}');
    Object.keys(saved).forEach(id => {
        const el = document.getElementById(id);
        if (el) {
            el.style.top = saved[id].t;
            el.style.left = saved[id].l;
            el.style.right = 'auto';
            el.style.bottom = 'auto';
            el.style.transform = 'none';
        }
    });
}

function updateCircle(id, val) {
    const el = document.getElementById(id);
    if (el) {
        let offset = 264 - (val / 100 * 264);
        el.style.strokeDashoffset = offset;
    }
}

window.addEventListener('message', (event) => {
    const payload = event.data;
    
    if (payload.action === "resetHud") {
        localStorage.removeItem('nexus_pos_v2');
        document.querySelectorAll('.drag-item').forEach(e => {
            e.style.top = ''; e.style.left = ''; e.style.right = ''; e.style.bottom = ''; e.style.transform = '';
        });
        loadPositions(); 
        return;
    }

    if (payload.action === "init") {
        if (payload.colors) {
            const root = document.documentElement;
            root.style.setProperty('--primary', payload.colors.primary);
            root.style.setProperty('--health', payload.colors.health);
            root.style.setProperty('--armor', payload.colors.armor);
            root.style.setProperty('--hunger', payload.colors.hunger);
            root.style.setProperty('--thirst', payload.colors.thirst);
        }
        if (payload.branding) {
            document.querySelector('.nexus').innerText = payload.branding.name1;
            document.querySelector('.roleplay').innerText = payload.branding.name2;
        }
        if (payload.settings) {
            document.getElementById('id-text').style.display = payload.settings.showID ? 'block' : 'none';
            document.getElementById('drag-status').style.display = payload.settings.showStatus ? 'flex' : 'none';
            document.getElementById('drag-mic').style.display = payload.settings.showMic ? 'block' : 'none';
        }
        loadPositions();
    }

    if (payload.action === "forceHide") { forceHidden = payload.state; }
    
    if (payload.action === "toggleEdit") {
        isEditMode = payload.state;
        document.body.classList.toggle('edit-mode', isEditMode);
    }

    if (payload.action === "tick") {
        // Sicherstellen, dass das HUD angezeigt wird wenn nicht pausiert
        document.body.style.display = (payload.paused || forceHidden) ? 'none' : 'block';
        
        if (!isEditMode && payload.mapPos) {
            const statusBox = document.getElementById('drag-status');
            const savedPos = JSON.parse(localStorage.getItem('nexus_pos_v2') || '{}');
            if (!savedPos['drag-status']) {
                // Ein Ticken weiter nach links (-3.6) für perfekte Symmetrie
                statusBox.style.left = (payload.mapPos.x + (payload.mapPos.w / 2) - 3.6) + "%";
                statusBox.style.top = (payload.mapPos.y - 4.1) + "%";
                statusBox.style.transform = 'translateX(-50%)';
                statusBox.style.bottom = 'auto';
                statusBox.style.right = 'auto';
            }
        }

        updateCircle('health-circle', payload.hp);
        updateCircle('armor-circle', payload.arm);
        
        const vehHud = document.getElementById('speedo-container');
        if (payload.inVeh) {
            vehHud.style.display = 'flex';
            document.getElementById('speed-val').innerText = payload.spd;
            document.getElementById('gear-val').innerText = payload.gear;
            document.getElementById('rpm-bar-fill').style.width = (payload.rpm * 100) + "%";
        } else { vehHud.style.display = 'none'; }

        const mic = document.getElementById('mic');
        if (payload.talking) {
            mic.classList.add('active');
            mic.classList.replace('fa-microphone-slash', 'fa-microphone');
        } else {
            mic.classList.remove('active');
            mic.classList.replace('fa-microphone', 'fa-microphone-slash');
        }
    }

    if (payload.action === "updateStats") {
        updateCircle('hunger-circle', payload.h);
        updateCircle('thirst-circle', payload.t);
    }

    if (payload.action === "status") {
        if (payload.cash !== undefined) document.getElementById('cash-text').innerText = payload.cash.toLocaleString();
        if (payload.bank !== undefined) document.getElementById('bank-text').innerText = payload.bank.toLocaleString();
        if (payload.sid !== undefined) document.getElementById('id-text').innerText = "ID: " + payload.sid;
    }
});

let current_drag = null;
document.addEventListener('mousedown', (e) => {
    if (!isEditMode) return;
    current_drag = e.target.closest('.drag-item');
    if (current_drag) current_drag.style.transform = 'none';
});

document.addEventListener('mousemove', (e) => {
    if (!isEditMode || !current_drag) return;
    current_drag.style.left = e.clientX - (current_drag.offsetWidth/2) + "px";
    current_drag.style.top = e.clientY - (current_drag.offsetHeight/2) + "px";
});

document.addEventListener('mouseup', () => {
    if (current_drag) {
        const speicher = JSON.parse(localStorage.getItem('nexus_pos_v2') || '{}');
        speicher[current_drag.id] = { t: current_drag.style.top, l: current_drag.style.left };
        localStorage.setItem('nexus_pos_v2', JSON.stringify(speicher));
        current_drag = null;
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === "Escape" && isEditMode) {
        fetch(`https://${GetParentResourceName()}/closeEdit`, { method: 'POST', body: JSON.stringify({}) });
    }
});

document.addEventListener('DOMContentLoaded', () => {
    fetch(`https://${GetParentResourceName()}/nuiReady`, { method: 'POST', body: JSON.stringify({}) });
    loadPositions();
});