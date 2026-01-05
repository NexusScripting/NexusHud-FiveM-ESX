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
    const c = document.getElementById(id);
    if (c) {
        let dashOffset = 264 - (val / 100 * 264);
        c.style.strokeDashoffset = dashOffset;
    }
}

window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.action === "resetHud") {
        localStorage.removeItem('nexus_pos_v2');
        document.querySelectorAll('.drag-item').forEach(e => {
            e.style.top = ''; e.style.left = ''; e.style.right = ''; e.style.bottom = ''; e.style.transform = '';
        });
        loadPositions(); 
        return;
    }

    if (data.action === "init") {
        if (data.colors) {
            const root = document.documentElement;
            root.style.setProperty('--primary', data.colors.primary);
            root.style.setProperty('--health', data.colors.health);
            root.style.setProperty('--armor', data.colors.armor);
            root.style.setProperty('--hunger', data.colors.hunger);
            root.style.setProperty('--thirst', data.colors.thirst);
        }
        if (data.branding) {
            document.querySelector('.nexus').innerText = data.branding.name1;
            document.querySelector('.roleplay').innerText = data.branding.name2;
        }
        if (data.settings) {
            document.getElementById('id-text').style.display = data.settings.showID ? 'block' : 'none';
            document.getElementById('drag-status').style.display = data.settings.showStatus ? 'flex' : 'none';
            document.getElementById('drag-mic').style.display = data.settings.showMic ? 'block' : 'none';
        }
        loadPositions();
    }

    if (data.action === "forceHide") { forceHidden = data.state; }
    
    if (data.action === "toggleEdit") {
        isEditMode = data.state;
        document.body.classList.toggle('edit-mode', isEditMode);
    }

    if (data.action === "tick") {
        document.body.style.display = (data.paused || forceHidden) ? 'none' : 'block';
        
        if (!isEditMode && data.mapPos) {
            const statusBox = document.getElementById('drag-status');
            const saved = JSON.parse(localStorage.getItem('nexus_pos_v2') || '{}');
            if (!saved['drag-status']) {
                statusBox.style.left = (data.mapPos.x + (data.mapPos.w / 2) - 2.0) + "%";
                statusBox.style.top = (data.mapPos.y - 3.5) + "%";
                statusBox.style.transform = 'translateX(-50%)';
                statusBox.style.bottom = 'auto';
                statusBox.style.right = 'auto';
            }
        }

        updateCircle('health-circle', data.hp);
        updateCircle('armor-circle', data.arm);
        
        const speedo = document.getElementById('speedo-container');
        if (data.inVeh) {
            speedo.style.display = 'flex';
            document.getElementById('speed-val').innerText = data.spd;
            document.getElementById('gear-val').innerText = data.gear;
            document.getElementById('rpm-bar-fill').style.width = (data.rpm * 100) + "%";
        } else { speedo.style.display = 'none'; }

        const mic = document.getElementById('mic');
        if (data.talking) {
            mic.classList.add('active');
            mic.classList.replace('fa-microphone-slash', 'fa-microphone');
        } else {
            mic.classList.remove('active');
            mic.classList.replace('fa-microphone', 'fa-microphone-slash');
        }
    }

    if (data.action === "updateStats") {
        updateCircle('hunger-circle', data.h);
        updateCircle('thirst-circle', data.t);
    }

    if (data.action === "status") {
        if (data.cash !== undefined) document.getElementById('cash-text').innerText = data.cash.toLocaleString();
        if (data.bank !== undefined) document.getElementById('bank-text').innerText = data.bank.toLocaleString();
        if (data.sid !== undefined) document.getElementById('id-text').innerText = "ID: " + data.sid;
    }
});

let dragging_item = null;
document.addEventListener('mousedown', (e) => {
    if (!isEditMode) return;
    dragging_item = e.target.closest('.drag-item');
    if (dragging_item) dragging_item.style.transform = 'none';
});

document.addEventListener('mousemove', (e) => {
    if (!isEditMode || !dragging_item) return;
    dragging_item.style.left = e.clientX - (dragging_item.offsetWidth/2) + "px";
    dragging_item.style.top = e.clientY - (dragging_item.offsetHeight/2) + "px";
});

document.addEventListener('mouseup', () => {
    if (dragging_item) {
        const s = JSON.parse(localStorage.getItem('nexus_pos_v2') || '{}');
        s[dragging_item.id] = { t: dragging_item.style.top, l: dragging_item.style.left };
        localStorage.setItem('nexus_pos_v2', JSON.stringify(s));
        dragging_item = null;
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